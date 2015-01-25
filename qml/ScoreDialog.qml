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

import QtQuick 2.2

Rectangle {
    function trigger(winningTeamName) {
        scoreText.text = winningTeamName + " SCORED!!"
        scoreIntermissionTimer.start()
    }

    id: root
    visible: false
    color: "transparent"
    Behavior on color { ColorAnimation { } }

    Text {
        id: scoreText
        y: parent.height / 2 - height / 2
        color: "white"
        font.pointSize: 128
        font.family: "Arial Black"
    }
    Timer {
        id: scoreIntermissionTimer
        interval: 1500
    }
    states: State {
        name: "scoreIntermission"
        when: scoreIntermissionTimer.running
        PropertyChanges { target: root; color: "#7f000000"}
    }
    transitions: [
        Transition {
            to: "scoreIntermission"
            SequentialAnimation {
                PropertyAction { target: boxWorld; property: "running"; value: false}
                PropertyAction { target: root; property: "visible"; value: true }
                NumberAnimation { target: scoreText; properties: "x"; from: root.width; to: root.width / 2 - scoreText.width / 2; easing.type: Easing.InOutQuad }
            }
        },
        Transition {
            from: "scoreIntermission"
            SequentialAnimation {
                NumberAnimation { target: scoreText; properties: "x"; to: -scoreText.width; easing.type: Easing.InOutQuad }
                PropertyAction { target: root; property: "visible"; value: false }
                ScriptAction { script: setupGame() }
                PropertyAction { target: boxWorld; property: "running"; value: true}
            }
        }
    ]
}