import QtQuick 2.2

import Box2D 1.1

World {
    function playerMoved(p) {
        print(p.x + " " + p.y)
        ball.applyLinearImpulse(Qt.point(10, 10), Qt.point(0, 0))
    }

    id: world
    width: 1024
    height: 768
    gravity: Qt.point(0, 0)
    Body {
        id: leftWall
        anchors { top: parent.top; bottom: parent.bottom; right: parent.left}
        width: 50
        fixtures: Box { anchors.fill: parent; friction: 1.0 }
    }
    Body {
        id: rightWall
        anchors { top: parent.top; bottom: parent.bottom; left: parent.right}
        width: 50
        fixtures: Box { anchors.fill: parent; friction: 1.0 }
    }
    Body {
        id: topWall
        anchors { left: parent.left; right: parent.right; bottom: parent.top}
        height: 50
        fixtures: Box { anchors.fill: parent; friction: 1.0 }
    }
    Body {
        id: bottomWall
        anchors { left: parent.left; right: parent.right; top: parent.bottom}
        height: 50
        fixtures: Box { anchors.fill: parent; friction: 1.0 }
    }

    Body {
        id: ball
        width: 100;
        height: 100;
        sleepingAllowed: true
        bodyType: Body.Dynamic
        fixtures: Box {
            anchors.fill: parent
            density: 1;
            friction: 0.4;
            restitution: 0.5;
        }
        Rectangle {
            anchors.fill: parent
            color: "red"
            // anchors.margins: -1
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: {
            playerMoved(Qt.point(mouse.x, mouse.y))
        }
    }
}
