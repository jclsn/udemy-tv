// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

// The tabs under "My learning" on udemy.com: bold white text, underlined when selected
FocusScope {
    id: root

    property list<string> tabs
    property int currentIndex: 0

    signal activated(int index)

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    onActiveFocusChanged: {
        if (activeFocus) {
            repeater.itemAt(currentIndex)?.forceActiveFocus();
        }
    }

    Row {
        id: row
        spacing: Kirigami.Units.gridUnit * 2

        BigscreenUI.KeyNavigationGroup.orientation: Qt.Horizontal

        Repeater {
            id: repeater
            model: root.tabs

            delegate: T.AbstractButton {
                id: tab

                required property int index
                required property string modelData

                readonly property bool selected: index === root.currentIndex

                implicitWidth: label.implicitWidth + leftPadding + rightPadding
                implicitHeight: label.implicitHeight + topPadding + bottomPadding
                leftPadding: Kirigami.Units.largeSpacing
                rightPadding: Kirigami.Units.largeSpacing
                topPadding: Kirigami.Units.largeSpacing
                bottomPadding: Kirigami.Units.largeSpacing * 2

                focusPolicy: Qt.StrongFocus
                text: modelData
                Accessible.role: Accessible.PageTab

                onPressed: forceActiveFocus()
                onClicked: {
                    root.currentIndex = index;
                    root.activated(index);
                }

                Keys.onReturnPressed: click()
                Keys.onEnterPressed: click()
                // Moving onto a tab opens it, as with the navigation bar
                onActiveFocusChanged: {
                    if (activeFocus && !selected) {
                        click();
                    }
                }

                contentItem: Text {
                    id: label
                    text: tab.text
                    color: "white"
                    opacity: tab.selected || tab.activeFocus ? 1 : 0.75
                    font.pixelSize: 21
                    font.weight: Font.Bold
                }

                background: Item {
                    Rectangle {
                        anchors.fill: parent
                        anchors.bottomMargin: Kirigami.Units.smallSpacing
                        radius: Kirigami.Units.cornerRadius
                        color: Qt.alpha("white", 0.12)
                        border.width: 2
                        border.color: Style.purpleLight
                        visible: tab.activeFocus
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: tab.leftPadding
                        anchors.rightMargin: tab.rightPadding
                        height: 4
                        color: "white"
                        visible: tab.selected
                    }
                }
            }
        }
    }
}
