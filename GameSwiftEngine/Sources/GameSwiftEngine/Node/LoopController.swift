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
                try renderInTexture(for: camera)
            }
        }
        node.lightController.lightInfo.buffer = nil
        try updateHandler?(Double(delta))
    }

    @discardableResult
    public func setUpdate(_ handler: @escaping (Double) throws -> Void) -> Self {
        self.updateHandler = handler
        return self
    }

    func renderInTexture(for camera: CameraNode) throws {
        let info = camera.renderInfo
        let size: Size = info.size

        let texture = info.colorInfo.color?.getMLTexture(device: device)
        let depthTexture = info.depthInfo.depth?.getMLTexture(device: device)

        let depthAttachementTexureDescriptor = MTLRenderPassDepthAttachmentDescriptor()
        depthAttachementTexureDescriptor.clearDepth = 1.0
        depthAttachementTexureDescriptor.loadAction = .dontCare
        depthAttachementTexureDescriptor.storeAction = .store
        depthAttachementTexureDescriptor.texture = depthTexture
        depthAttachementTexureDescriptor.slice = info.depthInfo.arrayIndex

        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].texture = texture
        descriptor.colorAttachments[0].resolveTexture = nil
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.colorAttachments[0].slice = info.colorInfo.arrayIndex
        descriptor.depthAttachment = depthAttachementTexureDescriptor

        try metalRender(camera: camera, descriptor: descriptor, drawable: nil, size: size)

        camera.didRender()
    }

    func metalRender(
        camera: CameraNode? = nil,
        descriptor: MTLRenderPassDescriptor,
        drawable: CAMetalDrawable?,
        size: Size
    ) throws {
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .lessEqual
        depthDescriptor.isDepthWriteEnabled = true

        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        guard
            let commandQueue = commandQueue,
            let buffer = commandQueue.makeCommandBuffer(),
            let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor),
            let depthState = device.makeDepthStencilState(descriptor: depthDescriptor),
            let node = node
        else {
            return
        }
        let camera = camera ?? node.mainCamera

        encoder.setDepthStencilState(depthState)

        buffer.label = UUID().uuidString

        let input = MetalRenderInput(
            time: 0.1,
            device: device,
            descriptor: descriptor,
            buffer: buffer,
            encoder: encoder,
            size: .init(x: Float(size.width), y: Float(size.height)),
            projectionMatrix: perspectiveMatrix(aspectRatio: Float(size.width / size.height)),
            lightInfo: node.lightController.lightInfo,
            renderType: camera === node.mainCamera ? .mainRender : .shadowRender
        )

        var outputError: Error?
        do {
            let cameraMatrix = matrix_multiply(
                camera.projectionMatrix,
                camera.absoluteTransform.inverse
            )
            try Node.metalLoop(
                camera: camera,
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
