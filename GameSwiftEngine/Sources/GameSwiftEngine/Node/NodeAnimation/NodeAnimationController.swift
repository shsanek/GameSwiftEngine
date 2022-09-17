public final class NodeAnimationController {
    public enum StopAction {
        case saveProgress
        case toEndProgress
        case toStartProgress
    }

    public let tag: String?
    var progress: Float {
        currentTime / duration
    }

    var functionProgress: Float {
        animationFunction.function(progress)
    }

    public var speed: Float = 1

    private let completion: ((Bool, StopAction) -> Void)?

    private let animation: (Node, Float) throws -> Void
    private let animationFunction: AnimationFunction
    private weak var node: Node?
    private var startHandler: ((Node) -> Void)?

    private let duration: Float
    private var currentTime: Float = 0
    private var repeatCount: Int

    private var isPaused: Bool = true

    init(
        tag: String? = nil,
        node: Node,
        duration: Float,
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

    public func play() {
        self.isPaused = false
    }

    public func pause() {
        self.isPaused = true
    }

    public func stop(_ stopAction: StopAction = .saveProgress) {
        self.stop(isFinish: false, stopAction)
    }

    func loop(_ deltaTime: Float) {
        guard isPaused == false else { return }
        currentTime += deltaTime * speed
        loop()
    }

    func setCurrentTime(_ time: Float) {
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
            currentTime = currentTime - Float(Int(currentTime / duration)) * duration
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