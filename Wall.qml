import QtQuick 2.3
import Box2DStatic 2.0

Item {
    id: root

    transformOrigin: Item.TopLeft
    Body {
        target: root
        world: boxWorld
        Box {
            width: root.width
            height: root.height
            friction: 1.0
            restitution: 1
        }
    }
}
