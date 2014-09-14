#ifndef LIGHTEDIMAGEITEM_H
#define LIGHTEDIMAGEITEM_H

#include <QQuickItem>
#include <QQmlListProperty>

class LightedImageItem : public QQuickItem {
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<QQuickItem> lightSources READ lightSourceItems FINAL)
    Q_PROPERTY(QString sourceImage READ sourceImage WRITE setSourceImage NOTIFY sourceImageChanged FINAL)
    Q_PROPERTY(QString normalsImage READ normalsImage WRITE setNormalsImage NOTIFY normalsImageChanged FINAL)
    Q_PROPERTY(float hRepeat READ hRepeat WRITE setHRepeat NOTIFY hRepeatChanged FINAL)
    Q_PROPERTY(float vRepeat READ vRepeat WRITE setVRepeat NOTIFY vRepeatChanged FINAL)
public:
    LightedImageItem();
    QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) override;

    QQmlListProperty<QQuickItem> lightSourceItems() {
        return QQmlListProperty<QQuickItem>(this, m_lightSourceItems);
    }

    QString sourceImage() const { return m_sourceImage; }
    void setSourceImage(QString value) {
        if (m_sourceImage != value) {
            m_sourceImage = value;
            emit sourceImageChanged();
            update();
        }
    }
    QString normalsImage() const { return m_normalsImage; }
    void setNormalsImage(QString value) {
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
    void sourceImageChanged();
    void normalsImageChanged();
    void hRepeatChanged();
    void vRepeatChanged();

private:
    QList<QQuickItem *> m_lightSourceItems;
    QString m_sourceImage;
    QString m_normalsImage;
    float m_hRepeat = 1;
    float m_vRepeat = 1;
};

#endif
