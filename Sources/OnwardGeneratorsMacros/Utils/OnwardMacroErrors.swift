import SwiftDiagnostics

enum OnwardMacroError: String, DiagnosticMessage {
    case notAClass
    case notAFunction
    case notAVariable
    case notNamedDecl

    case missingStore
    case missingActionComponents
    case missingActionType

    case invalidReducer
    case invalidKeyPaths
    case invalidAction
    case invalidMiddleware

    case getterCountMismatch
    case setterCountMismatch

    case missingInwardType
    case missingInwardDefault

    var identifier: String { self.rawValue }
    var diagnosticID: MessageID { MessageID(domain: "OnwardMacro", id: self.identifier) }
    var severity: DiagnosticSeverity { .error }

    var message: String {
        switch self {
        case .notAClass:
            return "@Store can only be applied to classes"
        case .notAFunction:
            return "@Reducer can only be applied to functions"
        case .notAVariable:
            return "@Action can only be applied to variables"
        case .notNamedDecl:
            return "Macro can only be applied to top-level named declarations"
        case .missingStore:
            return "Macro requires T.Type conform to Store protocol"
        case .missingActionComponents:
            return "Action macro requires at least one KeyPath argument"
        case .missingActionType:
            return "Action macro requires a variable with defined type"
        case .invalidReducer:
            return "Reducer functions must have at least one get parameter or one set parameter"
        case .invalidKeyPaths:
            return "Action macro requires valid KeyPath arguments"
        case .invalidAction:
            return "Action components must be owned by the action parent"
        case .invalidMiddleware:
            return "Middleware must have 0 parameters or Store.Proxy as its only parameter, e.g. funcName(_ proxy: Store.Proxy)"
        case .getterCountMismatch:
            return "Number of parameters should be equal to the number of Reducer get/getter parameter"
        case .setterCountMismatch:
            return "Number of returning types should be equal to the number of Reducer set/setter parameter"
        case .missingInwardType:
            return "@Inward requires an explicit type annotation, e.g. `@Inward var apiClient: APIClient = ...`"
        case .missingInwardDefault:
            return "@Inward requires an initializer expression to use as the InwardKey defaultValue, e.g. `@Inward var apiClient: APIClient = DefaultAPIClient()`"
        }
    }
}
