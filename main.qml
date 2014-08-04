import QtQuick 2.2

import Box2D 1.1

World {
    id: world
    function onPlayerConnected(model) {
        print("CONNECTED! " + model)
        var b = playerBodyComponent.createObject(world)
        var c = playerControlComponent.createObject(world, {playerBody: b, model: model})
    }

    Component {
        id: playerBodyComponent
        Body {
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
                restitution: 1
            }
            Rectangle {
                anchors.fill: parent
                color: "blue"
                radius: width
            }
        }
    }
    Component {
        id: playerControlComponent
        Body {
            id: controlBody
            property Item playerBody
            property var model
            property bool _touching: false

            Connections {
                target: world
                onStepped: {
                    // if (controlBody.linearVelocity.x)
                    //     console.log(friction.getReactionForce(1/world.timeStep))
                    controlBody.linearVelocity = Qt.point(0, 0)
                }
            }
            Connections {
                target: model
                onTouchStart: {
                    controlBody.x = playerBody.x
                    controlBody.y = playerBody.y
                    _touching = true
                }
                onTouchEnd: {
                    _touching = false
                }
                onTouchMove: {
                    // print(x + " " + y + " : " + time)
                    var ratio = pixelsPerMeter * timeStep
                    controlBody.linearVelocity = Qt.point(controlBody.linearVelocity.x + x / ratio, controlBody.linearVelocity.y + y / ratio)
                }
            }

            width: 200
            height: 200
            sleepingAllowed: true
            fixedRotation: true
            bodyType: Body.Kinematic
            fixtures: Box {
                anchors.fill: parent
                density: 1
                friction: 0.4
                restitution: 1
                categories: Fixture.None
            }
            // Rectangle {
            //     anchors.fill: parent
            //     color: "blue"
            //     opacity: 0.4
            // }
            FrictionJoint {
                id: friction
                bodyA: _touching ? playerBody : null
                bodyB: controlBody
                maxForce: 50000
                maxTorque: 5
            }
        }
    }

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
            restitution: 1
        }
        Rectangle {
            anchors.fill: parent
            color: "red"
            radius: width
        }
    }
    // DebugDraw {
    //     anchors.fill: parent
    //     world: world
    // }
}
