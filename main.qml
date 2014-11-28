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

    property Component playerBodyComponent: PlayerBody {}
    property real playerDiameterMeters: 2
    property real puckDiameterMeters: 1
    property real rinkWidthMeters: Math.max(20, 20 + leftTeam.numPlayers * 5)
    property real rinkRatio: 1.5
    property real goalWidthMeters: rinkWidthMeters / rinkRatio / 4
    property real cornerWidthMeters: rinkWidthMeters / rinkRatio / 6
    LightGroup { id: lights }

    property color puckColor: "#AF860B"
    color: "#303030"

    visible: true
    width: 1920
    height: 1080
    flags: Qt.Window | Qt.WindowFullscreenButtonHint

    Team {
        id: leftTeam
        property color teamColor: Qt.darker("red", 2)
        teamImage: "saucer_red.png"
    }
    Team {
        id: rightTeam
        property color teamColor: Qt.darker("blue", 1.5)
        teamImage: "saucer_blue.png"
    }
    Image {
        anchors.fill: parent
        source: "border.png"
        fillMode: Image.Tile
    }

    World {
        id: world
        anchors.fill: parent
        pixelsPerMeter: root.width * 0.8 / rinkWidthMeters

        width: 1024
        height: 768
        gravity: Qt.point(0, 0)

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
                    scoreDialog.trigger("BLUE")
                }
                RectangularGlow {
                    anchors.fill: parent
                    glowRadius: 10
                    cornerRadius: 0
                    color: leftTeam.teamColor
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
                    scoreDialog.trigger("RED")
                }
                RectangularGlow {
                    anchors.fill: parent
                    glowRadius: 10
                    cornerRadius: 0
                    color: rightTeam.teamColor
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
            id: topLeftCornerWall
            anchors { verticalCenter: rink.top; horizontalCenter: rink.left}
            fixtures: Box {
                anchors.centerIn: parent; rotation: 45; friction: 1.0; restitution: 1
                width: cornerWidthMeters * world.pixelsPerMeter; height: width
            }
        }
        Body {
            id: topRightCornerWall
            anchors { verticalCenter: rink.top; horizontalCenter: rink.right}
            fixtures: Box {
                anchors.centerIn: parent; rotation: 45; friction: 1.0; restitution: 1
                width: cornerWidthMeters * world.pixelsPerMeter; height: width
            }
        }
        Body {
            id: bottomLeftCornerWall
            anchors { verticalCenter: rink.bottom; horizontalCenter: rink.left}
            fixtures: Box {
                anchors.centerIn: parent; rotation: 45; friction: 1.0; restitution: 1
                width: cornerWidthMeters * world.pixelsPerMeter; height: width
            }
        }
        Body {
            id: bottomRightCornerWall
            anchors { verticalCenter: rink.bottom; horizontalCenter: rink.right}
            fixtures: Box {
                anchors.centerIn: parent; rotation: 45; friction: 1.0; restitution: 1
                width: cornerWidthMeters * world.pixelsPerMeter; height: width
            }
        }
        Corner {
            anchors { top: rink.top; left: rink.left }
            width: Math.sqrt(cornerWidthMeters * cornerWidthMeters * 2) / 2 * world.pixelsPerMeter
            height: width
            color: leftTeam.teamColor
        }
        Corner {
            anchors { bottom: rink.bottom; left: rink.left }
            width: Math.sqrt(cornerWidthMeters * cornerWidthMeters * 2) / 2 * world.pixelsPerMeter
            height: width
            color: leftTeam.teamColor
            rotation: -90
        }
        Corner {
            anchors { top: rink.top; right: rink.right }
            width: Math.sqrt(cornerWidthMeters * cornerWidthMeters * 2) / 2 * world.pixelsPerMeter
            height: width
            color: rightTeam.teamColor
            rotation: 90
        }
        Corner {
            anchors { bottom: rink.bottom; right: rink.right }
            width: Math.sqrt(cornerWidthMeters * cornerWidthMeters * 2) / 2 * world.pixelsPerMeter
            height: width
            color: rightTeam.teamColor
            rotation: 180
        }
        RinkShadow {
            anchors.fill: rink
            glowRadius: 25
            goalTop: leftGoal.y && mapFromItem(leftGoal, 0, 0).y
            goalBottom: leftGoal.y && leftGoal.height && mapFromItem(leftGoal, 0, leftGoal.height).y
            color: "#a0000000"
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
        Text {
            color: leftTeam.teamColor
            text: leftTeam.score
            font.pointSize: 48
            font.bold: true
            font.family: "Arial"
            style: Text.Outline; styleColor: Qt.lighter(color)
            anchors { left: parent.left; right: leftGoal.left; verticalCenter: leftGoal.verticalCenter }
            rotation: 90
            horizontalAlignment: Text.AlignHCenter
        }
        Text {
            color: rightTeam.teamColor
            text: rightTeam.score
            font.pointSize: 48
            font.bold: true
            font.family: "Arial"
            style: Text.Outline; styleColor: Qt.lighter(color)
            anchors { right: parent.right; left: rightGoal.right; verticalCenter: rightGoal.verticalCenter }
            rotation: -90
            horizontalAlignment: Text.AlignHCenter
        }
    }

    ScoreDialog {
        id: scoreDialog
        anchors.fill: parent
    }
}
