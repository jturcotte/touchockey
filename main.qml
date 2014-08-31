import QtQuick 2.2
import QtQuick.Window 2.2
import QtQuick.Particles 2.0
import QtGraphicalEffects 1.0
import Box2D 1.1

Window {
    function onPlayerConnected(model) {
        if (leftTeam.players.length)
            rightTeam.addPlayer(model)
        else
            leftTeam.addPlayer(model)
    }
    function onPlayerDisconnected(model) {
        leftTeam.removePlayer(model)
    }

    function setupGame() {
        puck.setup()
        leftTeam.setup()
        rightTeam.setup()
    }

    property real playerDiameter: 2 * world.pixelsPerMeter
    property real puckDiameter: 1/3 * world.pixelsPerMeter
    property real goalWidth: 4 * world.pixelsPerMeter
    property real rinkWidth: 20 * world.pixelsPerMeter
    property real rinkRatio: 1.5

    property color rinkColor: "#43439F"
    property color puckColor: "#AF860B"
    property color leftTeamColor: "#3A8100"
    property color rightTeamColor: "#9D0A36"

    visible: true
    width: 1024
    height: 768

    Component {
        id: teamComponent
        QtObject {
            property color teamColor
            function scored() { score++ }
            function addPlayer(model) {
                print("CONNECTED! " + model)
                var b = playerBodyComponent.createObject(world, {model: model, playerColor: teamColor})
                b.setup()
                players.push(b)
            }
            function removePlayer(model) {
                print("DISCONNECTED! " + model)
                for (var i = 0; i < players.length; i++)
                    if (players[i].model === model) {
                        players[i].destroy()
                        players.splice(i, 1)
                        return
                    }
            }
            function setup() {
                for (var i = 0; i < players.length; i++) {
                    players[i].setup()
                }
            }
            property int score: 0
            property var players: []
        }
    }
    property QtObject leftTeam: teamComponent.createObject(this, {teamColor: leftTeamColor})
    property QtObject rightTeam: teamComponent.createObject(this, {teamColor: rightTeamColor})
    World {
        id: world
        anchors.fill: parent
        pixelsPerMeter: 32

        Component {
            id: playerBodyComponent
            Body {
                id: body
                property var model
                property color playerColor

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
                    Rectangle {
                        anchors.fill: parent
                        color: playerColor
                        radius: width
                        Image {
                            anchors.fill: parent
                            source: "globe.svg"
                            rotation: -body.rotation
                        }
                        Text {
                            text: model ? model.name : ""
                        }
                    }
                    Emitter {
                        id: fireEmitter
                        system: flamePainter.system
                        width: 25
                        height: 25
                        anchors.centerIn: parent
                        enabled: false

                        lifeSpan: 160

                        velocity: PointDirection { xVariation: width * 2; yVariation: height * 2 }

                        size: 24
                        sizeVariation: size
                    }
                }
                Connections {
                    target: model
                    onTouchMove: {
                        // FIXME: Find a meaning for that number
                        var ratio = world.pixelsPerMeter * 0.0005
                        body.applyForceToCenter(Qt.point(x / ratio, y / ratio))
                        var v = Qt.vector2d(x, y)
                        var fireVel = v.normalized().times(-200)
                        fireEmitter.velocity.x = fireVel.x
                        fireEmitter.velocity.y = fireVel.y
                        fireEmitter.burst(v.length())
                    }
                }
            }
        }

        width: 1024
        height: 768
        gravity: Qt.point(0, 0)

        Rectangle {
            id: background
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "gray" }
                GradientStop { position: 0.33; color: "dimgray" }
                GradientStop { position: 1.0; color: "black" }
            }
        }

        RectangularGlow {
            anchors.fill: rink
            glowRadius: 25
            cornerRadius: rink.radius
        }

        Body {
            id: leftGoal
            anchors { right: rink.left; verticalCenter: rink.verticalCenter}
            width: 50
            height: goalWidth
            fixtures: Box {
                anchors.fill: parent; friction: 1.0
                sensor: true
                collidesWith: puck.collitionCategory
                onBeginContact: {
                    leftTeam.scored()
                    setupGame()
                }
                RectangularGlow {
                    anchors.fill: parent
                    glowRadius: 10
                    cornerRadius: 0
                    color: "slategray"
                }
            }
        }
        Body {
            id: rightGoal
            anchors { left: rink.right; verticalCenter: rink.verticalCenter}
            width: 50
            height: goalWidth
            fixtures: Box {
                anchors.fill: parent; friction: 1.0
                sensor: true
                collidesWith: puck.collitionCategory
                onBeginContact: {
                    rightTeam.scored()
                    setupGame()
                }
                RectangularGlow {
                    anchors.fill: parent
                    glowRadius: 10
                    cornerRadius: 0
                    color: "slategray"
                }
            }
        }

        Rectangle {
            id: rink
            width: rinkWidth
            height: rinkWidth / rinkRatio
            anchors.centerIn: parent
            radius: 10
            gradient: Gradient {
                GradientStop { position: 0; color: rinkColor }
                GradientStop { position: 1; color: Qt.darker(rinkColor) }
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
                    color: puckColor
                    radius: width
                    Image {
                        anchors.fill: parent
                        source: "globe.svg"
                        rotation: -puck.rotation
                    }
                }
            }
        }

        Component.onCompleted: setupGame()
        // DebugDraw {
        //     anchors.fill: parent
        //     world: world
        // }

        ImageParticle {
            id: flamePainter
            anchors.fill: parent
            system: ParticleSystem { }
            source: "qrc:///particleresources/glowdot.png"
            colorVariation: 0.1
            color: "#00ff400f"
        }
    }

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
}