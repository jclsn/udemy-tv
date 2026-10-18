// SPDX-FileCopyrightText: 2025 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import QtQuick.Effects

import org.kde.kirigami as Kirigami

T.Dialog {
    id: root

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentWidth + leftPadding + rightPadding,
                            implicitHeaderWidth,
                            implicitFooterWidth)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding
                             + (implicitHeaderHeight > 0 ? implicitHeaderHeight + spacing : 0)
                             + (implicitFooterHeight > 0 ? implicitFooterHeight + spacing : 0))

    /*!
       \brief This property holds item to focus when the dialog opens.
       \default footer
     */
    property var openFocusItem: footer

    modal: true

    topPadding: Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing
    bottomPadding: Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing
    leftPadding: Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing
    rightPadding: Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing

    width: Math.min(parent.width * 0.7, Math.max(parent.width * 0.4, Kirigami.Units.gridUnit * 35))
    parent: T.Overlay.overlay
    anchors.centerIn: parent

    standardButtons: T.Dialog.NoButton

    onOpened: openFocusItem.forceActiveFocus()
    onRejected: root.close()
    BackHandler.enabled: root.visible
    BackHandler.onActivated: root.reject()

    background: PopupBackground {}

    T.Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.4)
        Behavior on opacity {
            OpacityAnimator {
                duration: Kirigami.Units.longDuration
            }
        }
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
        NumberAnimation { property: "scale"; from: 0.95; to: 1; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
    }

    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Kirigami.Units.shortDuration; easing.type: Easing.InCubic }
    }

    header: T.Control {
        implicitWidth: implicitContentWidth + leftPadding + rightPadding
        implicitHeight: implicitContentHeight + topPadding + bottomPadding
        visible: contentItem.text.length > 0
        topPadding: Kirigami.Units.gridUnit
        bottomPadding: Kirigami.Units.gridUnit
        leftPadding: Kirigami.Units.gridUnit
        rightPadding: Kirigami.Units.gridUnit

        contentItem: Label {
            text: root.title
            type: Label.Section
            wrapMode: Text.Wrap
        }
    }

    footer: DialogButtonBox {
        dialog: root

        // Up from the buttons goes back to the content, to the item before them in the focus chain
        Keys.onUpPressed: event => {
            const item = itemAt(0)?.nextItemInFocusChain(false);
            for (let parent = item; parent; parent = parent.parent) {
                if (parent === root.contentItem) {
                    item.forceActiveFocus(Qt.BacktabFocusReason);
                    return;
                }
            }
            event.accepted = false;
        }
    }
}
