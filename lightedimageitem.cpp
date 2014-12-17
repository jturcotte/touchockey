#include "lightedimageitem.h"

#include <QSGGeometryNode>
#include <QQuickWindow>
#include <QSGSimpleMaterial>
#include <QSGTexture>
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
    LightGroup::LightPosArray *lightWorldPositions = nullptr;
    LightGroup::LightIntensityArray *lightIntensities = nullptr;

    int compare(const LightedImageMaterialState *o) const {
        int d = sourceImage.get() - o->sourceImage.get();
        if (d)
            return d;
        else if ((d = normalsImage.get() - o->normalsImage.get()) != 0)
            return d;
        else if ((d = lightWorldPositions - o->lightWorldPositions) != 0)
            return d;
        else
            return lightIntensities - o->lightIntensities;
    }
};

struct LightedPoint2D {
    static LightedPoint2D *from(QSGGeometry *g) { return static_cast<LightedPoint2D *>(g->vertexData()); }
    QVector2D pos;
    QVector2D tex;
    QVector2D tangent;
    QVector2D vertWorldPos;
};

static QSGGeometry::Attribute LightedImageNode_Attributes[] = {
    QSGGeometry::Attribute::create(0, 2, GL_FLOAT, true),   // pos
    QSGGeometry::Attribute::create(1, 2, GL_FLOAT),         // tex
    QSGGeometry::Attribute::create(2, 2, GL_FLOAT),         // tangent
    QSGGeometry::Attribute::create(3, 2, GL_FLOAT),         // vertWorldPos
};

static QSGGeometry::AttributeSet LightedImageNode_AttributeSet = {
    4, // Attribute Count
    (2+2+2+2) * sizeof(float),
    LightedImageNode_Attributes
};

static void updateGeometry(QSGGeometry *g, const QRectF &rect, const QRectF &textureRect)
{
    auto *v = LightedPoint2D::from(g);
    v[0] = { QVector2D(rect.topLeft()), QVector2D(textureRect.topLeft()), QVector2D(), QVector2D() };
    v[1] = { QVector2D(rect.bottomLeft()), QVector2D(textureRect.bottomLeft()), QVector2D(), QVector2D() };
    v[2] = { QVector2D(rect.topRight()), QVector2D(textureRect.topRight()), QVector2D(), QVector2D() };
    v[3] = { QVector2D(rect.bottomRight()), QVector2D(textureRect.bottomRight()), QVector2D(), QVector2D() };
}

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
            const int numberOfLights = 5;
            attribute highp vec4 vertex;
            attribute highp vec2 tex;
            attribute highp vec3 tangent;
            attribute highp vec3 vertWorldPos;
            uniform highp vec2 lightWorldPos[numberOfLights];
            uniform highp float lightIntensities[numberOfLights];
            uniform highp mat4 qt_Matrix;
            varying highp vec2 qt_TexCoord0;
            varying highp vec3 lightVecTangent[numberOfLights];

            void main() {
                qt_TexCoord0 = tex;
                gl_Position = qt_Matrix * vertex;

                // The normal is always (0,0,1) and we can calculate the bitangent,
                // so we only need the tangent to calculate a matrix to get the light
                // vectors into tangent space.
                vec3 normal = vec3(0.0, 0.0, 1.0);
                vec3 bitangent = cross(normal, tangent);
                mat3 toTanMat = mat3(tangent , bitangent , normal);

                for(int i = 0; i < numberOfLights; i++) {
                    // Get the light vector
                    vec3 lightVec = vec3(lightWorldPos[i], 50.0 * lightIntensities[i]) - vertWorldPos;
                    // Rotate the vector into tangent space
                    lightVecTangent[i] = toTanMat * lightVec;
                }
            }
        );
    }

    const char *fragmentShader() const {
        return QT_STRINGIFY(
            const int numberOfLights = 5;
            varying highp vec2 qt_TexCoord0;
            varying highp vec3 lightVecTangent[numberOfLights];
            uniform highp float qt_Opacity;
            uniform highp float lightIntensities[numberOfLights];
            uniform sampler2D sourceImage;
            uniform sampler2D normalsImage;

            void main(void) {
                highp vec2 pixPos = qt_TexCoord0;
                highp vec4 pix = texture2D(sourceImage, pixPos.st);
                highp vec4 pix2 = texture2D(normalsImage, pixPos.st);
                highp vec3 normal = vec3(pix2.rg * 2.0 - 1.0, pix2.b);
                highp float diffuse = 0.66;

                // Unroll the loop, my HD3000 doesn't like non-const array lookups.
                highp vec3 relVec;
                relVec = normalize(lightVecTangent[0]);
                diffuse += lightIntensities[0] * 0.4 * dot(normal, relVec);
                relVec = normalize(lightVecTangent[1]);
                diffuse += lightIntensities[1] * 0.4 * dot(normal, relVec);
                relVec = normalize(lightVecTangent[2]);
                diffuse += lightIntensities[2] * 0.4 * dot(normal, relVec);
                relVec = normalize(lightVecTangent[3]);
                diffuse += lightIntensities[3] * 0.4 * dot(normal, relVec);
                relVec = normalize(lightVecTangent[4]);
                diffuse += lightIntensities[4] * 0.4 * dot(normal, relVec);

                diffuse = clamp(diffuse, 0.0, 1.0);

                highp vec4 color = vec4(diffuse * pix.rgb, pix.a);
                gl_FragColor = color * qt_Opacity;
            }
        );
    }

    QList<QByteArray> attributes() const override {
        return QList<QByteArray>() << "vertex" << "tex" << "tangent" << "vertWorldPos";
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
        program()->setUniformValueArray("lightWorldPos", state->lightWorldPositions->data(), state->lightWorldPositions->size());
        program()->setUniformValueArray("lightIntensities", state->lightIntensities->data(), state->lightIntensities->size(), 1);
    }

};

