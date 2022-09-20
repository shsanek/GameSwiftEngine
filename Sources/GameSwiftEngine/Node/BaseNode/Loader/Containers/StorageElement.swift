import Foundation

public final class StorageElement {
    public let controller: IAnyStorageElementController
    public let object: Any
    public var model: Any

    public init(controller: IAnyStorageElementController, object: Any, model: Any) {
        self.controller = controller
        self.object = object
        self.model = model
    }
}
