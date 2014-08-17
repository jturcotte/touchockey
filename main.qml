import QtQuick 2.2
import Box2D 1.1

World {
    id: world
    pixelsPerMeter: 32
    property real playerDiameter: 1 * pixelsPerMeter
    property real puckDiameter: 1/3 * pixelsPerMeter
    property real goalWidth: 4 * pixelsPerMeter
    property real rinkWidth: 20 * pixelsPerMeter
    property real rinkRatio: 1.5

    function onPlayerConnected(model) {
        leftTeam.addPlayer(model)
    }
    function onPlayerDisconnected(model) {
        leftTeam.removePlayer(model)
    }

    Component {
        id: playerBodyComponent
        Body {
            property var model
            function setup() {
                x = 200
                y = 200
            }
            width: playerDiameter
            height: playerDiameter
            linearDamping: 5.0
            angularDamping: 5.0
            sleepingAllowed: true
            bullet: true // Ensures that the player doesn't jump over bodies within a step
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
                color: "#a0a0ff"
                radius: width
                Text {
                    text: model ? model.name : ""
                }
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

    Component {
        id: teamComponent
        QtObject {
            function scored() { score++ }
            function addPlayer(model) {
                print("CONNECTED! " + model)
                var b = playerBodyComponent.createObject(world, {model: model})
                var c = playerControlComponent.createObject(world, {playerBody: b, model: model})
                b.setup()
                players.push(c)
            }
            function removePlayer(model) {
                print("DISCONNECTED! " + model)
                for (var i = 0; i < players.length; i++)
                    if (players[i].model === model) {
                        players[i].playerBody.destroy()
                        players[i].destroy()
                        players.splice(i, 1)
                        return
                    }
            }
            function setup() {
                for (var i = 0; i < players.length; i++) {
                    players[i].playerBody.setup()
                }
            }
            property int score: 0
            property var players: []
        }
    }
    property QtObject leftTeam: teamComponent.createObject(this)
    property QtObject rightTeam: teamComponent.createObject(this)

    width: 1024
    height: 768
    gravity: Qt.point(0, 0)

    Text {
        color: "red"
        text: "Score: " + leftTeam.score
        font.pointSize: 24
        anchors { left: parent.left; top: parent.top }
    }
    Text {
        color: "blue"
        text: "Score: " + rightTeam.score
        font.pointSize: 24
        anchors { right: parent.right; top: parent.top }
    }

    Rectangle {
        id: rink
        color: "white"
        width: rinkWidth
        height: rinkWidth / rinkRatio
        anchors.centerIn: parent
    }
    Body {
        id: leftGoal
        anchors { right: rink.left; verticalCenter: rink.verticalCenter}
        width: 100
        height: goalWidth
        fixtures: Box {
            anchors.fill: parent; friction: 1.0
            sensor: true
            collidesWith: puck.collitionCategory
            onBeginContact: {
                leftTeam.scored()
                setupGame()
            }
            Rectangle {
                anchors.fill: parent
                color: "grey"
            }
        }
    }
    Body {
        id: rightGoal
        anchors { left: rink.right; verticalCenter: rink.verticalCenter}
        width: 100
        height: goalWidth
        fixtures: Box {
            anchors.fill: parent; friction: 1.0
            sensor: true
            collidesWith: puck.collitionCategory
            onBeginContact: {
                rightTeam.scored()
                setupGame()
            }
            Rectangle {
                anchors.fill: parent
                color: "grey"
            }
        }
    }
    Body {
        id: topLeftWall
        anchors { top: rink.top; bottom: leftGoal.top; right: rink.left}
        width: 50
        fixtures: Box { anchors.fill: parent; friction: 1.0; restitution: 1 }
    }
    Body {
        id: bottomLeftWall
        anchors { top: leftGoal.bottom; bottom: rink.bottom; right: rink.left}
        width: 50
        fixtures: Box { anchors.fill: parent; friction: 1.0; restitution: 1 }
    }
    Body {
        id: topRightWall
        anchors { top: rink.top; bottom: rightGoal.top; left: rink.right}
        width: 50
        fixtures: Box { anchors.fill: parent; friction: 1.0; restitution: 1 }
    }
    Body {
        id: bottomRightWall
        anchors { top: rightGoal.bottom; bottom: rink.bottom; left: rink.right}
        width: 50
        fixtures: Box { anchors.fill: parent; friction: 1.0; restitution: 1 }
    }
    Body {
        id: topWall
        anchors { left: rink.left; right: rink.right; bottom: rink.top}
        height: 50
        fixtures: Box { anchors.fill: parent; friction: 1.0; restitution: 1 }
    }
    Body {
        id: bottomWall
        anchors { left: rink.left; right: rink.right; top: rink.bottom}
        height: 50
        fixtures: Box { anchors.fill: parent; friction: 1.0; restitution: 1 }
    }

    Body {
        id: puck
        property int collitionCategory: Fixture.Category10

        function setup() {
            x = world.width / 2
            y = world.height / 2
            linearVelocity = Qt.point(0, 0)
            angularVelocity = 0
        }
        width: puckDiameter
        height: puckDiameter
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
            categories: puck.collitionCategory
            Rectangle {
                anchors.fill: parent
                color: "red"
                radius: width
            }
        }
    }

    Component.onCompleted: setupGame()
    function setupGame() {
        puck.setup()
        leftTeam.setup()
        rightTeam.setup()
    }
    // DebugDraw {
    //     anchors.fill: parent
    //     world: world
    // }
}
