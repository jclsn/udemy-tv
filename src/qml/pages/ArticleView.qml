// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

import io.github.udemytv

// A text lecture, on white like udemy.com, scrolled with ▲ and ▼
FocusScope {
    id: root

    required property CourseSession session
    required property int row
    required property var lecture

    property bool hasNext: false

    signal nextRequested()

    readonly property var item: session.item(row)
    readonly property real step: Kirigami.Units.gridUnit * 8

    function scrollBy(delta: real): void {
        const end = flickable.contentHeight - flickable.height;
        scroll.to = Math.max(0, Math.min(end, flickable.contentY + delta));
        scroll.restart();
    }

    Rectangle {
        anchors.fill: parent
        color: Style.background
    }

    Flickable {
        id: flickable

        anchors.fill: parent
        contentHeight: column.implicitHeight + Kirigami.Units.gridUnit * 8
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        NumberAnimation {
            id: scroll
            target: flickable
            property: "contentY"
            duration: Kirigami.Units.longDuration
            easing.type: Easing.OutCubic
        }

        ColumnLayout {
            id: column

            width: Math.min(parent.width - Kirigami.Units.gridUnit * 8,
                            Kirigami.Units.gridUnit * 55)
            x: (parent.width - width) / 2
            y: Kirigami.Units.gridUnit * 4
            spacing: Kirigami.Units.gridUnit * 1.5

            Text {
                Layout.fillWidth: true
                text: root.session.course.title ?? ""
                color: Style.subtleText
                font.pixelSize: 20
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.item.title ?? ""
                color: Style.text
                wrapMode: Text.Wrap
                font.family: Style.serifFamily
                font.pixelSize: 48
                font.weight: Font.Bold
            }

            Text {
                Layout.fillWidth: true
                text: (root.lecture.body ?? "").length > 0 ? root.lecture.body
                    : (root.lecture.description ?? "")
                textFormat: Text.RichText
                wrapMode: Text.Wrap
                color: Style.text
                linkColor: Style.accent
                font.pixelSize: 26
                lineHeight: 1.3
            }

            PrimaryButton {
                id: doneButton
                Layout.topMargin: Kirigami.Units.gridUnit * 2
                focus: true
                icon.name: root.hasNext ? "go-next" : "checkmark"
                text: root.hasNext ? i18n("Mark as complete and continue")
                    : i18n("Mark as complete")
                onClicked: {
                    root.session.setCompleted(root.row, true);

                    if (root.hasNext) {
                        root.nextRequested();
                    }
                }
            }
        }
    }

    Keys.onUpPressed: scrollBy(-step)
    Keys.onDownPressed: scrollBy(step)
    Keys.onPressed: event => {
        if (event.key === Qt.Key_PageDown) {
            scrollBy(flickable.height * 0.9);
            event.accepted = true;
        } else if (event.key === Qt.Key_PageUp) {
            scrollBy(-flickable.height * 0.9);
            event.accepted = true;
        }
    }
}
