/*
    SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

#pragma once

#include <QObject>
#include <QPointer>
#include <QQmlEngine>
#include <qqmlregistration.h>

class QQuickItem;

/*!
   \brief Attached property to make a row/column of controls arrow-navigable.

   Attach it to a row or column of controls, and the arrow keys along its orientation move
   focus to the previous or next control, in the order of the focus chain. Controls that are
   hidden or disabled are skipped.

   \code
   RowLayout {
       BigscreenUI.KeyNavigationGroup.orientation: Qt.Horizontal

       BigscreenUI.Button { text: i18n("Play") }
       BigscreenUI.Button { text: i18n("Shuffle"); visible: canShuffle }
       BigscreenUI.Button { text: i18n("Go to artist") }
   }
   \endcode
 */
class KeyNavigationGroup : public QObject
{
    Q_OBJECT

    /*!
       \brief The direction the controls are laid out in (for arrow key navigation).
     */
    Q_PROPERTY(Qt::Orientations orientation READ orientation WRITE setOrientation NOTIFY orientationChanged FINAL)

    /*!
       \brief Whether the arrow keys move focus in the group.
     */
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged FINAL)

    QML_ELEMENT
    QML_UNCREATABLE("Attached property only")
    QML_ATTACHED(KeyNavigationGroup)

public:
    explicit KeyNavigationGroup(QObject *target);
    ~KeyNavigationGroup() override;

    Qt::Orientations orientation() const;
    void setOrientation(Qt::Orientations orientation);

    bool enabled() const;
    void setEnabled(bool enabled);

    static KeyNavigationGroup *qmlAttachedProperties(QObject *object);

Q_SIGNALS:
    void orientationChanged();
    void enabledChanged();

protected:
    bool eventFilter(QObject *watched, QEvent *event) override;

private:
    QPointer<QQuickItem> m_target;
    Qt::Orientations m_orientation = Qt::Horizontal;
    bool m_enabled = true;
};

QML_DECLARE_TYPEINFO(KeyNavigationGroup, QML_HAS_ATTACHED_PROPERTIES)
