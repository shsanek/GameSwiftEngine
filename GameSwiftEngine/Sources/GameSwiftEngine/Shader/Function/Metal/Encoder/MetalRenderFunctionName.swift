import Foundation

struct MetalMetalRenderFunctionName {
    let bundle: Bundle
    let vertexFunction: String
    let fragmentFunction: String

    init(
        bundle: Bundle = .main,
        vertexFunction: String,
        fragmentFunction: String
    ) {
        self.bundle = bundle
        self.vertexFunction = vertexFunction
        self.fragmentFunction = fragmentFunction
    }
}
