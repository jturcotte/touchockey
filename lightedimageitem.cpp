#include "lightedimageitem.h"

#include <QSGGeometryNode>
#include <QQuickWindow>
#include <QSGSimpleMaterial>
#include <QSGTexture>
#include <array>

#include <memory>

struct LightedImageMaterialState
{
    std::unique_ptr<QSGTexture> sourceImage;
    std::unique_ptr<QSGTexture> normalsImage;
    std::array<QVector3D, 10> lightVec;
};

class LightedImageMaterialShader : public QSGSimpleMaterialShader<LightedImageMaterialState>
{
    QSG_DECLARE_SIMPLE_SHADER(LightedImageMaterialShader, LightedImageMaterialState)
public:

    const char *vertexShader() const {
        return QT_STRINGIFY(
            attribute highp vec4 vertex;
            attribute highp vec2 tex;
            uniform highp mat4 qt_Matrix;
            varying highp vec2 qt_TexCoord0;

            void main() {
                qt_TexCoord0 = tex;
                gl_Position = qt_Matrix * vertex;
            }
        );
    }

    const char *fragmentShader() const {
        return QT_STRINGIFY(
            varying highp vec2 qt_TexCoord0;
            uniform highp float qt_Opacity;
            uniform sampler2D sourceImage;
            uniform sampler2D normalsImage;
            uniform highp vec3 lightVec[10];

            void main(void)
            {
                highp vec2 pixPos = qt_TexCoord0;
                highp vec4 pix = texture2D(sourceImage, pixPos.st);
                highp vec4 pix2 = texture2D(normalsImage, pixPos.st);
                highp vec3 normal = vec3(pix2.rg * 2.0 - 1.0, pix2.b);
                highp float diffuse = 0.66;

                for(int i = 0; i <= 10; ++i) {
                    highp float factor = step(0.01, lightVec[i].z);
                    highp vec3 relVec = lightVec[i];
                    relVec.xy -= pixPos;
                    diffuse = min(1.0, max(diffuse, factor * dot(normal, normalize(relVec))));
                }

                highp vec4 color = vec4(diffuse * pix.rgb, pix.a);
                gl_FragColor = color * qt_Opacity;
            }
        );
    }

    QList<QByteArray> attributes() const override {
        return QList<QByteArray>() << "vertex" << "tex";
    }

    void resolveUniforms() override {
        program()->bind();
        program()->setUniformValue("sourceImage", 0);
        program()->setUniformValue("normalsImage", 1);
    }

    void updateState(const LightedImageMaterialState *state, const LightedImageMaterialState *) override {
        glActiveTexture(GL_TEXTURE1);
        state->normalsImage->bind();
        glActiveTexture(GL_TEXTURE0);
        state->sourceImage->bind();
        program()->setUniformValueArray("lightVec", state->lightVec.data(), state->lightVec.size());
    }

};


LightedImageItem::LightedImageItem()
{
    setFlag(ItemHasContents);
}

QSGNode *LightedImageItem::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *)
{
    auto node = static_cast<QSGGeometryNode *>(oldNode);
    if (!node) {
        node = new QSGGeometryNode;
        auto material = LightedImageMaterialShader::createMaterial();
        material->setFlag(QSGMaterial::Blending);
        // FIXME: Check for changed and move lower.
        material->state()->sourceImage.reset(window()->createTextureFromImage(QImage{ m_sourceImage }));
        material->state()->sourceImage->setHorizontalWrapMode(QSGTexture::Repeat);
        material->state()->sourceImage->setVerticalWrapMode(QSGTexture::Repeat);
        material->state()->normalsImage.reset(window()->createTextureFromImage(QImage{ m_normalsImage }));
        material->state()->normalsImage->setHorizontalWrapMode(QSGTexture::Repeat);
        material->state()->normalsImage->setVerticalWrapMode(QSGTexture::Repeat);
        node->setFlags(QSGNode::OwnsMaterial | QSGNode::OwnsGeometry);
        node->setMaterial(material);
        node->setGeometry(new QSGGeometry{ QSGGeometry::defaultAttributes_TexturedPoint2D(), 4 });
    }

    auto material = static_cast<QSGSimpleMaterial<LightedImageMaterialState>*>(node->material());
    unsigned i = 0;
    material->state()->lightVec = { };
    for (auto &item : m_lightSourceItems) {
        if (i >= material->state()->lightVec.size())
            break;
        if (item->property("lightWidth").toFloat() <= 0)
            continue;
        material->state()->lightVec[i] = QVector3D(mapFromItem(item, item->boundingRect().center()));
        material->state()->lightVec[i][0] *= m_hRepeat / width();
        material->state()->lightVec[i][1] *= m_vRepeat / height();
        material->state()->lightVec[i][2] = item->property("lightWidth").toFloat() * m_hRepeat / width();
        ++i;
    }

    QSGGeometry::updateTexturedRectGeometry(node->geometry(), boundingRect(), QRectF{ 0, 0, m_hRepeat, m_vRepeat });
    node->markDirty(QSGNode::DirtyGeometry);
    node->markDirty(QSGNode::DirtyMaterial);

    return node;
}
