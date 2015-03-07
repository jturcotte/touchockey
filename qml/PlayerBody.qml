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
import Box2DStatic 2.0
import QtMultimedia 5.0
import QtQuick 2.2
import QtQuick.Particles 2.0

LightedImage {
    id: root
    property var model
    property string playerImage

    width: playerDiameterMeters * boxWorld.pixelsPerMeter
    height: playerDiameterMeters * boxWorld.pixelsPerMeter

    sourceImage: playerImage
    normalsImage: "qrc:/images/saucer_normals.png"
    lightSources: lights

    Text {
        x : (parent.width - contentWidth) / 2
        y : (parent.height - contentHeight) / 2
        width: parent.width / 2
        height: parent.height / 2
        color: "#7fffffff"
        fontSizeMode: Text.Fit
        font.pointSize: 72
        font.weight: Font.Bold
        font.family: "DejaVu Sans"
        text: model ? model.name.slice(0, 2) : ""
    }
    Emitter {
        id: fireEmitter
        property real lightIntensity: 0
        system: flamePainter.system
        width: root.width / 4
        height: width
        enabled: false

        lifeSpan: 160

        velocity: PointDirection { xVariation: width * 2; yVariation: height * 2 }

        size: root.width
        sizeVariation: size / 4
        Component.onCompleted: {
            // Add the item itself just to get a sync when it moves
            var jsArray = [fireEmitter, root]
            for (var i in lights.sources)
                jsArray.push(lights.sources[i])
            lights.sources = jsArray
        }
        Component.onDestruction: {
            var jsArray = []
            for (var i in lights.sources) {
                var o = lights.sources[i]
                if (o != fireEmitter && o != root)
                    jsArray.push(o)
            }
            lights.sources = jsArray
        }
    }

    transformOrigin: Item.TopLeft
    property QtObject body: PlayerBox2DBody {
        target: root
        world: boxWorld

        linearDamping: 1
        angularDamping: 1
        sleepingAllowed: true
        bullet: true // Ensures that the player doesn't jump over bodies within a step
        bodyType: Body.Dynamic
        Circle {
            radius: root.width / 2
            density: 1
            friction: 0.4
            restitution: 1
        }
        onThrust: {
            function rotate(vec, deg)
            {
                var rad = deg * Math.PI / 180
                var x = vec.x * Math.cos(rad) - vec.y * Math.sin(rad)
                var y = vec.x * Math.sin(rad) + vec.y * Math.cos(rad)
                return Qt.vector2d(x, y)
            }
            var fireVel = direction.times(-25)
            var numParticles = Math.max(1, Math.min(3, strength / 20))
            fireEmitter.velocity.x = fireVel.x
            fireEmitter.velocity.y = fireVel.y
            fireEmitter.burst(numParticles)
            fireEmitter.lightIntensity += strength * 0.05
            if (fireEmitter.lightIntensity > 2)
                fireEmitter.lightIntensity = 2

            // Move the emitter to the edge of the body
            var p = fireEmitter.parent
            var center = Qt.vector2d(p.width / 2, p.height / 2)
            var vecFromCenter = rotate(direction.times(p.width / 2), -root.rotation)
            var pos = center.minus(vecFromCenter).minus(Qt.vector2d(fireEmitter.width / 2, fireEmitter.height / 2))
            fireEmitter.x = pos.x
            fireEmitter.y = pos.y
        }
        onTouchStart: { thrusterLowSound.play(); thrusterHighSound.play() }
    }
    SoundEffect {
        id: thrusterLowSound
        muted: !thrusterHighSound.muted || fireEmitter.lightIntensity < 0.1
        loops: SoundEffect.Infinite
        source: "qrc:/sounds/thruster_low.wav"
    }
    SoundEffect {
        id: thrusterHighSound
        muted: fireEmitter.lightIntensity < 0.8
        loops: SoundEffect.Infinite
        source: "qrc:/sounds/thruster_high.wav"
    }
    Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: if (fireEmitter.lightIntensity > 0.01) fireEmitter.lightIntensity *= 0.5; else fireEmitter.lightIntensity = 0
    }
    // Handle touch move signals in C++, and get a thrust vector back.
    Component.onCompleted: model.touchMove.connect(body.handleTouchMove)
}
