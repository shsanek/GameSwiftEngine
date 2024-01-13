import simd
import GameSwiftEngine
import Foundation

class DoorNode: Node, INodeActive {
    enum State {
        case close
        case open
    }

    var state: State = .close

    private let texture: Texture?

    init(texture: Texture? = Texture.load(in: "Resources/Textures/DOOR_2B.png", bundle: Bundle.module)) {
        self.texture = texture
        super.init()
        let x: GEFloat = 0.5
        let y: GEFloat = 0.5
        let z: GEFloat = 0.1
        let encoder = Sprite3DInput(
            texture: texture,
            vertexs: [
                .init(position: .init(x: x, y: y, z: -z), uv: .init(1, 1)),
                .init(position: .init(x: -x, y: y, z: -z), uv: .init(0, 1)),
                .init(position: .init(x: -x, y: -y, z: -z), uv: .init(0, 0)),

                .init(position: .init(x: -x, y: -y, z: -z), uv: .init(0, 0)),
                .init(position: .init(x: x, y: -y, z: -z), uv: .init(1, 0)),
                .init(position: .init(x: x, y: y, z: -z), uv: .init(1, 1)),

                .init(position: .init(x: -x, y: -y, z: z), uv: .init(0, 0)),
                .init(position: .init(x: -x, y: y, z: z), uv: .init(0, 1)),
                .init(position: .init(x: x, y: y, z: z), uv: .init(1, 1)),

                .init(position: .init(x: x, y: y, z: z), uv: .init(1, 1)),
                .init(position: .init(x: x, y: -y, z: z), uv: .init(1, 0)),
                .init(position: .init(x: -x, y: -y, z: z), uv: .init(0, 0))
            ]
        )
        addRenderInput(encoder)

        addCollision(y: z, angle: 0)
        addCollision(y: -z, angle: -.pi)

        let light = LightNode()
        light.power = 0.05
        light.color = .init(x: 1, y: 0, z: 0)
        // addSubnode(light)
        light.move(to: .init(0, 0.5, 0))
    }

    

    override func loop(_ time: Double, size: Size) throws {
        try super.loop(time, size: size)
        voxelElementController.lockNeedUpdate {
            let time = Float(time)
            let speed: Float = localScale.x
            if localPosition.x < speed && state == .open {
                move(on: .init(x: GEFloat(speed * time), y: 0, z: 0))
            }
            if state == .open && localPosition.x > speed {
                move(to: .init(x: 1, y: 0, z: 0))
            }
            if localPosition.x > 0 && state == .close {
                move(on: .init(x: -GEFloat(speed * time), y: 0, z: 0))
            }
            if state == .close && localPosition.x < 0 {
                move(to: .init(x: 0, y: 0, z: 0))
            }
        }
    }

    func action() {
        state = (state == .close ? .open : .close)
    }
}

import SwiftUI
import ObjectEditor

extension DoorNode {
    var isOpen: Bool {
        get {
            state == .open
        }
        set {
            state = newValue ? .open : .close
        }
    }
}



struct DoorNodeModification: IEditorModification {
    @Editable public var isOpen: Bool = false
    
    
    enum CodingKeys: String, CodingKey {
        case isOpen
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isOpen = try container.decode(Bool.self, forKey: .isOpen)
    }
    
    public init(isOpen: Bool = false) {
        self.isOpen = isOpen
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.isOpen, forKey: .isOpen)
    }
    
#if canImport (SwiftUI)
    public func _makeEditSwiftUIView() throws -> AnyView {
        let views: [EditorModificationView.ViewContainer] = [
            .init(id: "isOpen", view: try _isOpen.createEditorSwiftUIView(with: "isOpen"))
        ]
        return AnyView(EditorModificationView(views: views))
    }
#endif
    
    public init(_ object: DoorNode) {
        self.isOpen = object.isOpen
    }
    
    public func _subscribeObject(_ object: DoorNode) {
        
        
        self._isOpen.updateObjectHandler = { [weak object] in
            guard let object = object else {
                return
            }
            object.isOpen = $0
        }
    }
    
    public func _updateObject(_ object: DoorNode) {
        object.isOpen = self.isOpen
    }
    
    public func _updateModification(_ object: DoorNode) {
        self.isOpen = object.isOpen
    }
    
    public static var defaultValue: Self {
        .init()
    }
    
    
}
