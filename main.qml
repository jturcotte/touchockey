import QtQuick 2.2

Canvas {
    id:canvas
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
