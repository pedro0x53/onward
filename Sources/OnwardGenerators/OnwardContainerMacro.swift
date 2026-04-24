import OnwardCore

@attached(member, names: arbitrary)
@attached(extension, conformances: OnwardContainerSchema)
public macro OnwardContainer() = #externalMacro(module: "OnwardGeneratorsMacros", type: "OnwardContainerMacro")
