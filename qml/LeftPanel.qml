import QtQuick 2.3
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0

Item {
    property Team leftTeam
    property Team rightTeam
    property url connectUrl

    RectangularGlow {
        anchors {
            fill: scorePanel
            leftMargin: -glowRadius / 2
            rightMargin: -glowRadius / 2
            topMargin: -glowRadius / 2
            bottomMargin: -glowRadius / 2
        }
        glowRadius: 25
        opacity: 0.75
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
            color: leftTeam.teamColor
            font { pixelSize: scorePanel.textSize; bold: true; family: "Arial" }
            style: Text.Sunken; styleColor: Qt.lighter(color)
            verticalAlignment: Text.AlignVCenter
            Layout.fillHeight: true
        }
        Text {
            text: leftTeam.score
            color: leftTeam.teamColor
            font { pixelSize: scorePanel.textSize; bold: true; family: "Arial" }
            style: Text.Sunken; styleColor: Qt.lighter(color)
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            Layout.fillHeight: true
        }
        Text {
            text: "Blue: "
            color: rightTeam.teamColor
            font { pixelSize: scorePanel.textSize; bold: true; family: "Arial" }
            style: Text.Sunken; styleColor: Qt.lighter(color)
            verticalAlignment: Text.AlignVCenter
            Layout.fillHeight: true
        }
        Text {
            text: rightTeam.score
            color: rightTeam.teamColor
            font { pixelSize: scorePanel.textSize; bold: true; family: "Arial" }
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
        sourceSize {width: width; height: width }
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: connectUrlText.top
    }
    Text {
        id: connectUrlText
        text: connectUrl
        color: "white"
        font.pointSize: 24
        font.bold: true
        fontSizeMode: Text.HorizontalFit
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
