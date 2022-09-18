import SwiftUI
import simd
import GameSwiftEngine

final class ControlState {
    var leftTriger: CGPoint?
    var rightTriger: CGPoint?

    var actionHandler: (() -> Void)?
}

final class GameState {
    lazy var controlState = ControlState()
    lazy var node = MainNode()
    lazy var view: MetalView = {
        let metalView = MetalView()
        metalView.controller?.node = node
        metalView.controller?.setUpdate { [weak self] time in
            if let triger = self?.controlState.leftTriger {
                self?.node.player?.movePlayer(
                    .init(
                        x: GEFloat(triger.x * time),
                        y: GEFloat(triger.y * time)
                    )
                )
            }
            if let triger = self?.controlState.rightTriger {
                self?.node.player?.rotatePlayer(
                    .init(
                        x: GEFloat(triger.x * time),
                        y: GEFloat(triger.y * time)
                    )
                )
            }
        }
        return metalView
    }()

    init() {
        controlState.actionHandler = { [weak self] in
            self?.node.player?.action()
        }
    }
}

