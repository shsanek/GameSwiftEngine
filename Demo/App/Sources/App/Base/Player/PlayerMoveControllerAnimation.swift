import simd
import GameSwiftEngine

final class PlayerMoveControllerAnimation {
    var isMove: Bool = false {
        didSet {
            guard isMove != oldValue else {
                return
            }
            self.state = isMove ? .startMove : .endMove
        }
    }

    var speed: GEFloat = 1 {
        didSet {
            if speed < 0.4 {
                speed = 0.4
                return
            }
            if speed > 1 {
                speed = 1
                return
            }
            currentAnimation?.speed = speed
        }
    }
    private enum State {
        case notMove
        case startMove
        case move
        case endMove
    }

    private let container: Node

    private var currentAnimation: NodeAnimationController?
    private var state: State = .notMove {
        didSet {
            guard state != oldValue else {
                return
            }
            updateState(state)
        }
    }

    init(container: Node) {
        self.container = container
        updateState(self.state)
    }

    private func updateState(_ state: State) {
        currentAnimation?.stop(.saveProgress)
        let speed: GEFloat = 0.8
        let right = vector_float3(-0.1, -0.05, 0)
        switch state {
        case .notMove:
            break
        case .startMove:
            let x = cos(0) * right.x * speed
            let y = sin(0) * right.y * speed
            var animation = NodeAnimation.move(from: container.localPosition, to: .init(x, y, 0))
            animation.duration = length(container.localPosition - right) / speed
            currentAnimation = container.addAnimation(animation, completion: { [weak self] isFinish in
                self?.state = .move
            })
        case .move:
            var animation = NodeAnimation.move { [weak self] progress in
                let angle = progress * .pi
                let x = cos(angle) * right.x * (self?.speed ?? 1)
                let y = sin(angle) * right.y * (self?.speed ?? 1)
                return .init(x, y, 0)
            }
            animation.duration = 0.8
            animation.repeatCount = 0
            animation.animationFunction = .loop
            currentAnimation = container.addAnimation(animation)
        case .endMove:
            var animation = NodeAnimation.move(from: container.localPosition, to: .zero)
            animation.duration = length(container.localPosition - .zero) / speed
            currentAnimation = container.addAnimation(animation, completion: { [weak self] isFinish in
                self?.state = .notMove
            })
        }
    }
}

