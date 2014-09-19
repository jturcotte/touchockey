#include "lightedimageitem.h"

#include <QSGGeometryNode>
#include <QQuickWindow>
#include <QSGSimpleMaterial>
#include <QSGTexture>
#include <array>
#include <memory>
#include <unordered_map>

namespace std {
template <>
struct hash<QString> {
    size_t operator()(const QString &x) const {
        return qHash(x);
    }
};
}

struct LightedImageMaterialState
{
    std::shared_ptr<QSGTexture> sourceImage;
    std::shared_ptr<QSGTexture> normalsImage;
    std::array<QVector3D, 10> lightVec;

    int compare(const LightedImageMaterialState *o) const {
	// FIXME: This assumes that lightVec is the same for all instances.
        int d = sourceImage.get() - o->sourceImage.get();
        if (d)
            return d;
        else if ((d = normalsImage.get() - o->normalsImage.get()) != 0)
            return d;
        else
            return 0;
    }
};

static std::shared_ptr<QSGTexture> createAndCacheTexture(QQuickWindow *window, const QString &path)
{
    static std::unordered_map<QString, std::weak_ptr<QSGTexture>> cachedTexturesMap;
    std::weak_ptr<QSGTexture> &cachedTexture = cachedTexturesMap[path];
    std::shared_ptr<QSGTexture> texture = cachedTexture.lock();
    if (!texture) {
        texture.reset(window->createTextureFromImage(QImage{ path }));
        texture->setHorizontalWrapMode(QSGTexture::Repeat);
        texture->setVerticalWrapMode(QSGTexture::Repeat);
        cachedTexture = texture;
    }
    return texture;
}

class LightedImageMaterialShader : public QSGSimpleMaterialShader<LightedImageMaterialState>
{
    QSG_DECLARE_SIMPLE_COMPARABLE_SHADER(LightedImageMaterialShader, LightedImageMaterialState)
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
            const int numberOfLights = 5;
            varying highp vec2 qt_TexCoord0;
            uniform highp float qt_Opacity;
            uniform sampler2D sourceImage;
            uniform sampler2D normalsImage;
            uniform highp vec3 lightVec[numberOfLights];

            void main(void)
            {
                highp vec2 pixPos = qt_TexCoord0;
                highp vec4 pix = texture2D(sourceImage, pixPos.st);
                highp vec4 pix2 = texture2D(normalsImage, pixPos.st);
                highp vec3 normal = vec3(pix2.rg * 2.0 - 1.0, pix2.b);
                highp float diffuse = 0.66;

                for(int i = 0; i < numberOfLights; i++) {
                    highp vec3 relVec = lightVec[i];
                    relVec.xy -= pixPos;
                    diffuse = min(1.0, max(diffuse, step(0.01, relVec.z) * dot(normal, normalize(relVec))));
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
        // FIXME: Check for changed and move lower.
        material->state()->sourceImage = createAndCacheTexture(window(), m_sourceImage);
        material->state()->normalsImage = createAndCacheTexture(window(), m_normalsImage);
        if (material->state()->sourceImage->hasAlphaChannel())
            material->setFlag(QSGMaterial::Blending);
        node->setFlags(QSGNode::OwnsMaterial | QSGNode::OwnsGeometry);
        node->setMaterial(material);
        node->setGeometry(new QSGGeometry{ QSGGeometry::defaultAttributes_TexturedPoint2D(), 4 });
    }

    auto material = static_cast<QSGSimpleMaterial<LightedImageMaterialState>*>(node->material());
    unsigned i = 0;
    material->state()->lightVec = { };
    if (m_lightSources)
        for (auto &item : m_lightSources->sourceItemsList()) {
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
