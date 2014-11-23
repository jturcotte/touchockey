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
                PropertyAction { target: world; property: "running"; value: false}
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
                PropertyAction { target: world; property: "running"; value: true}
            }
        }
    ]
}