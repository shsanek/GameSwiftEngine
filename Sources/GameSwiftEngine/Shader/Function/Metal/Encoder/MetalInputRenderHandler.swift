import MetalKit

protocol MetalRenderHandler: AnyRenderHandler {
    static var dependencyFunctions: [MetalRenderFunctionName] { get }

    func renderEncode(
        _ encoder: MTLRenderCommandEncoder,
        device: MTLDevice,
        attributes: RenderAttributes,
        functionsСache: RenderFunctionsCache
    ) throws
}


extension MetalRenderHandler {
    static var dependencyFunctions: [MetalRenderFunctionName] { [] }
}


