import MetalKit

#if canImport(UIKit)
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
            let size = Size(width: GEFloat(size.width), height: GEFloat(size.height))
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

#endif

#if canImport(Cocoa)
import Cocoa

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
            let size = Size(width: GEFloat(size.width), height: GEFloat(size.height))
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

#endif

//import ObjectEditor
//
//public protocol IEvent {
//    var identifier: String { get }
//}
//
//public struct Event<ValueType>: IEvent {
//    public let identifier: String
//    public let info: ValueType
//}
//
//public struct EventType<ValueType> {
//    public let identifier: String
//
//    public func event(_ info: ValueType) -> Event<ValueType> {
//        .init(identifier: identifier, info: info)
//    }
//}
//
//public final class EventHandler {
//    let block: (IEvent) throws -> Void
//
//    init(_ block: @escaping (IEvent) throws -> Void) {
//        self.block = block
//    }
//}
//
//public final class EventHandlersContainer {
//    weak var eventSystem: EventSystem?
//
//    var handlers: [String: ValueContainer<[EventHandler]>] = [:]
//
//    public func addHandler<VT>(_ eventType: EventType<VT>, handler: @escaping (Event<VT>) -> Void) {
//        let handler: (IEvent) throws -> Void = { event in
//            guard let event = event as? Event<VT> else {
//                throw RenderError.message("incorrect type")
//            }
//            handler(event)
//        }
//
//        handlers[eventType.identifier] = handlers[eventType.identifier] ?? .init(value: [])
//        handlers[eventType.identifier]?.value.append(EventHandler(handler))
//
//
//    }
//}
//
//public final class EventSystem {
//    private(set) var loopHandler: ValueContainer<[EventHandler]> = .init(value: [])
//    private(set) lazy var handlers: [String: ValueContainer<[EventHandler]>] = ["loop": loopHandler]
//
//    public func addHandler<VT>(_ identifier: String, handler: EventHandler) {
//        handlers[identifier]
//    }
//}
