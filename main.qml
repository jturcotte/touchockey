import main 1.0
import QtQuick 2.2
import QtQuick.Window 2.2
import QtQuick.Particles 2.0
import QtGraphicalEffects 1.0
import Box2D 1.1

Window {
    id: root
    function onPlayerConnected(model) {
        var team = leftTeam.numPlayers > rightTeam.numPlayers ? rightTeam : leftTeam
        team.addPlayer(model)
        team.setup()
    }
    function onPlayerDisconnected(model) {
        leftTeam.removePlayer(model)
    }

    function setupGame() {
        puck.setup()
        leftTeam.setup()
        rightTeam.setup()
    }

    property real playerDiameterMeters: 2
    property real puckDiameterMeters: 1
    property real rinkWidthMeters: Math.max(20, 20 + leftTeam.numPlayers * 5)
    property real rinkRatio: 1.5
    property real goalWidthMeters: rinkWidthMeters / rinkRatio / 4
    LightGroup { id: lights }

    property color rinkColor: "#43439F"
    property color puckColor: "#AF860B"
    property string leftTeamImage: "saucer_red.png"
    property string rightTeamImage: "saucer_blue.png"

    visible: true
    width: 1920
    height: 1080
    flags: Qt.Window | Qt.WindowFullscreenButtonHint

    Component {
        id: teamComponent
        QtObject {
            id: team
            property string teamImage
            property int numPlayers
            function scored() { score++ }
            function addPlayer(model) {
                print("CONNECTED! " + model)
                var b = playerBodyComponent.createObject(world, {model: model, playerImage: teamImage})
                b.x = rink.x + 100
                b.y = rink.y + 100
                players.push(b)
                numPlayers = players.length
            }
            function removePlayer(model) {
                print("DISCONNECTED! " + model)
                for (var i = 0; i < players.length; i++)
                    if (players[i].model === model) {
                        players[i].destroy()
                        players.splice(i, 1)
                        return
                    }
                numPlayers = players.length
            }
            function setup() {
                function adjXLeft(x) { return rink.x + x }
                function adjXRight(x) { return rink.x + rink.width - x }
                function adjY(y) { return rink.y + y }
                var adjX = team == leftTeam ? adjXLeft : adjXRight
                var numCols = Math.round(Math.sqrt(players.length))
                var numRows = Math.ceil(players.length / numCols)
                var colDist = rink.width / 2 / (numCols + 1)
                var rowDist = rink.height / (numRows + 1)
                var playerI = 0
                for (var i = 1; i <= numCols && playerI < players.length; ++i) {
                    for (var j = 1; j <= numRows && playerI < players.length; ++j, ++playerI) {
                        players[playerI].rotation = 0
                        players[playerI].x = adjX(i * colDist) - players[playerI].width / 2
                        players[playerI].y = adjY(j * rowDist) - players[playerI].height / 2
                    }
                }
            }
            property int score: 0
            property var players: []
        }
    }
    property QtObject leftTeam: teamComponent.createObject(this, {teamImage: leftTeamImage})
    property QtObject rightTeam: teamComponent.createObject(this, {teamImage: rightTeamImage})

    Rectangle {
        id: background
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "gray" }
            GradientStop { position: 0.33; color: "dimgray" }
            GradientStop { position: 1.0; color: "black" }
        }
    }

    World {
        id: world
        anchors.fill: parent
        pixelsPerMeter: root.width * 0.8 / rinkWidthMeters

        Component {
            id: playerBodyComponent
            Body {
                id: body
                property var model
                property string playerImage
                property real lightWidth: 50;

                width: playerDiameterMeters * world.pixelsPerMeter
                height: playerDiameterMeters * world.pixelsPerMeter
                linearDamping: 1
                angularDamping: 1
                sleepingAllowed: true
                bullet: true // Ensures that the player doesn't jump over bodies within a step
                bodyType: Body.Dynamic
                fixtures: Circle {
                    anchors.fill: parent
                    radius: width / 2
                    density: 1
                    friction: 0.4
                    restitution: 1
                    LightedImage {
                        id: image
                        anchors.fill: parent
                        sourceImage: playerImage
                        normalsImage: "saucer_normals.png"
                        lightSources: lights
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
                        function velocityDifferenceVector(toProj, onto) {
                            // Find what part of the push to removed in account for the current velocity
                            // of the body (like when you can't get any faster on a bicycle unless you
                            // start pedaling faster than what the current speed is rotating the traction
                            // wheel).
                            // There is surely a better formula than this, but here take the projection
                            // of the input movement onto the current velocity vector, and remove that part,
                            // clamping what we remove between 0 and the length of the velocity vector.
                            var unitOnto = onto.normalized()
                            var projLength = toProj.dotProduct(unitOnto)
                            var effectiveProjLength = Math.max(0, Math.min(projLength, onto.length()))
                            return unitOnto.times(effectiveProjLength)
                        }
                        // Moving the finger 100px per second will be linearly reduced by a speed of 1m per second.
                        var inputPixelPerMeter = 100
                        // How much fraction of a second it takes to reach the mps described by the finger.
                        // 1/8th of a second will be needed for the ball to reach the finger mps speed
                        // (given that we only accelerate using the velocity difference between the controller
                        // and the player body).
                        var accelFactor = body.getMass() * 8

                        var moveTime = time ? time : 16
                        var bodyVelMPS = body.linearVelocity
                        var moveVecMPS = Qt.vector2d(x, y).times(1000 / moveTime / inputPixelPerMeter)
                        var velVecMPS = Qt.vector2d(bodyVelMPS.x, bodyVelMPS.y)
                        var inputAdjustmentVec = velocityDifferenceVector(moveVecMPS, velVecMPS)
                        var adjustedMove = moveVecMPS.minus(inputAdjustmentVec)

                        var appliedForce = adjustedMove.times(accelFactor)
                        body.applyForceToCenter(Qt.point(appliedForce.x, appliedForce.y))

                        var v = Qt.vector2d(x, y)
                        var fireVel = v.normalized().times(-200)
                        fireEmitter.velocity.x = fireVel.x
                        fireEmitter.velocity.y = fireVel.y
                        fireEmitter.burst(v.length())
                        if (body.lightWidth < root.width / 3)
                            body.lightWidth += v.length() * 5
                    }
                }
                Component.onCompleted: {
                    var jsArray = [body]
                    for (var i in lights.sources)
                        jsArray.push(lights.sources[i])
                    lights.sources = jsArray
                }
                Component.onDestruction: {
                    var jsArray = []
                    for (var i in lights.sources) {
                        var o = lights.sources[i]
                        if (o != body)
                            jsArray.push(o)
                    }
                    lights.sources = jsArray
                }
                Timer {
                    interval: 16
                    running: true
                    repeat: true
                    onTriggered: if (body.lightWidth > 0) body.lightWidth -= 50
                }
            }
        }

        width: 1024
        height: 768
        gravity: Qt.point(0, 0)

        RectangularGlow {
            anchors.fill: rink
            glowRadius: 25
            color: "black"
        }

        Body {
            id: leftGoal
            anchors { right: rink.left; verticalCenter: rink.verticalCenter}
            width: 50
            height: goalWidthMeters * world.pixelsPerMeter
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
        Body {
            id: rightGoal
            anchors { left: rink.right; verticalCenter: rink.verticalCenter}
            width: 50
            height: goalWidthMeters * world.pixelsPerMeter
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

        LightedImage {
            id: rink
            width: rinkWidthMeters * world.pixelsPerMeter
            height: rinkWidthMeters * world.pixelsPerMeter / rinkRatio
            anchors.centerIn: parent
            sourceImage: "ft_broken01_c.png"
            normalsImage: "ft_broken01_n.png"
            hRepeat: 2
            vRepeat: hRepeat / width * height
            lightSources: lights
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
            id: leftGoalLeftWall
            anchors { right: leftGoal.left; top: leftGoal.top; bottom: leftGoal.bottom;}
            width: 50
            fixtures: Box { anchors.fill: parent; friction: 1.0; restitution: 1 }
        }
        Body {
            id: rightGoalRightWall
            anchors { left: rightGoal.right; top: rightGoal.top; bottom: rightGoal.bottom;}
            width: 50
            fixtures: Box { anchors.fill: parent; friction: 1.0; restitution: 1 }
        }


        Body {
            id: puck
            property int collitionCategory: Fixture.Category10

            function setup() {
                rotation = 0
                x = world.width / 2 - width / 2
                y = world.height / 2 - height / 2
                linearVelocity = Qt.point(0, 0)
                angularVelocity = 0
            }
            width: puckDiameterMeters * world.pixelsPerMeter
            height: puckDiameterMeters * world.pixelsPerMeter
            linearDamping: 3.0
            angularDamping: 3.0
            sleepingAllowed: true
            bodyType: Body.Dynamic
            fixtures: Circle {
                anchors.fill: parent
                radius: width / 2
                density: 0.5
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