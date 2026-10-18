// SPDX-FileCopyrightText: 2025 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import QtQuick.Effects

import org.kde.kirigami as Kirigami

T.Button {
    id: root

    Kirigami.Theme.colorSet: Kirigami.Theme.Button
    Kirigami.Theme.inherit: false

    implicitWidth: Math.max((text && display !== T.AbstractButton.IconOnly ?
        implicitBackgroundWidth : implicitHeight) + leftInset + rightInset,
        implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    Kirigami.MnemonicData.enabled: enabled && visible
    Kirigami.MnemonicData.controlType: Kirigami.MnemonicData.ActionElement
    Kirigami.MnemonicData.label: display !== T.AbstractButton.IconOnly ? text : ""
    Kirigami.MnemonicData.onActiveChanged: background?.updateItem()

    icon.width: Kirigami.Units.iconSizes.medium
    icon.height: Kirigami.Units.iconSizes.medium

    topPadding: Kirigami.Units.largeSpacing // Units.verticalPadding
    bottomPadding: Kirigami.Units.largeSpacing // Units.verticalPadding
    leftPadding: Units.horizontalPadding
    rightPadding: Units.horizontalPadding

    background: DelegateBackground {
        control: root
        raisedBackground: !root.flat
        translucentHighlight: root.flat
    }

    onPressed: root.forceActiveFocus()
    Keys.onReturnPressed: {
        click();
    }

    contentItem: RowLayout {
        spacing: 0

        Kirigami.Icon {
            Layout.rightMargin: internalTextItem.visible ? Kirigami.Units.gridUnit : 0
            Layout.alignment: Qt.AlignVCenter

            color: root.icon.color
            implicitHeight: (root.icon.name !== "") ? root.icon.height : 0
            implicitWidth: (root.icon.name !== "") ? root.icon.width : 0
            source: root.icon.name
            visible: root.icon.name != ''
        }

        Label {
            id: internalTextItem
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: root.text
            elide: Text.ElideRight
            visible: root.text
        }
    }
}
