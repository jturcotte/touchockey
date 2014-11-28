/****************************************************************************
**
** Copyright (C) 2013 Digia Plc and/or its subsidiary(-ies).
** Contact: http://www.qt-project.org/legal
**
** This file is part of the Qt Graphical Effects module.
**
** $QT_BEGIN_LICENSE:BSD$
** You may use this file under the terms of the BSD license as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of Digia Plc and its Subsidiary(-ies) nor the names
**     of its contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.0

ShaderEffect {

    property real glowRadius: 0.0
    property real spread: 0.0
    property color color: "white"
    property real cornerRadius: glowRadius

    property real goalTop: 0
    property real goalBottom: 0

    function clampedCornerRadius() {
        var maxCornerRadius = Math.min(width, height) / 2 + glowRadius;
        return Math.max(0, Math.min(cornerRadius, maxCornerRadius))
    }

    property real inverseSpread: 1.0 - spread
    property real relativeSizeX: ((inverseSpread * inverseSpread) * glowRadius + cornerRadius2 * 2.0) / width
    property real relativeSizeY: relativeSizeX * (width / height)
    property real cornerRadius2: clampedCornerRadius()
    property real goalTopNorm: goalTop / height
    property real goalBottomNorm: goalBottom / height

    fragmentShader: "
        uniform highp float qt_Opacity;
        uniform mediump float relativeSizeX;
        uniform mediump float relativeSizeY;
        uniform mediump float spread;
        uniform mediump float goalTopNorm;
        uniform mediump float goalBottomNorm;
        uniform lowp vec4 color;
        varying highp vec2 qt_TexCoord0;

        highp float linearstep(highp float e0, highp float e1, highp float x) {
            return clamp((x - e0) / (e1 - e0), 0.0, 1.0);
        }

        void main() {
            if (qt_TexCoord0.y > goalTopNorm && qt_TexCoord0.y < goalBottomNorm) {
                gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
            } else {
                lowp float alpha =
                    smoothstep(0.0, relativeSizeX, 0.5 - abs(0.5 - qt_TexCoord0.x)) *
                    smoothstep(0.0, relativeSizeY, 0.5 - abs(0.5 - qt_TexCoord0.y));

                highp float spreadMultiplier = linearstep(spread, 1.0 - spread, 1.0 - alpha);
                gl_FragColor = color * qt_Opacity * spreadMultiplier * spreadMultiplier;
            }
        }
    "
}
