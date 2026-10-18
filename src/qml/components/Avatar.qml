// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick

import org.kde.kirigami as Kirigami

// The round initials badge Udemy shows for the signed-in user
Rectangle {
    id: root

    property var user: ({})

    readonly property string initials: {
        if (user.initials) {
            return user.initials;
        }

        const name = user.display_name ?? user.title ?? "";

        return name.split(/\s+/)
            .filter(part => part.length > 0)
            .slice(0, 2)
            .map(part => part[0].toUpperCase())
            .join("");
    }

    implicitWidth: Kirigami.Units.gridUnit * 2.5
    implicitHeight: implicitWidth
    radius: width / 2
    color: Style.text
    visible: initials.length > 0

    Text {
        anchors.centerIn: parent
        text: root.initials
        color: "white"
        font.pixelSize: Math.round(root.height * 0.38)
        font.weight: Font.Bold
    }
}
