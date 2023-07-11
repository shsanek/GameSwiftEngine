import AppKit
import SwiftUI
import GameSwiftEngine
import ObjectEditor

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
        editorScene.addSubnode(node)
        let view = MetalView()
        view.controller?.node = editorScene
        let splitVM = SplitViewModel(
            contentA: AnyView(SwiftUIView(closure: { view })),
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
            SplitView(
                viewModel: splitVM
            )
        )
    }
}
