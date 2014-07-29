import QtQuick 2.2

import Box2D 1.1

World {
    function playerMoved(x, y, time) {
        print(x + " " + y + " : " + time)
        var ratio = pixelsPerMeter * timeStep
        controlSurface.linearVelocity = Qt.point(controlSurface.linearVelocity.x + x / ratio, controlSurface.linearVelocity.y + y / ratio)
    }

    id: world
    width: 1024
    height: 768
    gravity: Qt.point(0, 0)

    onStepped: {
        if (controlSurface.linearVelocity.x)
            console.log(friction.getReactionForce(1/world.timeStep))
        controlSurface.linearVelocity = Qt.point(0, 0)
    }
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
        fixedRotation: true
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
    Body {
        id: controlSurface
        property var posAfterStep: Qt.point(x, y)
        width: 200;
        height: 200;
        sleepingAllowed: true
        fixedRotation: true
        bodyType: Body.Kinematic
        fixtures: Box {
            anchors.fill: parent
            density: 1;
            friction: 0.4;
            restitution: 0.5;
        }
        Rectangle {
            anchors.fill: parent
            color: "blue"
            opacity: 0.4
        }
    }
    FrictionJoint {
        id: friction
        bodyA: ball
        bodyB: controlSurface
        maxForce: 50000
        maxTorque: 5
        localAnchorA: bodyA.getLocalCenter()
        localAnchorB: bodyB.getLocalCenter()
    }
    DebugDraw {
        anchors.fill: parent
        world: world
    }
}