class LightedImageNode : public QSGGeometryNode {
public:
    LightedImageNode() {
        setFlags(QSGNode::UsePreprocess);
        setFlags(QSGNode::OwnsGeometry);
        setGeometry(new QSGGeometry{ LightedImageNode_AttributeSet, 4 });
    }
    void preprocess() override {
        // The renderer will already do this, but only after preprocessing.
        // We have to recalculate the whole matrix chain ourselves to allow
        // batching geometries having different matrices, and store the extra
        // transformation info as attributes.
        QSGNode *n = this;
        QMatrix4x4 m;
        while (n) {
            if (n->type() == QSGNode::TransformNodeType) {
                auto &nodeMatrix = static_cast<QSGTransformNode *>(n)->matrix();
                if (!nodeMatrix.isIdentity())
                    m *= nodeMatrix;
            }
            n = n->parent();
        }

        auto inverse = m.inverted();
        auto v = LightedPoint2D::from(geometry());
        // Pick the x-axis part of the tangent space basis matrix and reconstruct it in the vertex shader.
        QVector2D tangent = QVector2D(inverse(0, 0), inverse(1, 0));
        v[0].tangent = v[1].tangent = v[2].tangent = v[3].tangent = tangent;

        v[0].vertWorldPos = QVector2D(m.map(v[0].pos.toPointF()));
        v[1].vertWorldPos = QVector2D(m.map(v[1].pos.toPointF()));
        v[2].vertWorldPos = QVector2D(m.map(v[2].pos.toPointF()));
        v[3].vertWorldPos = QVector2D(m.map(v[3].pos.toPointF()));
    }
};

void LightGroup::sync()
{
    if (!m_dirty)
        return;

    unsigned i = 0;
    m_syncedLightWorldPositions = { };
    m_syncedLightIntensities = { };
    for (auto &item : m_sourceItems) {
        if (i >= m_syncedLightWorldPositions.size())
            break;
        if (item->property("lightIntensity").toFloat() <= 0)
            continue;
        m_syncedLightWorldPositions[i] = QVector2D(item->mapToScene(item->boundingRect().center()));
        m_syncedLightIntensities[i] = item->property("lightIntensity").toFloat();
        ++i;
    }
    m_dirty = false;
}

LightedImageItem::LightedImageItem()
{
    setFlag(ItemHasContents);
}

QSGNode *LightedImageItem::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *)
{
    auto node = static_cast<LightedImageNode *>(oldNode);
    if (!node) {
        node = new LightedImageNode;
        auto material = LightedImageMaterialShader::createMaterial();
        // FIXME: Check for changed and move lower.
        material->state()->sourceImage = createAndCacheTexture(window(), m_sourceImage);
        material->state()->normalsImage = createAndCacheTexture(window(), m_normalsImage);
        if (material->state()->sourceImage->hasAlphaChannel())
            material->setFlag(QSGMaterial::Blending);
        node->setFlag(QSGNode::OwnsMaterial);
        node->setMaterial(material);
    }

    auto material = static_cast<QSGSimpleMaterial<LightedImageMaterialState>*>(node->material());
    material->state()->lightWorldPositions = m_lightSources->lightWorldPositions();
    material->state()->lightIntensities = m_lightSources->lightIntensities();
    m_lightSources->sync();

    updateGeometry(node->geometry(), boundingRect(), QRectF{ 0, 0, m_hRepeat, m_vRepeat });
    node->markDirty(QSGNode::DirtyGeometry);
    node->markDirty(QSGNode::DirtyMaterial);

    return node;
}
