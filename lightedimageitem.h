#ifndef LIGHTEDIMAGEITEM_H
#define LIGHTEDIMAGEITEM_H

#include <QQmlListProperty>
#include <QQuickItem>
#include <QVector3D>
#include <array>

class LightGroup : public QObject {
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<QQuickItem> sources READ sourceItems FINAL)
public:
    QQmlListProperty<QQuickItem> sourceItems() {
        return QQmlListProperty<QQuickItem>(this, &m_sourceItems, sourceAppend, sourceCount, sourceAt, sourceClear);
    }

    typedef std::array<QVector2D, 5> LightPosArray;
    typedef std::array<float, 5> LightIntensityArray;
    LightPosArray *lightWorldPositions() { return &m_syncedLightWorldPositions; }
    LightIntensityArray *lightIntensities() { return &m_syncedLightIntensities; }
    void sync();

signals:
    void someLightMoved();

private slots:
    void needsUpdate() {
        m_dirty = true;
        emit someLightMoved();
    }

private:
    static void sourceAppend(QQmlListProperty<QQuickItem> *p, QQuickItem *v) {
        QObject::connect(v, SIGNAL(xChanged()), p->object, SLOT(needsUpdate()));
        QObject::connect(v, SIGNAL(yChanged()), p->object, SLOT(needsUpdate()));
        reinterpret_cast<QList<QQuickItem *> *>(p->data)->append(v);
    }
    static int sourceCount(QQmlListProperty<QQuickItem> *p) {
        return reinterpret_cast<QList<QQuickItem *> *>(p->data)->count();
    }
    static QQuickItem *sourceAt(QQmlListProperty<QQuickItem> *p, int idx) {
        return reinterpret_cast<QList<QQuickItem *> *>(p->data)->at(idx);
    }
    static void sourceClear(QQmlListProperty<QQuickItem> *p) {
        auto list = reinterpret_cast<QList<QQuickItem *> *>(p->data);
        for (auto i : *list)
            i->disconnect(p->object);
        auto o = static_cast<LightGroup*>(p->object);
        o->m_dirty = true;
        emit o->someLightMoved();
        return list->clear();
    }
    bool m_dirty = true;
    QList<QQuickItem *> m_sourceItems;
    LightPosArray m_syncedLightWorldPositions;
    LightIntensityArray m_syncedLightIntensities;
};

class LightedImageItem : public QQuickItem {
    Q_OBJECT
    Q_PROPERTY(LightGroup *lightSources READ lightSources WRITE setLightSources NOTIFY lightSourcesChanged FINAL)
    Q_PROPERTY(QUrl sourceImage READ sourceImage WRITE setSourceImage NOTIFY sourceImageChanged FINAL)
    Q_PROPERTY(QUrl normalsImage READ normalsImage WRITE setNormalsImage NOTIFY normalsImageChanged FINAL)
    Q_PROPERTY(float hRepeat READ hRepeat WRITE setHRepeat NOTIFY hRepeatChanged FINAL)
    Q_PROPERTY(float vRepeat READ vRepeat WRITE setVRepeat NOTIFY vRepeatChanged FINAL)
public:
    LightedImageItem();
    QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) override;

    LightGroup *lightSources() const { return m_lightSources; }
    void setLightSources(LightGroup *value) {
        if (m_lightSources != value) {
            if (m_lightSources)
                m_lightSources->disconnect(this);
            m_lightSources = value;
            if (m_lightSources)
                connect(m_lightSources, SIGNAL(someLightMoved()), SLOT(update()));
            emit lightSourcesChanged();
            update();
        }
    }
    QUrl sourceImage() const { return m_sourceImage; }
    void setSourceImage(QUrl value) {
        if (m_sourceImage != value) {
            m_sourceImage = value;
            emit sourceImageChanged();
            update();
        }
    }
    QUrl normalsImage() const { return m_normalsImage; }
    void setNormalsImage(QUrl value) {
        if (m_normalsImage != value) {
            m_normalsImage = value;
            emit normalsImageChanged();
            update();
        }
    }
    float hRepeat() const { return m_hRepeat; }
    void setHRepeat(float value) {
        if (m_hRepeat != value) {
            m_hRepeat = value;
            emit hRepeatChanged();
            update();
        }
    }
    float vRepeat() const { return m_vRepeat; }
    void setVRepeat(float value) {
        if (m_vRepeat != value) {
            m_vRepeat = value;
            emit vRepeatChanged();
            update();
        }
    }

signals:
    void lightSourcesChanged();
    void sourceImageChanged();
    void normalsImageChanged();
    void hRepeatChanged();
    void vRepeatChanged();

private:
    LightGroup *m_lightSources = nullptr;
    QUrl m_sourceImage;
    QUrl m_normalsImage;
    float m_hRepeat = 1;
    float m_vRepeat = 1;
};

#endif
