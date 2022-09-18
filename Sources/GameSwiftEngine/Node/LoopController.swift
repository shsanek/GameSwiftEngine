import MetalKit

public final class LoopController {
    public var node: SceeneNode?
    public var updateHandler: ((_ time: Double) throws -> Void)? = nil

    private let commandQueue: MTLCommandQueue?
    private let device: MTLDevice
    private let functions = RenderFunctionsCache()
    private var lastTime: Double?

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

        node.voxelsSystemController.loop()
        try Node.updateLoop(
            node: node,
            time: delta,
            size: screenSize
        )
        node.voxelsSystemController.loop()
        node.collisionController.loop()
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

        let texture = info.colorInfo.color?.metal?.getMLTexture(device: device)
        let depthTexture = info.depthInfo.depth?.metal?.getMLTexture(device: device)

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
        descriptor.renderTargetWidth = Int(size.width)
        descriptor.renderTargetHeight = Int(size.height)

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
            encoder: encoder,
            size: .init(x: GEFloat(size.width), y: GEFloat(size.height)),
            attributes: camera.renderInfo.renderAttributes,
            functionCache: functions,
            projectionMatrix: perspectiveMatrix(aspectRatio: GEFloat(size.width / size.height)),
            lightInfo: node.lightController.lightInfo
        )

        let viewPort = MTLViewport(
            originX: 0,
            originY: 0,
            width: Double(input.size.x),
            height: Double(input.size.y),
            znear: -1,
            zfar: 1
        )


        encoder.setViewport(viewPort)

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
