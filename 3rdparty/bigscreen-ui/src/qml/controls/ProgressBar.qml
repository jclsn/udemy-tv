// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami

/*!
   \brief A progress bar.
 */
T.ProgressBar {
    id: root

    readonly property color separatorColor: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor,
        Kirigami.ColorUtils.brightnessForColor(Kirigami.Theme.backgroundColor) === Kirigami.ColorUtils.Light ? 0.3 : 0.15)

    readonly property int grooveHeight: {
        let h = Math.floor(fontMetrics.height / 3);
        return h + h % 2;
    }

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    Kirigami.Theme.colorSet: Kirigami.Theme.Button
    Kirigami.Theme.inherit: false

    FontMetrics {
        id: fontMetrics
        font: root.font
    }

    background: Rectangle {
        implicitWidth: Kirigami.Units.gridUnit * 10
        implicitHeight: root.grooveHeight
        radius: root.grooveHeight / 2
        color: Kirigami.Theme.backgroundColor
        border.width: 1
        border.color: root.separatorColor
        border.pixelAligned: false
    }

    contentItem: Item {
        implicitWidth: Kirigami.Units.gridUnit * 10
        implicitHeight: root.grooveHeight

        Rectangle {
            visible: width > 0
            width: root.visualPosition * parent.width
            height: parent.height
            radius: root.grooveHeight / 2
            color: Kirigami.Theme.alternateBackgroundColor
            border.width: 1
            border.color: Kirigami.Theme.focusColor
            border.pixelAligned: false
        }
    }
}
