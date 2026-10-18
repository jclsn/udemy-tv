// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami

/*!
   \brief A user-adjustable playback position slider.

   The groove thickens and a handle appears while it has focus.
 */
T.Slider {
    id: root

    readonly property color separatorColor: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor,
        Kirigami.ColorUtils.brightnessForColor(Kirigami.Theme.backgroundColor) === Kirigami.ColorUtils.Light ? 0.3 : 0.15)

    implicitWidth: Kirigami.Units.gridUnit * 20
    implicitHeight: Kirigami.Units.gridUnit * 2

    focusPolicy: Qt.StrongFocus
    hoverEnabled: true

    Kirigami.Theme.colorSet: Kirigami.Theme.Button
    Kirigami.Theme.inherit: false

    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + (root.availableHeight - height) / 2
        width: root.availableWidth
        height: root.activeFocus ? Math.round(Kirigami.Units.gridUnit * 0.7) : Math.round(Kirigami.Units.gridUnit * 0.4)
        radius: height / 2
        color: Kirigami.Theme.backgroundColor
        border.width: 1
        border.color: root.separatorColor

        Behavior on height {
            NumberAnimation {
                duration: Kirigami.Units.shortDuration
            }
        }

        // The played part
        Rectangle {
            width: Math.max(parent.height, root.visualPosition * parent.width)
            height: parent.height
            radius: height / 2
            visible: root.visualPosition > 0
            color: Kirigami.Theme.alternateBackgroundColor
            border.width: 1
            border.color: Kirigami.Theme.focusColor
        }
    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * root.availableWidth - width / 2
        y: root.topPadding + (root.availableHeight - height) / 2
        width: Math.round(Kirigami.Units.gridUnit * 1.4)
        height: width
        radius: width / 2
        color: Kirigami.Theme.backgroundColor
        border.width: 1
        border.color: Kirigami.Theme.focusColor
        scale: (root.activeFocus || root.pressed) ? 1 : 0

        Behavior on scale {
            NumberAnimation {
                duration: Kirigami.Units.shortDuration
                easing.type: Easing.OutCubic
            }
        }

        // Handle shadow
        Rectangle {
            z: -1
            y: 1
            width: parent.width
            height: parent.height
            radius: parent.radius
            color: Qt.rgba(0, 0, 0, 0.1)
        }

        // Breeze focus ring
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: Qt.alpha(Kirigami.Theme.focusColor, 0.42)
            visible: root.visualFocus
        }
    }
}
