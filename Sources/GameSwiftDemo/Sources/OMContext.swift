import GameSwiftEngine
import ObjectEditor
import Foundation

public final class GameSwiftDemoModule {
    public static let bundle: Bundle = Bundle.module
}

extension OMContext {
    public static var demoContext: OMContext {
        let context = OMContext.swiftGameEngineContext
        do {
            try context.registerObjects([
                .make(name: "Zoombe", { ZombeeNode.init() }),
            ])
            try context.registerModifications([
            ])
        }
        catch {
            print(error)
        }
        return context
    }
}
