// The MIT License (MIT)
//
// Copyright (c) 2015 Jocelyn Turcotte
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import main 1.0
import QtQuick 2.2
import QtQuick.Window 2.2
import QtQuick.Particles 2.0
import QtMultimedia 5.0
import Box2DStatic 2.0

Window {
    id: window
    property alias connectUrl: leftPanel.connectUrl
    property bool lowfi: true
    function onPlayerConnected(model) {
        var team = leftTeam.numPlayers > rightTeam.numPlayers ? rightTeam : leftTeam
        team.addPlayer(model)
        if (leftTeam.numPlayers + rightTeam.numPlayers == 1)
            setupGame()
    }
    function onPlayerDisconnected(model) {
        leftTeam.removePlayer(model)
        rightTeam.removePlayer(model)
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
    property real cornerWidthMeters: rinkWidthMeters / rinkRatio / 6
    LightGroup { id: lights }
    SoundEffect { id: hitLowSound; source: "qrc:/sounds/hit_low.wav" }
    SoundEffect { id: hitMediumSound; source: "qrc:/sounds/hit_medium.wav" }
    SoundEffect { id: hitHighSound; source: "qrc:/sounds/hit_high.wav" }
    SoundEffect { id: hitBallSound; source: "qrc:/sounds/hit_ball.wav" }
    SoundEffect { id: goalSound; source: "qrc:/sounds/goal.wav" }

    property color puckColor: "#AF860B"
    color: "#101010"

    visible: true
    width: 1920
    height: 1080
    flags: Qt.platform.os == "osx"  ? (Qt.Window | Qt.WindowFullscreenButtonHint) : Qt.Window

    Item {
        focus: true
        Keys.onPressed: if (event.key == Qt.Key_Escape) Qt.quit()
    }

    Team {
        id: leftTeam
        property color teamColor: Qt.darker("red", 2)
        teamImage: "qrc:/images/saucer_red.png"
    }
    Team {
        id: rightTeam
        property color teamColor: Qt.darker("blue", 1.5)
        teamImage: "qrc:/images/saucer_blue.png"
    }
    World {
        id: boxWorld
        pixelsPerMeter: window.width * 0.8 / rinkWidthMeters
        gravity: Qt.point(0, 0)
        onPreSolve: {
            var bodyA = contact.fixtureA.getBody();
            var bodyB = contact.fixtureB.getBody();
            var velA = bodyA.linearVelocity
            var velB = bodyB.linearVelocity
            var length = Qt.vector2d(velA.x, velA.y).minus(Qt.vector2d(velB.x, velB.y)).length()

            // Send vibration impact feedback
            if (bodyA.target.model)
                bodyA.target.model.vibrate(length * 2)
            if (bodyB.target.model)
                bodyB.target.model.vibrate(length * 2)

            // Play impact sounds
            if ((bodyA == puckBody || bodyB == puckBody) && length > 4)
                hitBallSound.play()
            else if (length > 30)
                hitHighSound.play()
            else if (length > 10)
                hitMediumSound.play()
            else if (length > 4)
                hitLowSound.play()
        }
    }

    Image {
        visible: !lowfi
        anchors.fill: parent
        source: "qrc:/images/border.png"
        fillMode: Image.Tile
    }
    Rectangle {
        id: leftGoal
        anchors { right: rink.left; verticalCenter: rink.verticalCenter}
        width: 50
        height: goalWidthMeters * boxWorld.pixelsPerMeter
        color: leftTeam.teamColor

        Body {
            target: leftGoal
            world: boxWorld
            Box {
                width: leftGoal.width
                height: leftGoal.height
                sensor: true
                collidesWith: puck.collitionCategory
                onBeginContact: {
                    rightTeam.scored()
                    goalSound.play()
                    scoreDialog.trigger("BLUE")
                }
            }
        }
    }
    Rectangle {
        id: rightGoal
        anchors { left: rink.right; verticalCenter: rink.verticalCenter}
        width: 50
        height: goalWidthMeters * boxWorld.pixelsPerMeter
        color: rightTeam.teamColor

        Body {
            target: rightGoal
            world: boxWorld
            Box {
                width: rightGoal.width
                height: rightGoal.height
                friction: 1.0
                sensor: true
                collidesWith: puck.collitionCategory
                onBeginContact: {
                    leftTeam.scored()
                    goalSound.play()
                    scoreDialog.trigger("RED")
                }
            }
        }
    }

    LightedImage {
        id: rink
        width: rinkWidthMeters * boxWorld.pixelsPerMeter
        height: rinkWidthMeters * boxWorld.pixelsPerMeter / rinkRatio
        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: rightGoal.width * 1.5
        }
        sourceImage: "qrc:/images/ft_broken01_c.png"
        normalsImage: "qrc:/images/ft_broken01_n.png"
        hRepeat: 2
        vRepeat: hRepeat / width * height
        lightSources: lights
    }
    Wall {
        id: topLeftWall
        anchors { top: rink.top; bottom: leftGoal.top; right: rink.left}
        width: 50
    }
    Wall {
        id: bottomLeftWall
        anchors { top: leftGoal.bottom; bottom: rink.bottom; right: rink.left}
        width: 50
    }
    Wall {
        id: topRightWall
        anchors { top: rink.top; bottom: rightGoal.top; left: rink.right}
        width: 50
    }
    Wall {
        id: bottomRightWall
        anchors { top: rightGoal.bottom; bottom: rink.bottom; left: rink.right}
        width: 50
    }
    Wall {
        id: topWall
        anchors { left: rink.left; right: rink.right; bottom: rink.top}
        height: 50
    }
    Wall {
        id: bottomWall
        anchors { left: rink.left; right: rink.right; top: rink.bottom}
        height: 50
    }
    Wall {
        id: leftGoalLeftWall
        anchors { right: leftGoal.left; top: leftGoal.top; bottom: leftGoal.bottom;}
        width: 50
    }
    Wall {
        id: rightGoalRightWall
        anchors { left: rightGoal.right; top: rightGoal.top; bottom: rightGoal.bottom;}
        width: 50
    }
    Corner {
        anchors { top: rink.top; left: rink.left }
        width: Math.sqrt(cornerWidthMeters * cornerWidthMeters * 2) / 2 * boxWorld.pixelsPerMeter
        height: width
        color: leftTeam.teamColor
    }
    Corner {
        anchors { top: rink.bottom; left: rink.left }
        width: Math.sqrt(cornerWidthMeters * cornerWidthMeters * 2) / 2 * boxWorld.pixelsPerMeter
        height: width
        color: leftTeam.teamColor
        rotation: -90
    }
    Corner {
        anchors { top: rink.top; left: rink.right }
        width: Math.sqrt(cornerWidthMeters * cornerWidthMeters * 2) / 2 * boxWorld.pixelsPerMeter
        height: width
        color: rightTeam.teamColor
        rotation: 90
    }
    Corner {
        anchors { top: rink.bottom; left: rink.right }
        width: Math.sqrt(cornerWidthMeters * cornerWidthMeters * 2) / 2 * boxWorld.pixelsPerMeter
        height: width
        color: rightTeam.teamColor
        rotation: 180
    }
    ShadowStrip {
        anchors.fill: rink
        points: rightGoal.x && leftGoal.x && [Qt.point(0, 0), Qt.point(width, 0)
            , mapFromItem(rightGoal, 0, 0), mapFromItem(rightGoal, rightGoal.width, 0)
            , mapFromItem(rightGoal, rightGoal.width, rightGoal.height), mapFromItem(rightGoal, 0, rightGoal.height)
            , Qt.point(width, height), Qt.point(0, height)
            , mapFromItem(leftGoal, leftGoal.width, leftGoal.height), mapFromItem(leftGoal, 0, leftGoal.height)
            , mapFromItem(leftGoal, 0, 0), mapFromItem(leftGoal, leftGoal.width, 0)
            ]
        color: "#a0000000"
    }

    Rectangle {
        id: puck
        property int collitionCategory: Fixture.Category10
        function setup() {
            rotation = 0
            x = rink.x + rink.width / 2 - width / 2
            y = rink.y + rink.height / 2 - height / 2
            body.linearVelocity = Qt.point(0, 0)
            body.angularVelocity = 0
            visible = true
        }
        visible: false
        width: puckDiameterMeters * boxWorld.pixelsPerMeter
        height: puckDiameterMeters * boxWorld.pixelsPerMeter

        color: puckColor
        radius: width
        Image {
            anchors.fill: parent
            source: "qrc:/images/globe.svg"
            rotation: -puck.rotation
        }

        transformOrigin: Item.TopLeft
        property QtObject body: Body {
            id: puckBody
            target: puck
            world: boxWorld

            linearDamping: 2.0
            angularDamping: 2.0
            sleepingAllowed: true
            bodyType: Body.Dynamic
            Circle {
                radius: puck.width / 2
                density: 0.5
                friction: 0.4
                restitution: 1
                categories: puck.collitionCategory
                }
            }
    }

    // DebugDraw {
    //     anchors.fill: parent
    //     world: boxWorld
    // }

    ImageParticle {
        id: flamePainter
        anchors.fill: parent
        system: ParticleSystem { }
        source: "qrc:/particleresources/glowdot.png"
        colorVariation: 0.1
        color: "#00ff400f"
    }
    Item {
        id: playerContainer
    }
    LeftPanel {
        id: leftPanel
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: rink.left
            leftMargin: leftGoal.width * 0.5
            rightMargin: leftGoal.width * 0.5
            bottomMargin: leftGoal.width * 0.5
            topMargin: leftGoal.width * 0.5
        }
        leftTeam: leftTeam
        rightTeam: rightTeam
    }
    ScoreDialog {
        id: scoreDialog
        anchors.fill: parent
    }
}
