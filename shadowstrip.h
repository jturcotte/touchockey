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

#ifndef SHADOWSTRIP_H
#define SHADOWSTRIP_H

#include <QQuickItem>
#include <QSGSimpleMaterialShader>
#include <QSGGeometry>
#include <QSGGeometryNode>

class MinimalShader : public QSGSimpleMaterialShader<QColor>
{
    QSG_DECLARE_SIMPLE_SHADER(MinimalShader, QColor)
public:

    const char *vertexShader() const {
        return QT_STRINGIFY(
            attribute mediump vec4 vertex;
            attribute mediump vec2 texCoord;
            uniform mediump mat4 qt_Matrix;
            varying mediump vec2 tex;

            void main() {
                tex = texCoord;
                gl_Position = qt_Matrix * vertex;
            });
    }

    const char *fragmentShader() const {
        // return QT_STRINGIFY(
        //     varying mediump vec2 tex;
        //     uniform lowp float qt_Opacity;
        //     uniform lowp vec4 color;
        //     void main() {
        //         gl_FragColor = vec4(abs(tex), 0.0, 1.0) * qt_Opacity;
        //     });
        return QT_STRINGIFY(
            varying mediump vec2 tex;
            uniform lowp float qt_Opacity;
            uniform lowp vec4 color;

            void main() {
                lowp float alpha = 0.0;
                if (tex.y < 0.0)
                    alpha = (1.0 - tex.x) * (1.0 - abs(tex.y));
                else
                    alpha = 1.0 - tex.x * (1.0 - tex.y);
                gl_FragColor = color * alpha * alpha * qt_Opacity;
            }
        );
    }

    QList<QByteArray> attributes() const {
        return QList<QByteArray>() << "vertex" << "texCoord";
    }

    void updateState(const QColor *color, const QColor *) {
        program()->setUniformValue("color", *color);
    }

};

class ShadowStrip : public QQuickItem {
    Q_OBJECT
    Q_PROPERTY(QVariantList points MEMBER m_points WRITE setPoints FINAL)
    Q_PROPERTY(QColor color MEMBER m_color WRITE setColor FINAL)
    QVariantList m_points;
    QColor m_color;

public:
    ShadowStrip() {
        setFlag(ItemHasContents);
    }

    void setPoints(const QVariantList &points) {
        m_points = points;
        update();
    }
    void setColor(const QColor &color) {
        m_color = color;
        update();
    }

    QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) override
    {
        auto node = static_cast<QSGGeometryNode *>(oldNode);
        delete node;
        node =0;
        if (!node) {
            const float stripWidth = 50;
            const int vertexCount = m_points.size() * 4;
            const int indexCount = m_points.size() * 12;
            QSGGeometry *geometry = new QSGGeometry(QSGGeometry::defaultAttributes_TexturedPoint2D(), vertexCount, indexCount);
            geometry->setDrawingMode(GL_TRIANGLES);
            auto vertices = geometry->vertexDataAsTexturedPoint2D();
            auto indices = geometry->indexDataAsUShort();

            bool wasRightTurn = true;
            for (int i = 0; i < m_points.size(); ++i) {
                QVector2D p1{m_points[i].value<QPointF>()};
                QVector2D p2{m_points[(i+1)%m_points.size()].value<QPointF>()};
                QVector2D p3{m_points[(i+2)%m_points.size()].value<QPointF>()};
                auto ppa = (p3 - p2).normalized() * stripWidth;
                auto ppb = (p2 - p1).normalized() * stripWidth;
                float crossProduct = ppa.x() * ppb.y() - ppa.y() * ppb.x();
                bool isRightTurn = crossProduct < 0;
                if (isRightTurn)
                    ppb = -ppb;
                else
                    ppa = -ppa;

                quint16 first = vertices - geometry->vertexDataAsTexturedPoint2D();
                if (isRightTurn) {
                    // Since we go clockwise, the edge is outside the turn
                    // p3 p3b
                    // x  x
                    // |  |
                    // |  |p2a
                    // |  x---x p1a
                    // |p2
                    // x------x p1

                    // This logic only makes sense if we assume that all angles are 90deg
                    auto p12 = p2 + ppb;
                    auto p23 = p2 + ppa;
                    auto p2a = p2 + ppa + ppb;

                    *vertices++ = QSGGeometry::TexturedPoint2D{p2.x(), p2.y(), 0, 1};
                    *vertices++ = QSGGeometry::TexturedPoint2D{p12.x(), p12.y(), 0, 0};
                    *vertices++ = QSGGeometry::TexturedPoint2D{p2a.x(), p2a.y(), 1, 0};
                    *vertices++ = QSGGeometry::TexturedPoint2D{p23.x(), p23.y(), 0, 0};                    
                } else {
                    // Since we go clockwise, the edge is inside the turn
                    // p1a p1
                    // x  x
                    // |  |
                    // |  |p2
                    // |  x---x p3
                    // |p2a
                    // x------x p3b

                    // This logic only makes sense if we assume that all angles are 90deg
                    auto p12a = p2 + ppa;
                    auto p23b = p2 + ppb;
                    auto p2a = p2 + ppa + ppb;

                    // Use a negative number in the corner to trigger a different codepath in the shader for those triangles
                    *vertices++ = QSGGeometry::TexturedPoint2D{p2a.x(), p2a.y(), 1, -1};
                    *vertices++ = QSGGeometry::TexturedPoint2D{p12a.x(), p12a.y(), 1, 0};
                    *vertices++ = QSGGeometry::TexturedPoint2D{p2.x(), p2.y(), 0, 0};
                    *vertices++ = QSGGeometry::TexturedPoint2D{p23b.x(), p23b.y(), 1, 0};
                }
                bool switched = isRightTurn == wasRightTurn;
                wasRightTurn = isRightTurn;
                *indices++ = first - (switched ? 2 : 1);
                *indices++ = first - (switched ? 1 : 2);
                *indices++ = first + 1;
                *indices++ = first - (switched ? 2 : 1);
                *indices++ = first + 1;
                *indices++ = first + 2;

                *indices++ = first;
                *indices++ = first + 1;
                *indices++ = first + 2;
                *indices++ = first;
                *indices++ = first + 2;
                *indices++ = first + 3;
            }

            // Update the start indices to point to vertices at the end of the loop
            // FIXME: Check the input vertices to know if it's switched here
            bool switched = true;
            quint16 first = vertices - geometry->vertexDataAsTexturedPoint2D();
            indices = geometry->indexDataAsUShort();
            indices[0] = first - (switched ? 2 : 1);
            indices[1] = first - (switched ? 1 : 2);
            indices[3] = first - (switched ? 2 : 1);

            auto material = MinimalShader::createMaterial();
            material->setFlag(QSGMaterial::Blending);
            *material->state() = m_color;

            node = new QSGGeometryNode;
            node->setFlags(QSGNode::OwnsGeometry | QSGNode::OwnsMaterial);
            node->setGeometry(geometry);
            node->setMaterial(material);
        }
        return node;
    }
};

#endif