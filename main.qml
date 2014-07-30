import QtQuick 2.2

import Box2D 1.1

World {
    function touchStart() {
        controlBody.x = player.x
        controlBody.y = player.y
        _touching = true
    }
    function touchEnd() {
        _touching = false
    }
    function touchMove(x, y, time) {
        // print(x + " " + y + " : " + time)
        var ratio = pixelsPerMeter * timeStep
        controlBody.linearVelocity = Qt.point(controlBody.linearVelocity.x + x / ratio, controlBody.linearVelocity.y + y / ratio)
    }

    property bool _touching: false
    id: world
    width: 1024
    height: 768
    gravity: Qt.point(0, 0)

    onStepped: {
        // if (controlBody.linearVelocity.x)
        //     console.log(friction.getReactionForce(1/world.timeStep))
        controlBody.linearVelocity = Qt.point(0, 0)
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
        width: 50
        height: 50
        x: 400
        y: 400
        linearDamping: 3.0
        angularDamping: 3.0
        sleepingAllowed: true
        bodyType: Body.Dynamic
        fixtures: Circle {
            anchors.fill: parent
            radius: width / 2
            density: 1
            friction: 0.4
            restitution: 0.5
        }
        Rectangle {
            anchors.fill: parent
            color: "red"
            radius: width
        }
    }
    Body {
        id: player
        width: 100
        height: 100
        linearDamping: 5.0
        angularDamping: 5.0
        sleepingAllowed: true
        bodyType: Body.Dynamic
        fixtures: Circle {
            anchors.fill: parent
            radius: width / 2
            density: 1
            friction: 0.4
            restitution: 0.5
        }
        Rectangle {
            anchors.fill: parent
            color: "blue"
            radius: width
        }
    }
    Body {
        id: controlBody
        width: 200
        height: 200
        sleepingAllowed: true
        fixedRotation: true
        bodyType: Body.Kinematic
        fixtures: Box {
            anchors.fill: parent
            density: 1
            friction: 0.4
            restitution: 0.5
            categories: Fixture.None
        }
        // Rectangle {
        //     anchors.fill: parent
        //     color: "blue"
        //     opacity: 0.4
        // }
    }
    FrictionJoint {
        id: friction
        bodyA: _touching ? player : null
        bodyB: controlBody
        maxForce: 50000
        maxTorque: 5
    }
    DebugDraw {
        anchors.fill: parent
        world: world
    }
}
