//
//  StoreMacroImplementation.swift
//  onward
//
//  Created by Pedro Sousa on 11/11/25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct StoreMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self)
        else {
            context.diagnose(Diagnostic(node: Syntax(node), message: OnwardMacroError.notAClass))
            return []
        }
        
        let storeName = classDecl.name.text
        let storedProperties = getVariables(from: classDecl)

        let proxyExtension = try buildProxyExtension(storeName: storeName, storedProperties: storedProperties)
        let mutatorExtension = try buildMutatorExtension(storeName: storeName, storedProperties: storedProperties)
        
        return [mutatorExtension, proxyExtension]
    }
    
    private static func buildProxyExtension(storeName: String, storedProperties: [VariableDeclSyntax]) throws -> ExtensionDeclSyntax {
        let computedProperties = parseToComputedProperties(storedProperties)
        
        let proxyStruct = try StructDeclSyntax("struct Proxy") {
            DeclSyntax(
            """
                private let store: \(raw: storeName)
            
                public init(store: \(raw: storeName)) {
                    self.store = store
                }
            
            """)
            
            for property in computedProperties {
                property
            }
            
            DeclSyntax(
            """
                public func dispatch<each Argument>(_ action: Action<\(raw: storeName),
                                                    repeat each Argument>, args: repeat each Argument) {
                    store.dispatch(action, args: repeat each args)
                }
            
                public func dispatch<each Argument>(_ actionPath: KeyPath<\(raw: storeName), Action<\(raw: storeName), repeat each Argument>>,
                                                    args: repeat each Argument) {
                    store.dispatch(actionPath, args: repeat each args)
                }
            
                public func dispatch<each Argument>(_ asyncAction: AsyncAction<\(raw: storeName), repeat each Argument>,
                                                    args: repeat each Argument) async {
                    await store.dispatch(asyncAction, args: repeat each args)
                }
            
                public func dispatch<each Argument>(_ asyncActionPath: KeyPath<\(raw: storeName), AsyncAction<\(raw: storeName), repeat each Argument>>,
                                                    args: repeat each Argument) async {
                    await store.dispatch(asyncActionPath, args: repeat each args)
                }
            """)
        }
        
        
        return try ExtensionDeclSyntax("extension \(raw: storeName): Store") {
            DeclSyntax(
                """
                    var proxy: \(raw: storeName).Proxy {
                        \(raw: storeName).Proxy(store: self)
                    }
                """
            )
            
            proxyStruct
        }
    }
    
    private static func buildMutatorExtension(storeName: String, storedProperties: [VariableDeclSyntax]) throws -> ExtensionDeclSyntax {
        let mutators = makeMutators(storeName: storeName, using: storedProperties)

        return try ExtensionDeclSyntax("extension \(raw: storeName)") {
            for mutator in mutators {
                mutator
            }
        }
    }

    private static func getVariables(from classDecl: ClassDeclSyntax) -> [VariableDeclSyntax] {
        let storedProperties: [VariableDeclSyntax] = classDecl.memberBlock.members.compactMap { member in
            guard let variable = member.decl.as(VariableDeclSyntax.self),
                  variable.bindings.first?.accessorBlock == nil
            else { return nil }
            return variable
        }
        
        return storedProperties
    }
    
    private static func parseToComputedProperties(_ storedProperties: [VariableDeclSyntax]) -> [DeclSyntax] {
        let computedProperties: [DeclSyntax] = storedProperties.compactMap { variable in
            guard let binding = variable.bindings.first,
                  let idPattern = binding.pattern.as(IdentifierPatternSyntax.self)
            else { return nil }
            
            let name = idPattern.identifier.text
            let type = binding.typeAnnotation?.type ?? "Any"
            
            return DeclSyntax(stringLiteral: "var \(name): \(type) { store.\(name) }")
        }
        
        return computedProperties
    }

    private static func makeMutators(storeName: String, using properties: [VariableDeclSyntax]) -> [DeclSyntax] {
        let mutators: [DeclSyntax] = properties.compactMap { variable in
            guard let binding = variable.bindings.first,
                  let idPattern = binding.pattern.as(IdentifierPatternSyntax.self),
                  variable.bindingSpecifier.text != "let"
            else { return nil }
            
            let name = idPattern.identifier.text
            let type = binding.typeAnnotation?.type ?? "Any"
            
            return DeclSyntax(
                """
                    var \(raw: name)Mutator: Action<\(raw: storeName), \(raw: type.trimmed)> {
                        Action { newValue in
                            Reducer(set: \\.\(raw: name)) {
                                return newValue
                            }
                        }
                    }
                """
            )
        }

        return mutators
    }
}
