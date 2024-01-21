import Foundation

protocol FunctionIdentifier {
    var id: String { get }
}

struct MetalRenderFunctionName: Hashable {
    let id: String
    let bundle: Bundle
    let vertexFunction: String
    let fragmentFunction: String

    var name: String {
        return "\(bundle).\(vertexFunction).\(fragmentFunction)"
    }

    init(
        bundle: Bundle = .main,
        vertexFunction: String,
        fragmentFunction: String
    ) {
        self.id = "\(bundle)\(vertexFunction)\(fragmentFunction)"
        self.bundle = bundle
        self.vertexFunction = vertexFunction
        self.fragmentFunction = fragmentFunction
    }
}



struct MetalMeshFunctionName: Hashable {
    let id: String
    let bundle: Bundle

    let meshFunction: String
    let objectFunction: String
    let fragmentFunction: String

    var name: String {
        return "\(bundle).\(meshFunction).\(fragmentFunction)\(objectFunction)"
    }

    init(bundle: Bundle = .main, meshFunction: String, objectFunction: String, fragmentFunction: String) {
        self.id = "\(bundle).\(meshFunction).\(fragmentFunction)\(objectFunction)"
        self.bundle = bundle
        self.meshFunction = meshFunction
        self.objectFunction = objectFunction
        self.fragmentFunction = fragmentFunction
    }
}
