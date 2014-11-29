import QtQuick 2.3
import Box2DStatic 2.0

ShaderEffect {
    id: root
    property color color
    fragmentShader: "
        varying highp vec2 qt_TexCoord0;
        uniform lowp vec4 color;
        uniform lowp float qt_Opacity;

        void main() { gl_FragColor = color * qt_Opacity * step(qt_TexCoord0.x, 1.0 - qt_TexCoord0.y); }
    "

    transformOrigin: Item.TopLeft
    Body {
        target: root
        world: boxWorld
        Polygon {
            vertices: [
                Qt.point(0,0),
                Qt.point(root.width, 0),
                Qt.point(0, root.height)
            ]
        }
    }
}
