// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

// "4.6 ★★★★½ (1,234)", as under Udemy's course titles
RowLayout {
    id: root

    property real rating: 0
    property int reviews: 0
    property int pixelSize: Style.cardDetailPixelSize
    property bool onDark: false

    spacing: Kirigami.Units.smallSpacing
    visible: rating > 0

    Text {
        text: root.rating.toLocaleString(Qt.locale(), "f", 1)
        color: root.onDark ? "#f69c08" : Style.ratingText
        font.pixelSize: root.pixelSize
        font.weight: Font.Bold
    }

    Item {
        implicitWidth: empty.implicitWidth
        implicitHeight: empty.implicitHeight

        Text {
            id: empty
            text: "★★★★★"
            color: root.onDark ? Qt.alpha("white", 0.3) : Style.border
            font.pixelSize: root.pixelSize
        }

        Item {
            width: empty.implicitWidth * Math.max(0, Math.min(1, root.rating / 5))
            height: parent.height
            clip: true

            Text {
                text: "★★★★★"
                color: Style.star
                font.pixelSize: root.pixelSize
            }
        }
    }

    Text {
        visible: root.reviews > 0
        text: "(%1)".arg(root.reviews.toLocaleString(Qt.locale(), "f", 0))
        color: root.onDark ? Style.purpleLight : Style.subtleText
        font.pixelSize: root.pixelSize
    }
}
