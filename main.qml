import QtQuick 2.2
import Box2D 1.1

World {
    id: world
    function onPlayerConnected(model) {
        leftTeam.addPlayer(model)
    }
    function onPlayerDisconnected(model) {
        leftTeam.removePlayer(model)
    }

    Component {
        id: playerBodyComponent
        Body {
            function setup() {
                x = 200
                y = 200
            }
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

    Component {
        id: teamComponent
        QtObject {
            function scored() { score++ }
            function addPlayer(model) {
                print("CONNECTED! " + model)
                var b = playerBodyComponent.createObject(world)
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
        id: leftGoal
        anchors { left: parent.left; verticalCenter: parent.verticalCenter}
        width: 100
        height: 500
        fixtures: Box {
            anchors.fill: parent; friction: 1.0
            sensor: true
            collidesWith: ball.collitionCategory
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
        anchors { right: parent.right; verticalCenter: parent.verticalCenter}
        width: 100
        height: 500
        fixtures: Box {
            anchors.fill: parent; friction: 1.0
            sensor: true
            collidesWith: ball.collitionCategory
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
        id: ball
        property int collitionCategory: Fixture.Category10

        function setup() {
            x = world.width / 2
            y = world.height / 2
            linearVelocity = Qt.point(0, 0)
            angularVelocity = 0
        }
        width: 50
        height: 50
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
            categories: ball.collitionCategory
            Rectangle {
                anchors.fill: parent
                color: "red"
                radius: width
            }
        }
    }

    Component.onCompleted: setupGame()
    function setupGame() {
        ball.setup()
        leftTeam.setup()
        rightTeam.setup()
    }
    // DebugDraw {
    //     anchors.fill: parent
    //     world: world
    // }
}
