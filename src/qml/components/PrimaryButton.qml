// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami

// Udemy's buttons: filled purple, or outlined for secondary actions
T.Button {
    id: root

    // Outlined instead of filled
    property bool secondary: false

    // For buttons on Udemy's dark bands
    property bool onDark: false

    readonly property color outlineColor: onDark ? "white" : Style.text

    implicitWidth: Math.max(implicitBackgroundWidth,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight,
                             implicitContentHeight + topPadding + bottomPadding)

    leftPadding: Kirigami.Units.gridUnit * 1.5
    rightPadding: Kirigami.Units.gridUnit * 1.5
    topPadding: Kirigami.Units.gridUnit * 0.9
    bottomPadding: Kirigami.Units.gridUnit * 0.9

    icon.width: Kirigami.Units.iconSizes.smallMedium
    icon.height: Kirigami.Units.iconSizes.smallMedium

    focusPolicy: Qt.StrongFocus
    hoverEnabled: true

    onPressed: forceActiveFocus()
    Keys.onReturnPressed: click()
    Keys.onEnterPressed: click()

    scale: activeFocus ? 1.04 : 1
    Behavior on scale {
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.OutCubic
        }
    }

    background: Item {
        implicitWidth: Kirigami.Units.gridUnit * 8
        implicitHeight: Kirigami.Units.gridUnit * 2.75

        Rectangle {
            anchors.fill: parent
            radius: Kirigami.Units.cornerRadius * 2
            color: {
                if (root.secondary) {
                    return root.activeFocus || root.hovered ? Qt.alpha(root.outlineColor, 0.12)
                                                             : "transparent";
                }

                return root.activeFocus || root.down ? Style.purpleDark : Style.purple;
            }

            border.width: root.secondary ? 1 : 0
            border.color: root.outlineColor
        }

        // A ring around the focused button, clear of its edge, so it reads from across the room
        Rectangle {
            anchors.fill: parent
            anchors.margins: -5
            radius: Kirigami.Units.cornerRadius * 2 + 5
            color: "transparent"
            border.width: 3
            border.color: root.onDark ? Style.purpleLight : Style.accent
            visible: root.activeFocus
        }
    }

    contentItem: RowLayout {
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Icon {
            Layout.alignment: Qt.AlignVCenter
            visible: root.icon.name.length > 0
            source: root.icon.name
            implicitWidth: root.icon.width
            implicitHeight: root.icon.height
            color: label.color
            isMask: true
        }

        Text {
            id: label
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: root.text
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 19
            font.weight: Font.Bold
            color: root.secondary ? root.outlineColor : "white"
        }
    }
}
