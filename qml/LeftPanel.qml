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

import QtQuick 2.3
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0

Item {
    property Team leftTeam
    property Team rightTeam
    property url connectUrl

    Rectangle {
        anchors {
            fill: scorePanel
            leftMargin: -10
            rightMargin: -10
            topMargin: -10
            bottomMargin: -10
        }
        color: "black"
    }
    GridLayout {
        id: scorePanel
        property real textSize: scorePanel.width > 0 ? scorePanel.width / 4 : 12
        anchors { left: parent.left; right: parent.right; top: parent.top }
        columns: 2

        Text {
            id: leftTeamScore
            text: "Red: "
            color: Qt.lighter(leftTeam.teamColor)
            font { pixelSize: scorePanel.textSize; bold: true; family: "DejaVu Sans" }
            style: Text.Sunken; styleColor: Qt.lighter(color)
            verticalAlignment: Text.AlignVCenter
            Layout.fillHeight: true
        }
        Text {
            text: leftTeam.score
            color: Qt.lighter(leftTeam.teamColor)
            font { pixelSize: scorePanel.textSize; bold: true; family: "DejaVu Sans" }
            style: Text.Sunken; styleColor: Qt.lighter(color)
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            Layout.fillHeight: true
        }
        Text {
            text: "Blue: "
            color: Qt.lighter(rightTeam.teamColor)
            font { pixelSize: scorePanel.textSize; bold: true; family: "DejaVu Sans" }
            style: Text.Sunken; styleColor: Qt.lighter(color)
            verticalAlignment: Text.AlignVCenter
            Layout.fillHeight: true
        }
        Text {
            text: rightTeam.score
            color: Qt.lighter(rightTeam.teamColor)
            font { pixelSize: scorePanel.textSize; bold: true; family: "DejaVu Sans" }
            style: Text.Sunken; styleColor: Qt.lighter(color)
            horizontalAlignment: Text.AlRight
            verticalAlignment: Text.AlignVCenter
            Layout.fillHeight: true
        }
    }
    Text {
        text: "TO JOIN:"
        color: "white"
        font.pointSize: 24
        font.bold: true
        font.family: "DejaVu Sans"
        fontSizeMode: Text.HorizontalFit
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: connectQrImg.top
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    Image {
        id: connectQrImg
        source: "image://main/connectQr"
        smooth: false
        height: width
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: connectUrlText.top
    }
    Text {
        id: connectUrlText
        text: connectUrl
        color: "white"
        font.pixelSize: 24
        font.family: "DejaVu Sans"
        fontSizeMode: Text.HorizontalFit
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
