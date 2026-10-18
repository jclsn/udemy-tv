// SPDX-FileCopyrightText: 2025 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import org.kde.kirigami as Kirigami

Item {
    id: root
    property var control

    // Whether the background is visually raised.
    property bool raisedBackground: true

    // The corner radius of the background.
    property int radius: Kirigami.Units.cornerRadius

    // Whether the background is highlighted. By default, this is when the control is focused.
    property bool highlighted: control && ("activeFocus" in control) && control.activeFocus

    // Whether just the border is highlighted. By default, this is the same as highlighted.
    property bool borderHighlighted: highlighted

    // Whether the background highlight color should be translucent.
    property bool translucentHighlight: false

    // Whether to use the theme's alternate background color for differentiation. Only applicable when raisedBackground = true.
    property bool alternateBackgroundColor: false

    // The width of the border when it is highlighted.
    property int borderHighlightWidth: 2

    // Whether the background is shown as selected. By default, this is when the control is checked.
    property bool checked: control && ("checked" in control) && control.checked

    Rectangle {
        id: frame
        anchors.fill: parent

        readonly property bool isLightTheme: Kirigami.Theme.backgroundColor.hslLightness > 0.5

        readonly property bool hovered: control && ("hovered" in control) && control.hovered

        readonly property color backgroundNeutralColor: {
            const color = alternateBackgroundColor ? Kirigami.Theme.alternateBackgroundColor : Kirigami.Theme.backgroundColor;
            return root.checked ? Kirigami.ColorUtils.tintWithAlpha(color, Kirigami.Theme.highlightColor, 0.4) : color;
        }
        readonly property color backgroundHighlightColor: {
            (root.translucentHighlight)
                ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2)
                : Kirigami.Theme.activeBackgroundColor
        }

        // Neutral borders in dark theme tend to look gross, disabling by default
        readonly property color borderNeutralColor: isLightTheme ? Qt.darker(backgroundNeutralColor, 1.2) : 'transparent'
        readonly property color borderHighlightColor: {
            if (root.translucentHighlight) {
                return Kirigami.Theme.highlightColor
            }

            Qt.hsva(
                backgroundHighlightColor.hsvHue,
                Kirigami.Theme.highlightColor.hsvSaturation,
                Kirigami.Theme.highlightColor.hsvValue,
                1.0
            )
        }

        readonly property int borderNeutralWidth: (isLightTheme ? 1 : 0)

        border.width: borderHighlighted ? root.borderHighlightWidth : borderNeutralWidth
        border.color: {
            (root.borderHighlighted)
                ? borderHighlightColor
            : (raisedBackground ? borderNeutralColor : 'transparent')
        }

        color: {
            (highlighted || hovered)
                ? backgroundHighlightColor
            : (raisedBackground ? backgroundNeutralColor : 'transparent')
        }

        radius: root.radius
    }

    MultiEffect {
        id: frameShadow
        visible: root.raisedBackground

        anchors.fill: frame
        source: frame
        blurMax: 16
        shadowEnabled: true
        shadowOpacity: 0.6
        shadowColor: Qt.darker(frame.color, 1.7)
    }
}
