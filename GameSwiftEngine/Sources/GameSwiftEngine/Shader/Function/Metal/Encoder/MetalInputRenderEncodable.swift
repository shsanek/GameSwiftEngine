import MetalKit

protocol MetalInputRenderEncodable: AnyInputRenderEncodable {
    static var render: MetalMetalRenderFunctionName? { get }
    static var name: String { get }

    func renderEncode(_ encoder: MTLRenderCommandEncoder, device: MTLDevice) throws
}

extension MetalInputRenderEncodable {
    static var name: String {
        return "\(Self.self)"
    }
    static var render: MetalMetalRenderFunctionName? { nil }

    func renderEncode(_ encoder: MTLRenderCommandEncoder, device: MTLDevice) throws {
    }
}
