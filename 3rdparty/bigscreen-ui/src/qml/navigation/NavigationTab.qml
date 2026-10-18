// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami

/*!
   \brief A tab in a NavigationBar.
 */
T.AbstractButton {
    id: root

    /*!
       \brief Whether this is the selected tab.
     */
    property bool selected: false

    readonly property bool iconOnly: action instanceof Kirigami.Action && (action.displayHint & Kirigami.DisplayHint.IconOnly)

    implicitWidth: iconOnly ? implicitHeight : contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: Kirigami.Units.gridUnit * 3

    leftPadding: Kirigami.Units.gridUnit
    rightPadding: Kirigami.Units.gridUnit

    focusPolicy: Qt.StrongFocus
    hoverEnabled: true

    Accessible.role: Accessible.PageTab
    Accessible.name: text

    onPressed: root.forceActiveFocus()
    Keys.onReturnPressed: click()
    Keys.onEnterPressed: click()

    background: DelegateBackground {
        control: root
        raisedBackground: false

        // Underline for selected item
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: root.iconOnly ? Kirigami.Units.largeSpacing * 2 : root.leftPadding - Kirigami.Units.smallSpacing
            anchors.rightMargin: anchors.leftMargin
            anchors.bottomMargin: Kirigami.Units.smallSpacing + 2
            height: 3
            radius: height / 2
            color: Kirigami.Theme.highlightColor
            visible: root.selected
        }
    }

    contentItem: Item {
        implicitWidth: root.iconOnly ? icon.implicitWidth : label.implicitWidth
        implicitHeight: Math.max(icon.implicitHeight, label.implicitHeight)

        Kirigami.Icon {
            id: icon
            anchors.centerIn: parent
            visible: root.iconOnly
            implicitWidth: Kirigami.Units.iconSizes.smallMedium
            implicitHeight: Kirigami.Units.iconSizes.smallMedium
            source: root.icon.name
        }

        Label {
            id: label
            anchors.centerIn: parent
            visible: !root.iconOnly
            text: root.text
            type: Label.Heading
            color: (root.selected || root.activeFocus) ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
            Accessible.ignored: true
        }
    }
}
