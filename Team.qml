import QtQuick 2.2

QtObject {
    id: team
    property string teamImage
    property int numPlayers
    property Component playerBodyComponent: PlayerBody {}
    function scored() { score++ }
    function addPlayer(model) {
        print("CONNECTED! " + model)
        var b = playerBodyComponent.createObject(playerContainer, {model: model, playerImage: teamImage})
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
                break
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
                players[playerI].body.linearVelocity = Qt.point(0, 0)
                players[playerI].body.angularVelocity = 0
            }
        }
    }
    property int score: 0
    property var players: []
}
