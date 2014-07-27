import QtQuick 2.2

Canvas {
    function playerMoved(p) {
        print(p.x + " " + p.y)
        var ctx = canvas.getContext('2d');
        ctx.fillStyle = 'red'
        ctx.fillRect(p.x, p.y, 40, 40)
        canvas.markDirty(p.x, p.y, 40, 40);
    }
    id:canvas
    width: 1024
    height: 768
    // onPaint:{
    //     var ctx = canvas.getContext('2d');
    //     ctx.fillStyle = 'red'
    //     ctx.fillRect(10, 10, 40, 40)
    // }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: {
            print(mouse.x + " " + mouse.y)
            var ctx = canvas.getContext('2d');
            ctx.fillStyle = 'red'
            ctx.fillRect(mouse.x, mouse.y, 40, 40)
            canvas.markDirty(mouse.x, mouse.y, 40, 40);
        }
    }
}
