import SwiftUI
import GameSwiftEngine
import ObjectEditor

import simd

#if canImport(AppKit)
import AppKit

@available(macOS 10.15, *)
public class AppDelegate: NSObject, NSApplicationDelegate {
    let willResignActive: () -> Void

    public init(willResignActive: @escaping () -> Void) {
        self.willResignActive = willResignActive
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        let appMenu = NSMenuItem()
        appMenu.submenu = NSMenu()
        let mainMenu = NSMenu(title: "Editor")
        mainMenu.addItem(appMenu)
        NSApplication.shared.mainMenu = mainMenu

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func applicationWillResignActive(_ notification: Notification) {
        willResignActive()
    }
}

#endif

public final class EditorProjectManagerDelegate: IEditorProjectManagerDelegate {
    private var windows = [EditorWindow]()
    private var splitVM: SplitViewModel?

    let context: OMContext

    public init(context: OMContext) {
        self.context = context
    }

    public func openNode(
        node: IOMNode,
        selectedNode: @escaping (IOMNode?) -> Void,
        actionHandler: @escaping (IEditorAction) -> Void
    ) throws -> AnyView {
        guard let node = node as? Node else {
            throw EditorError.message("node is not NSView")
        }
        let editorScene = SceneNode()
        let controll = EditorControl(editorScene: editorScene, context: context)
        editorScene.addSubnode(node)
        let view = MetalView()
        view.controller?.node = editorScene
        let splitVM = SplitViewModel(
            contentA: AnyView(
                VStack {
                    ZStack {
                        controll.body.frame(width: 0, height: 0)
                        SwiftUIView(closure: {
                            view
                        }).focusable()
                        VStack {
                            HStack {
                                Spacer()
                                CameraSettingView(node: controll.containerNode)
                            }
                            Spacer()
                        }
                    }
                    .gesture(controll.dragGesture)
                    .gesture(controll.scaleGesture)
                }
            ),
            aspect: self.splitVM?.aspect ?? 0.8
        )
        splitVM.contentB = { [context] in
            AnyView(
                EditorView(
                    context: context,
                    node: node,
                    selectHandler: {
                        controll.selectedNode = ($0 as? Node)
                        selectedNode($0)
                    },
                    actionHandler: actionHandler
                )
            )
        }
        self.splitVM = splitVM
        return AnyView(
            VStack {
                SplitView(
                    viewModel: splitVM
                )
            }
        )
    }
}


struct CameraSettingView: View {
    @State var isOpen: Bool = false
    private let node: Node

    init(node: Node) {
        self.node = node
    }

    var body: some View {
        VStack {
            HStack {
                Text("ViewSetting")
                Spacer()
                if isOpen {
                    Image(systemName: "chevron.down.circle.fill")
                } else {
                    Image(systemName: "chevron.right.circle.fill")
                }
            }.onTapGesture {
                isOpen.toggle()
            }
            if isOpen {
                ScrollView {
                    EditorObjectView(node: node, isIdentifierShow: false)
                }
                .scrollIndicators(.hidden)
                .frame(height: 200)
            }
        }
        .frame(width: 150)
        .background(Color(cgColor: .init(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)))
        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
    }
}

extension IOMNode {
    func getModification<ModificationType>(_ type: ModificationType.Type) -> ModificationType? {
        omModifications.first(where: { $0 is ModificationType }) as? ModificationType
    }

    func updateModification<ModificationType>(
        _ type: ModificationType.Type,
        _ block: (ModificationType) -> Void
    ) {
        if let modification = getModification(type) {
            block(modification)
        }
    }
}

final class EditorNode: Node {
    let arrowNode: Node = Node()

    override init() {
        super.init()
        self.omIgnore = true
        loadArrow()
    }

