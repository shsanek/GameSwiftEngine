/// Struct for setting animation
public struct NodeAnimation {
    /// tag
    public var tag: String? = nil

    /// Duration may be ignored in cases of nested animation
    public var duration: GEFloat = 1

    /// Number of repeat, if zero then forever loop
    public var repeatCount: Int = 1

    /// Function for controll progress animation
    public var animationFunction: AnimationFunction = .default

    /// Maker for handler animation
    public let animationMaker: (Node) -> IAnimationHandler
}

public protocol IAnimationHandler {
    func updateAnimation(_ node: Node, with progress: GEFloat) throws
    func prepareAnimation(_ node: Node)
}

public struct AnimationHandler<NodeType: Node>: IAnimationHandler  {
    let updateHandler: (NodeType, GEFloat) throws -> Void
    var prepareHandler: (NodeType) -> Void

    public init(
        updateHandler: @escaping (NodeType, GEFloat) throws -> Void,
        prepareHandler: @escaping (NodeType) -> Void
    ) {
        self.updateHandler = updateHandler
        self.prepareHandler = prepareHandler
    }


    public func updateAnimation(_ node: Node, with progress: GEFloat) throws {
        guard let node = node as? NodeType else { return }
        try updateHandler(node, progress)
    }

    public func prepareAnimation(_ node: Node) {
        guard let node = node as? NodeType else { return }
        prepareHandler(node)
    }
}

extension AnimationHandler where NodeType == Node {
    public init(_ block: @escaping (Node, GEFloat) throws -> Void) {
        self.init(updateHandler: block, prepareHandler: { _ in })
    }
}

extension NodeAnimation {
    func makeController(
        for node: Node,
        completion: ((Bool, NodeAnimationController.StopAction) -> Void)? = nil
    ) -> NodeAnimationController {
        let animation = animationMaker(node)
        return .init(
            tag: tag,
            node: node,
            duration: duration,
            repeatCount: repeatCount,
            animationFunction: animationFunction,
            animationHandler: animation,
            completion: completion
        )
    }
}

import simd

extension NodeAnimation {

    /// Empty animation
    public static var empty: NodeAnimation {
        .init(animationMaker: { _ in return AnimationHandler { _, _ in }})
    }

    /// Animation for change position node
    public static func move(to position: @escaping (GEFloat) -> vector_float3) -> NodeAnimation {
        .init { node in
            return AnimationHandler { node, progress in
                node.move(to: position(progress))
            }
        }
    }

    /// Animation for change position node
    public static func move(to toPosition: vector_float3) -> NodeAnimation {
        .init { node in
            var fromPosition = node.localPosition
            return AnimationHandler(
                updateHandler: { node, progress in
                    node.move(to: fromPosition + (toPosition - fromPosition) * progress)
                },
                prepareHandler: { node in
                    fromPosition = node.localPosition
                }
            )
        }
    }

    /// Animation for change position node
    public static func move(from fromPosition: vector_float3, to toPosition: vector_float3) -> NodeAnimation {
        .init { node in
            return AnimationHandler { node, progress in
                node.move(to: fromPosition + (toPosition - fromPosition) * progress)
            }
        }
    }

    /// Animation for bones, only for `Object3DNode`
    public static func updateFrame(from fromFrame: Int, to toFrame: Int) -> NodeAnimation {
        .init { node in
            return AnimationHandler<Object3DNode>(
                updateHandler: { node, progress in
                    node.setTransitionProgress(progress)
                },
                prepareHandler: { node in
                    node.frameTransition(from: fromFrame, to: toFrame)
                }
            )
        }
    }

    /// Animation for bones, only for `Object3DNode`
    public static func updateFrame(from bones: [matrix_float4x4], to toFrame: Int) -> NodeAnimation {
        .init { node in
            return AnimationHandler<Object3DNode>(
                updateHandler: { node, progress in
                    node.setTransitionProgress(progress)
                },
                prepareHandler: { node in
                    node.frameTransition(from: bones, to: toFrame)
                }
            )
        }
    }

    /// Animation for bones, only for `Object3DNode`
    public static func updateFrames(_ frames: [Int]) -> NodeAnimation {
        guard frames.count > 1 else {
            if let first = frames.first {
                return .updateFrame(from: first, to: first)
            } else {
                return .empty
            }
        }
        var animations: [NodeAnimation] = []
        for i in 0..<frames.count - 1 {
            animations.append(.updateFrame(from: frames[i], to: frames[i + 1]))
        }
        return sequence(to: animations)
    }

    /// Animation sequence
    /// Animations will be executed in a row one after another
    /// By default, the length is the sum of the lengths of all animations
    /// If change duration then duration ratios persist
    public static func sequence(to animations: [NodeAnimation]) -> NodeAnimation {
        let fullDuration: GEFloat = animations.reduce(GEFloat(0), { $0 + $1.duration })
        let animations: [NodeAnimation] = animations.map {
            var animation = $0
            animation.duration = $0.duration / fullDuration
            return animation
        }
        var animation = NodeAnimation { node in
            var context: (offset: Int, controller: NodeAnimationController)? = nil

            return AnimationHandler { node, progress in
                var progress = progress
                for animation in animations.enumerated() {
                    let fullProgress = animation.element.duration
                    if progress > fullProgress {
                        progress -= fullProgress
                    } else {
                        if context?.offset != animation.offset {
                            context?.controller.stop(.saveProgress)
                            let controller = animation.element.makeController(for: node) { _, _ in
                                context = nil
                            }
                            context = (animation.offset, controller)
                        }
                        context?.controller.play()
                        context?.controller.setCurrentTime(progress)
                        context?.controller.loop()
                        return
                    }
                }
            }
        }
        animation.duration = fullDuration
        return animation
    }
}
