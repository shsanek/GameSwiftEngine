/// Animation controller use `func animation` in `Node` for create
///
public final class NodeAnimationController {

    /// Stop action
    public enum StopAction {
        /// Saved current progress
        case saveProgress

        /// Call animation handler with progress 1 if need
        case toEndProgress

        /// Call animation handler with progress 0 if need
        case toStartProgress
    }

    /// Tag for identifier animation
    public let tag: String?

    /// animation speed multiplier dfault 1
    public var speed: GEFloat = 1

    var progress: GEFloat {
        currentTime / duration
    }

    var functionProgress: GEFloat {
        animationFunction.function(progress)
    }

    private let completion: ((Bool, StopAction) -> Void)?

    private let animation: (Node, GEFloat) throws -> Void
    private let animationFunction: AnimationFunction
    private weak var node: Node?
    private var startHandler: ((Node) -> Void)?

    private let duration: GEFloat
    private var currentTime: GEFloat = 0
    private var repeatCount: Int

    private var isPaused: Bool = true

    init(
        tag: String? = nil,
        node: Node,
        duration: GEFloat,
        repeatCount: Int,
        animationFunction: AnimationFunction,
        animationHandler: IAnimationHandler,
        completion: ((Bool, StopAction) -> Void)?
    ) {
        self.startHandler = animationHandler.prepareAnimation(_:)
        self.animation = animationHandler.updateAnimation(_:with:)
        self.node = node
        self.tag = tag
        self.duration = duration
        self.completion = completion
        self.animationFunction = animationFunction
        self.repeatCount = repeatCount
    }

    /// Pauses the animation
    public func play() {
        self.isPaused = false
    }

    /// Pauses the animation
    public func pause() {
        self.isPaused = true
    }

    /// Stop animation
    /// - Parameter stopAction: finished animation and remove it from node
    public func stop(_ stopAction: StopAction = .saveProgress) {
        self.stop(isFinish: false, stopAction)
    }

    func loop(_ deltaTime: GEFloat) {
        guard isPaused == false else { return }
        currentTime += deltaTime * speed
        loop()
    }

    func setCurrentTime(_ time: GEFloat) {
        currentTime = time
    }

    func loop() {
        guard let node = node else { return }
        if let startHandler = startHandler {
            startHandler(node)
            self.startHandler = nil
        }
        if currentTime > duration {
            if repeatCount > 0 {
                repeatCount -= Int(currentTime / duration);
                if repeatCount <= 0 {
                    currentTime = duration
                    try? animation(node, animationFunction.function(1))
                    stop(isFinish: true, .toEndProgress)
                    return
                }
            }
            currentTime = currentTime - GEFloat(Int(currentTime / duration)) * duration
            loop()
        } else {
            try? animation(node, functionProgress)
        }
    }

    private func stop(isFinish: Bool, _ stopAction: StopAction) {
        guard let node = node else {
            return
        }
        switch stopAction {
        case .saveProgress:
            break
        case .toEndProgress:
            if currentTime != duration {
                try? animation(node, 1)
            }
        case .toStartProgress:
            if currentTime != 0 {
                try? animation(node, 0)
            }
        }
        self.node = nil
        completion?(isFinish, stopAction)
    }
}
