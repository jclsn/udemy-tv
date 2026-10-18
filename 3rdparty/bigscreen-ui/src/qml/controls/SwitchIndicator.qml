// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick

import org.kde.kirigami as Kirigami

/*!
   \brief The track and handle of a switch.
 */
Item {
    id: root

    /*!
       \brief Whether the switch is on.
     */
    property bool checked: false

    /*!
       \brief Whether the handle is highlighted, for example while its control has focus.
     */
    property bool highlighted: false

    // A border that separates the switch from what is behind it, as in Breeze
    readonly property color separatorColor: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor,
        Kirigami.ColorUtils.brightnessForColor(Kirigami.Theme.backgroundColor) === Kirigami.ColorUtils.Light ? 0.3 : 0.15)

    implicitWidth: implicitHeight * 2
    implicitHeight: Math.round(Kirigami.Units.gridUnit * 1.4)

    opacity: enabled ? 1 : 0.5

    Kirigami.Theme.colorSet: Kirigami.Theme.Button
    Kirigami.Theme.inherit: false

    Rectangle {
        id: track
        anchors.fill: parent
        anchors.margins: Math.floor(parent.height / 6)
        radius: height / 2
        color: Kirigami.Theme.backgroundColor
        border.width: 1
        border.color: root.separatorColor
    }

    // The part of the track up to the handle, tinted while the switch is on
    Rectangle {
        anchors.left: track.left
        anchors.right: handle.horizontalCenter
        anchors.top: track.top
        anchors.bottom: track.bottom
        visible: width > handle.width / 2
        radius: height / 2
        color: Kirigami.Theme.alternateBackgroundColor
        border.width: 1
        border.color: Kirigami.Theme.focusColor
    }

    Rectangle {
        id: handle
        x: root.checked ? root.width - width : 0
        width: height
        height: parent.height
        radius: height / 2
        color: Kirigami.Theme.backgroundColor
        border.width: 1
        border.color: root.highlighted ? Kirigami.Theme.focusColor : root.separatorColor

        Behavior on x {
            NumberAnimation {
                duration: Kirigami.Units.shortDuration
                easing.type: Easing.InOutCubic
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: Kirigami.Units.shortDuration
            }
        }

        // A small shadow under the handle
        Rectangle {
            z: -1
            y: 1
            width: parent.width
            height: parent.height
            radius: parent.radius
            color: Qt.rgba(0, 0, 0, 0.1)
        }
    }
}
