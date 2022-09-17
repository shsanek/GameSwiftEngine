import MetalKit

public final class LoopController {
    public var node: SceeneNode?
    public var updateHandler: ((_ time: Double) throws -> Void)? = nil

    private let commandQueue: MTLCommandQueue?
    private let device: MTLDevice
    private var lastTime: Double?
    private var functions: [String: AnyObject] = [:]

    init(device: MTLDevice) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()
    }

    func loop(screenSize: Size, time: Double) throws {
        guard let node = node else {
            return
        }
        let delta = lastTime.flatMap { time - $0 } ?? 0
        lastTime = time
        try Node.updateLoop(
            node: node,
            time: delta,
            size: screenSize
        )
        node.collisionController.update()
        node.lightController.calculatePosition()
        for camera in node.camers {
            if camera.isActive && camera !== node.mainCamera {
                //bla bla
            }
        }
        try updateHandler?(Double(delta))
    }

    @discardableResult
    public func setUpdate(_ handler: @escaping (Double) throws -> Void) -> Self {
        self.updateHandler = handler
        return self
    }

    func metalRender(
        descriptor: MTLRenderPassDescriptor,
        drawable: CAMetalDrawable?,
        size: Size
    ) throws {
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .lessEqual
        depthDescriptor.isDepthWriteEnabled = true

        guard
            let commandQueue = commandQueue,
            let buffer = commandQueue.makeCommandBuffer(),
            let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor),
            let depthState = device.makeDepthStencilState(descriptor: depthDescriptor),
            let node = node
        else {
            return
        }

        encoder.setDepthStencilState(depthState)
        descriptor.colorAttachments[0].loadAction = .clear

        buffer.label = UUID().uuidString

        let input = MetalRenderInput(
            time: 0.1,
            device: device,
            descriptor: descriptor,
            buffer: buffer,
            encoder: encoder,
            size: .init(x: Float(size.width), y: Float(size.height)),
            projectionMatrix: perspectiveMatrix(aspectRatio: Float(size.width / size.height)),
            lightInfo: node.lightController.lightInfo
        )

        var outputError: Error?
        do {
            let cameraMatrix = matrix_multiply(
                node.mainCamera.projectionMatrix,
                node.mainCamera.absoluteTransform.inverse
            )
            try Node.metalLoop(
                camera: node.mainCamera,
                node: node,
                cameraMatrix: cameraMatrix,
                with: &functions,
                renderInput: input
            )
        }
        catch {
            outputError = error
        }

        encoder.endEncoding()

        drawable.flatMap { buffer.present($0) }

        buffer.commit()

        if let error = outputError {
            throw error
        }
    }
}

