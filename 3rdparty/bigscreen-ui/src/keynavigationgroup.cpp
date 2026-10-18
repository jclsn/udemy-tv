/*
    SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

#include "keynavigationgroup.h"

#include <QGuiApplication>
#include <QKeyEvent>
#include <QQuickItem>
#include <QQuickWindow>

KeyNavigationGroup::KeyNavigationGroup(QObject *target)
    : QObject(target)
    , m_target(qobject_cast<QQuickItem *>(target))
{
    if (m_target) {
        m_target->installEventFilter(this);
    } else {
        qWarning() << "KeyNavigationGroup must be attached to an Item";
    }
}

KeyNavigationGroup::~KeyNavigationGroup()
{
    if (m_target) {
        m_target->removeEventFilter(this);
    }
}

Qt::Orientations KeyNavigationGroup::orientation() const
{
    return m_orientation;
}

void KeyNavigationGroup::setOrientation(Qt::Orientations orientation)
{
    if (m_orientation == orientation) {
        return;
    }

    m_orientation = orientation;
    Q_EMIT orientationChanged();
}

bool KeyNavigationGroup::enabled() const
{
    return m_enabled;
}

void KeyNavigationGroup::setEnabled(bool enabled)
{
    if (m_enabled == enabled) {
        return;
    }

    m_enabled = enabled;
    Q_EMIT enabledChanged();
}

KeyNavigationGroup *KeyNavigationGroup::qmlAttachedProperties(QObject *object)
{
    return new KeyNavigationGroup(object);
}

bool KeyNavigationGroup::eventFilter(QObject *watched, QEvent *event)
{
    if (!m_enabled || watched != m_target || event->type() != QEvent::KeyPress) {
        return QObject::eventFilter(watched, event);
    }

    auto keyEvent = static_cast<QKeyEvent *>(event);
    if (keyEvent->modifiers() & ~Qt::KeypadModifier) {
        return QObject::eventFilter(watched, event);
    }

    const bool horizontalKeys = m_orientation & Qt::Horizontal;
    const bool verticalKeys = m_orientation & Qt::Vertical;
    const bool mirrored = QGuiApplication::layoutDirection() == Qt::RightToLeft;

    bool forward;
    switch (keyEvent->key()) {
    case Qt::Key_Left:
        if (!horizontalKeys) {
            return QObject::eventFilter(watched, event);
        }
        forward = mirrored;
        break;
    case Qt::Key_Right:
        if (!horizontalKeys) {
            return QObject::eventFilter(watched, event);
        }
        forward = !mirrored;
        break;
    case Qt::Key_Up:
        if (!verticalKeys) {
            return QObject::eventFilter(watched, event);
        }
        forward = false;
        break;
    case Qt::Key_Down:
        if (!verticalKeys) {
            return QObject::eventFilter(watched, event);
        }
        forward = true;
        break;
    default:
        return QObject::eventFilter(watched, event);
    }

    QQuickItem *focused = m_target->window() ? m_target->window()->activeFocusItem() : nullptr;
    if (!focused || (focused != m_target && !m_target->isAncestorOf(focused))) {
        return QObject::eventFilter(watched, event);
    }

    // Get next item, hidden and disabled controls are autoskipped
    QQuickItem *next = focused->nextItemInFocusChain(forward);
    if (!next || next == focused || !m_target->isAncestorOf(next)) {
        return QObject::eventFilter(watched, event);
    }

    // The focus chain wraps around at the end, which can lead back into the
    // group when nothing else can take focus, so only move the way the key points
    const bool vertical = keyEvent->key() == Qt::Key_Up || keyEvent->key() == Qt::Key_Down;
    const QPointF from = focused->mapToItem(m_target, focused->boundingRect().center());
    const QPointF to = next->mapToItem(m_target, next->boundingRect().center());
    const qreal distance = vertical ? to.y() - from.y() : to.x() - from.x();
    const bool pointsForward = vertical || !mirrored ? forward : !forward;
    if (pointsForward ? distance <= 0 : distance >= 0) {
        return QObject::eventFilter(watched, event);
    }

    next->forceActiveFocus(forward ? Qt::TabFocusReason : Qt::BacktabFocusReason);
    event->accept();
    return true;
}

#include "moc_keynavigationgroup.cpp"
