//
//  StoreMacro.swift
//  onward
//
//  Created by Pedro Sousa on 12/11/25.
//

import OnwardCore

@attached(extension, conformances: Store, names: arbitrary, named(proxy), named(Proxy))
public macro Store() = #externalMacro(module: "OnwardGeneratorsMacros", type: "StoreMacro")
