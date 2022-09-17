import MetalKit
import UIKit

public class MetalView: MTKView, MTKViewDelegate {

    public private(set) var controller: LoopController?
    private var size: CGSize = .init(width: 100, height: 100)

    public init() {
        super.init(frame: .zero, device: MTLCreateSystemDefaultDevice())
        guard let defaultDevice = device else {
            fatalError("Device loading error")
        }
        controller = LoopController(device: defaultDevice)
        colorPixelFormat = .bgra8Unorm_srgb
        depthStencilPixelFormat = .depth32Float
        clearDepth = 1
        self.delegate = self
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.size = size
    }

    public func draw(in view: MTKView) {
        do {
            let time = CACurrentMediaTime()
            let size = Size(width: Float32(size.width), height: Float32(size.height))
            try controller?.loop(screenSize: size, time: time)
            guard
                let descriptor = view.currentRenderPassDescriptor,
                let drawable = view.currentDrawable
            else {
                return
            }
            try controller?.metalRender(descriptor: descriptor, drawable: drawable, size: size)
        }
        catch {
            assertionFailure("\(error)")
        }
    }
}
