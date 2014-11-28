import QtQuick 2.3

ShaderEffect {
    property color color
    fragmentShader: "
        varying highp vec2 qt_TexCoord0;
        uniform lowp vec4 color;
        uniform lowp float qt_Opacity;

        void main() { gl_FragColor = color * qt_Opacity * step(qt_TexCoord0.x, 1.0 - qt_TexCoord0.y); }
    "
}
