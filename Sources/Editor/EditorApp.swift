import AppKit
import SwiftUI
import GameSwiftEngine
import ObjectEditor

import simd

@available(macOS 10.15, *)
public class AppDelegate: NSObject, NSApplicationDelegate {
    let context: OMContext

    public init(context: OMContext) {
        self.context = context
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
}

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
        let controll = CameraControl(node: editorScene)
        try? context.addAllModification(controll.controll)
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
                                CameraSettingView(controll: controll.controll)
                            }
                            Spacer()
                        }
                    }.gesture(controll.dragGesture).gesture(controll.scaleGesture)
                }
            ),
            aspect: self.splitVM?.aspect ?? 0.7
        )
        splitVM.contentB = { [context] in
            AnyView(
                EditorView(
                    context: context,
                    node: node,
                    selectHandler: selectedNode,
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

    init(controll: Node) {
        self.node = controll
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
                    ObjectEditorView(node: node)
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

struct CameraControl {
    let node: SceneNode

    let controll: Node = Node()
    let camera = EditorCameraNode()

    let lastLocation: ValueContainer<CGPoint?> = .init(value: nil)
    let statFullPosition: ValueContainer<CGPoint> = .init(value: .zero)

    var dragGesture: some Gesture {
        DragGesture().onChanged { value in
            let speed: CGFloat = 0.1
            var currentLocation: CGPoint = .zero
            currentLocation.x = value.location.x
            currentLocation.y = value.location.y

            let lastLocation = lastLocation.value ?? value.startLocation
            self.lastLocation.value = currentLocation

            statFullPosition.value.x -= (currentLocation.x - lastLocation.x) * speed
            statFullPosition.value.y -= (currentLocation.y - lastLocation.y) * speed

            controll.updateModification(NodeBaseModification.self) { mod in
                mod.localRotate.y = GEFloat(statFullPosition.value.x)
                mod.localRotate.x = GEFloat(statFullPosition.value.y)
            }
        }.onEnded { _ in
            lastLocation.value = nil
        }
    }

    private let totalZoom: ValueContainer<CGFloat> = .init(value: 10)

    var scaleGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                updateZoom(zoom: value.magnification)
            }
            .onEnded { value in
                totalZoom.value /= value.magnification
            }
    }

    func updateZoom(zoom: CGFloat) {
        let s = max(GEFloat(totalZoom.value / zoom), 1)
        print("s: \(s), z: \(zoom)")
        controll.scale(to: .init(x: s, y: s, z: s))
        camera.gridScale = s
    }

    let speed: GEFloat = 1

    init(node: SceneNode) {
        self.node = node
        install()
    }

    func install() {
        node.mainCamera.removeFromParent()
        node.mainCamera = camera
        node.addSubnode(controll)
        controll.addSubnode(camera)
        node.mainCamera.localPosition = .init(x: 0, y: 0, z: 1)
        updateZoom(zoom: 1)
    }

    var body: some View {
        ZStack {
            Button(action: {
                controll.move(on: .init(x: 0, y: 0, z: -1) * speed)
            }, label: {
                Text("w")
            }).keyboardShortcut("w", modifiers: [])
            Button(action: {
                controll.move(on: .init(x: 0, y: 0, z: 1) * speed)
            }, label: {
                Text("s")
            }).keyboardShortcut("s", modifiers: [])
            Button(action: {
                controll.move(on: .init(x: 1, y: 0, z: 0) * speed)
            }, label: {
                Text("d")
            }).keyboardShortcut("d", modifiers: [])
            Button(action: {
                controll.move(on: .init(x: -1, y: 0, z: 0) * speed)
            }, label: {
                Text("a")
            }).keyboardShortcut("a", modifiers: [])
        }.opacity(0).frame(width: 0, height: 0).position(x: -10000, y: -10000)
    }

}
