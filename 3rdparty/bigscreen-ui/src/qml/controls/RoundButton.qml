// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami

/*!
   \brief A circular icon-only button.
 */
T.Button {
    id: root

    Kirigami.Theme.colorSet: Kirigami.Theme.Button
    Kirigami.Theme.inherit: false

    implicitWidth: implicitHeight
    implicitHeight: implicitContentHeight + topPadding + bottomPadding

    // The space around the icon; without it the icon fills the whole circle
    padding: Kirigami.Units.gridUnit

    icon.width: Kirigami.Units.iconSizes.medium
    icon.height: Kirigami.Units.iconSizes.medium

    display: T.AbstractButton.IconOnly
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true

    background: DelegateBackground {
        control: root
        radius: height / 2
        borderHighlightWidth: 3
    }

    onPressed: root.forceActiveFocus()
    Keys.onReturnPressed: click()
    Keys.onEnterPressed: click()

    contentItem: Kirigami.Icon {
        implicitWidth: root.icon.width
        implicitHeight: root.icon.height
        source: root.icon.name !== "" ? root.icon.name : root.icon.source
        color: root.icon.color
    }
}
