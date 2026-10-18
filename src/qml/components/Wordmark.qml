// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

// The app's name, set like udemy.com's header. Not Udemy's logo: this app is unofficial.
RowLayout {
    id: root

    property int pixelSize: 30
    property color color: Style.text

    spacing: Kirigami.Units.smallSpacing * 2

    Text {
        text: "Udemy"
        color: root.color
        font.pixelSize: root.pixelSize
        font.weight: Font.Black
        font.letterSpacing: -0.5
    }

    Rectangle {
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: tv.implicitWidth + Kirigami.Units.smallSpacing * 3
        implicitHeight: tv.implicitHeight + Kirigami.Units.smallSpacing
        radius: Kirigami.Units.cornerRadius
        color: Style.purple

        Text {
            id: tv
            anchors.centerIn: parent
            text: "TV"
            color: "white"
            font.pixelSize: Math.round(root.pixelSize * 0.5)
            font.weight: Font.Bold
        }
    }
}
