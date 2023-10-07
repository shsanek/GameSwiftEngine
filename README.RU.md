# [GameSwiftEngine](https://github.com/shsanek/GameSwiftEngine)

Simple engine for 3d

Features: Collision, dynamic shadow map, bones animation.

Models format:  `OBJ`, [`IQE`](http://sauerbraten.org/iqm/iqe.txt)

## Demo

![image](/Screen/1.png)

Unfortunately you will have to use your resources to run the demo

## Editor

![image](/Screen/2.jpg)

You can edit the scene in the editor. With `ObjectEditor` you can save and load the scene state and edit it (see EditorDemo). You can add to the editor your own objects inherited from `Node` with custom fields (see `DoorNode`).
[](end_description)

## Warning

⚠️ At the moment, the shadow is drawn with errors.

## Fast instruction

Added SMP

```
    .package(url: "https://github.com/shsanek/GameSwiftEngine.git", branch: "main")
```

Added import

```
import GameSwiftEngine
```

Create `MetalView`

```
let metalView = MetalView()
```

Added metal view in classic UIView

```
parentView.addSubview(metalView)
```

or you can use SwiftUIView

```
SwiftUIView {
    metalView
}
```

Сreate a `SceneNode` and attach it to the loop in you MetalView

```
let sceneNode = SceneNode()
metalView.controller.node = sceneNode
```

Use base node for to fill the stage scene

```
let texture = Texture.load(in: "Asset name")
let object = Sprite3DNode(texture: texture, size: .init(1, 1)) // generate plane
sceneNode.addSubnode(object)
```

### BaseNode

- `Node` - base node
- `SceneNode` - root node for render, contains main camera
- `Sprite3DNode` - simple 3Dmodel node, supported texture and vertex geometry
- `Object3DNode` - 3Dmodel node for IQE (see InterQuakeImporter), supported texture and vertex geometry, and bones animation
- `LightNode` - node for light controll
- `CameraNode` - for render in texture or main camera


### NodeAnimation

`NodeAnimation` - animation description, `NodeAnimationController` - for control animation

- `NodeAnimation.empty`
- `NodeAnimation.move` - for change position object
- `NodeAnimation.updateFrame` - for control transition frame in `Object3DNode`
- `NodeAnimation.sequence` - combines multiple animations

```
var animation = NodeAnimation.move(to: .init(x, y, 0))
animation.duration = 1
controller = container.addAnimation(animation)
```

### Matrix

For simplicity, there are several functions

- `perspectiveMatrix`
- `translationMatrix4x4`
- `rotationMatrix4x4`

