import AppKit
import SwiftUI
import Editor
import GameSwiftDemo
import GameSwiftEngine
import Foundation
import ObjectEditor

ResourcesPool.default.addContainer(
    FolderResourcesContainer(path: "/Users/alexandershipin/Documents/projects/GameSwiftEngine/Sources/GameSwiftDemo"),
    with: ResourcesPool.defaultContainerName
)

let editorDelegate = EditorProjectManagerDelegate(context: .demoContext)
let editor = MACEditorProjectManager(
    baseTypeIdentifier: "Node",
    context: .demoContext,
    pool: .default,
    delegate: editorDelegate
)


let app = NSApplication.shared
let delegate = AppDelegate(context: .demoContext)
app.delegate = delegate

let window = EditorWindow({ NSView() }, delegate: EditorWindow.Delegate(closeHandler: {
    editor.save()
    NSApplication.shared.terminate(0)
}))
try editor.start({ view in
    window.view = { NSHostingView(rootView: view) }
})
window.show(title: "Editor")

app.run()
