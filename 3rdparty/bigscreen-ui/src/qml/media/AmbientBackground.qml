// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Effects

import org.kde.kirigami as Kirigami

/*!
   \brief A background of soft colored light, for pages without images to put in the background.

   The light is tinted with \l tint and two hues either side of it. The page darkens
   towards the bottom, so text over it stays readable.

   \code
   BigscreenUI.Page {
       background: BigscreenUI.AmbientBackground {}
   }
   \endcode
 */
Item {
    id: root

    /*!
       \brief The color under the light.
       \default Kirigami.Theme.backgroundColor
     */
    property color color: Kirigami.Theme.backgroundColor

    /*!
       \brief The color the light is based on.
       \default Kirigami.Theme.highlightColor
     */
    property color tint: Kirigami.Theme.highlightColor

    /*!
       \brief How strong the light is, from 0 to 1.
       \default 0.45
     */
    property real intensity: 0.45

    readonly property real __hue: tint.hslHue < 0 ? 0.58 : tint.hslHue

    Rectangle {
        anchors.fill: parent
        color: root.color
    }

    Item {
        anchors.fill: parent
        opacity: root.intensity

        Glow {
            color: root.tint
            size: root.height * 0.9
            centerX: root.width * 0.75
            centerY: root.height * 0.1
        }
        Glow {
            color: Qt.hsla((root.__hue + 0.92) % 1, 0.6, 0.55, 1)
            size: root.height * 0.8
            centerX: root.width * 0.15
            centerY: root.height * 0.85
        }
        Glow {
            color: Qt.hsla((root.__hue + 0.12) % 1, 0.6, 0.55, 1)
            size: root.height * 0.6
            centerX: root.width * 0.95
            centerY: root.height * 0.9
        }
    }

    // Keeps text over the light readable, most of all at the bottom
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.alpha(root.color, 0.2) }
            GradientStop { position: 1; color: Qt.alpha(root.color, 0.85) }
        }
    }

    // Soft circle of light
    component Glow: Item {
        id: glow

        property color color
        property real size
        property real centerX
        property real centerY

        // Small circle blurred and scaled up for performance
        readonly property real sourceSize: 128

        width: sourceSize
        height: sourceSize
        scale: size / sourceSize
        x: centerX - width / 2
        y: centerY - height / 2

        Rectangle {
            id: circle
            anchors.fill: parent
            radius: width / 2
            color: glow.color
            visible: false
            layer.enabled: true
        }

        MultiEffect {
            anchors.fill: parent
            source: circle
            blurEnabled: true
            blur: 1.0
            blurMax: 48
            autoPaddingEnabled: true
        }
    }
}