    private func loadArrow() {
        guard let container = try? ObjectImporterLoader.load(.init("/Resources/Objects/arrow.obj")) else {
            return
        }
        let texture = try? TextureLoader.load(.init("/Resources/Textures/256pallet.png"))
        let xInput = Sprite3DInput(texture: texture, vertexs: container.vertexs.values.map({
            .init(position: $0.position, uv: .init(x: 0.5 / 16.0, y: 0.5 / 16.0))
        }))
        xInput.material = .gizmo
        arrowNode.addRenderInput(xInput)

        let yInput = Sprite3DInput(texture: texture, vertexs: container.vertexs.values.map({
            .init(
                position: (rotationMatrix4x4(
                    radians: Float.pi / 2,
                    axis: .init(x: 0, y: 0, z: 1)
                ) * $0.position.to4).xyz,
                uv: .init(x: 0.5 / 16.0, y: 1.5 / 16.0)
            )
        }))
        yInput.material = .gizmo
        arrowNode.addRenderInput(yInput)

        let zInput = Sprite3DInput(texture: texture, vertexs: container.vertexs.values.map({
            .init(
                position: (rotationMatrix4x4(
                    radians: Float.pi / 2,
                    axis: .init(x: 0, y: 1, z: 0)
                ) * $0.position.to4).xyz,
                uv: .init(x: 1.5 / 16.0, y: 0.5 / 16.0)
            )
        }))
        zInput.material = .gizmo
        arrowNode.addRenderInput(zInput)

        addSubnode(arrowNode)
    }

    override func loop(_ time: Double, size: Size) throws {
        try super.loop(time, size: size)
        self.lastMatrix = self.parent?.absoluteTransform.inverse ?? .init(1)
        let parent = self.parent?.position ?? .zero
        let camera = scene?.mainCamera.position ?? .zero
        let pos = camera + normalize(parent - camera) * 10
        self.localPosition = pos
    }
}

final class EditorControl {
    let editorScene: SceneNode

    let containerNode: Node = Node()
    let cameraNode = EditorCameraNode()

    private var lastLocation: CGPoint? = nil
    private var startZoom: CGFloat? = nil
    private let speed: GEFloat = 1
    private var retains = [Any?]()
    private let context: OMContext

    var selectedNode: Node? = nil {
        didSet {
            willDeselect(oldValue)
            if let node = selectedNode {
                didSelect(node)
            }
        }
    }

    private let editor = EditorNode()

    init(editorScene: SceneNode, context: OMContext) {
        self.editorScene = editorScene
        self.context = context
        install()
    }

    private func didSelect(_ node: Node) {
        node.addSubnode(editor)
    }

    private func willDeselect(_ node: Node?) {
        editor.removeFromParent()
    }

    private func install() {
        editorScene.mainCamera.removeFromParent()
        editorScene.mainCamera = cameraNode
        editorScene.addSubnode(containerNode)
        containerNode.addSubnode(cameraNode)
        editorScene.mainCamera.localPosition = .init(x: 0, y: 0, z: 1)
        try? context.addAllModification(containerNode)

        containerNode.updateModification(NodeBaseModification.self) { mod in
            mod.localRotate.y -= GEFloat(35)
            mod.localRotate.x -= GEFloat(30)
        }
        updateZoom(zoom: 1.0 / 30.0)
        startZoom = nil
    }

    var body: some View {
        ZStack {
//            Button(action: {
//                controll.move(on: .init(x: 0, y: 0, z: -1) * speed)
//            }, label: {
//                Text("w")
//            }).keyboardShortcut("w", modifiers: [])
        }.opacity(0).frame(width: 0, height: 0).position(x: -10000, y: -10000)
    }

    var dragGesture: some Gesture {
        DragGesture().onChanged { value in
            let speed: CGFloat = 0.1
            var currentLocation: CGPoint = .zero
            currentLocation.x = value.location.x
            currentLocation.y = value.location.y

            let lastLocation = self.lastLocation ?? value.startLocation
            self.lastLocation = currentLocation

            self.containerNode.updateModification(NodeBaseModification.self) { mod in
                mod.localRotate.y -= GEFloat((currentLocation.x - lastLocation.x) * speed)
                mod.localRotate.x -= GEFloat((currentLocation.y - lastLocation.y) * speed)
            }
        }.onEnded { _ in
            self.lastLocation = nil
        }
    }

    var scaleGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                self.updateZoom(zoom: value.magnification)
            }
            .onEnded { value in
                self.startZoom = nil
            }
    }

    func updateZoom(zoom: CGFloat) {
        let startZoom = self.startZoom ?? CGFloat(containerNode.localScale.x)
        self.startZoom = startZoom
        let s = max(GEFloat(startZoom / zoom), 1)
        containerNode.updateModification(NodeBaseModification.self) { mod in
            mod.localScale = .init(x: s, y: s, z: s)
        }
        cameraNode.updateModification(NodeBaseModification.self) { mod in
            mod.localScale = .init(x: 1 / s, y: 1 / s, z: 1 / s)
        }
        cameraNode.gridScale = s
    }
}
