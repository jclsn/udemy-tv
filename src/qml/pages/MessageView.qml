// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

import io.github.udemytv

// A message in place of a lecture, with up to two things to do about it
FocusScope {
    id: root

    property string iconName
    property string text
    property string explanation
    property string primaryText
    property string secondaryText

    signal primaryClicked()
    signal secondaryClicked()

    Rectangle {
        anchors.fill: parent
        color: Style.dark
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.6, Kirigami.Units.gridUnit * 45)
        spacing: Kirigami.Units.gridUnit * 1.5

        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Kirigami.Units.iconSizes.enormous
            implicitHeight: implicitWidth
            source: root.iconName
            color: "white"
            isMask: true
            opacity: 0.7
        }

        Text {
            Layout.fillWidth: true
            text: root.text
            color: "white"
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 36
            font.weight: Font.Bold
        }

        Text {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.explanation
            color: Style.border
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 21
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Kirigami.Units.gridUnit
            spacing: Kirigami.Units.gridUnit

            BigscreenUI.KeyNavigationGroup.orientation: Qt.Horizontal

            PrimaryButton {
                focus: true
                visible: root.primaryText.length > 0
                text: root.primaryText
                onDark: true
                onClicked: root.primaryClicked()
            }

            PrimaryButton {
                visible: root.secondaryText.length > 0
                text: root.secondaryText
                secondary: true
                onDark: true
                onClicked: root.secondaryClicked()
            }
        }
    }
}
