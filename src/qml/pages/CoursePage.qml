// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

import io.github.udemytv

// A course you take: what it is and how far you got on the left, its contents on the right,
// like the sidebar of Udemy's course player
BigscreenUI.Page {
    id: root

    required property var course

    function play(row: int): void {
        const item = session.item(row);

        if (item.itemClass === "lecture") {
            Window.window.openLecture(session, row);
        } else {
            // Quizzes and exercises only exist in Udemy's web player
            Window.window.openWeb(session.webUrl(row), item.title);
        }
    }

    function iconFor(itemClass: string, assetType: string): string {
        if (itemClass === "quiz") {
            return "question";
        }

        if (itemClass !== "lecture") {
            return "document-edit";
        }

        switch (assetType) {
        case "Article":
            return "text-x-generic";
        case "Presentation":
        case "VideoMashup":
            return "view-presentation";
        case "Audio":
            return "audio-x-generic";
        case "E-Book":
        case "File":
            return "document-open";
        default:
            return "video-x-generic";
        }
    }

    function describe(itemClass: string, assetType: string, duration: real): string {
        let kind;

        if (itemClass === "quiz") {
            kind = i18n("Quiz");
        } else if (itemClass === "practice") {
            kind = i18n("Practice");
        } else if (assetType === "Article") {
            kind = i18n("Article");
        } else if (assetType === "VideoMashup") {
            kind = i18n("Slides and video");
        } else if (assetType === "Presentation") {
            kind = i18n("Slides");
        } else {
            kind = i18n("Video");
        }

        const minutes = Math.max(1, Math.round(duration / 60));

        return duration > 0 ? i18n("%1 · %2min", kind, minutes) : kind;
    }

    BigscreenUI.BackHandler.enabled: visible
    BigscreenUI.BackHandler.onActivated: T.StackView.view.pop()

    Component.onCompleted: session.load()

    CourseSession {
        id: session
        course: root.course

        onLoadingChanged: {
            if (!loading && resumeRow >= 0) {
                contents.currentIndex = resumeRow;
                contents.positionViewAtIndex(resumeRow, ListView.Center);
            }
        }
    }

    background: Rectangle {
        color: Style.background
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // The course
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: Math.round(root.width * 0.38)
            color: Style.band

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: root.contentMargins.left
                anchors.rightMargin: Kirigami.Units.gridUnit * 2
                anchors.topMargin: root.contentMargins.top
                anchors.bottomMargin: root.contentMargins.bottom
                spacing: Kirigami.Units.gridUnit

                Kirigami.ShadowedImage {
                    Layout.fillWidth: true
                    Layout.preferredHeight: width * 9 / 16
                    source: root.course.imageLarge ?? root.course.image ?? ""
                    fillMode: Image.PreserveAspectCrop
                    radius: BigscreenUI.Units.cardCornerRadius
                    color: Qt.alpha("white", 0.1)
                    asynchronous: true
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.gridUnit
                    text: root.course.title ?? ""
                    color: "white"
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    font.family: Style.serifFamily
                    font.pixelSize: 36
                    font.weight: Font.Bold
                }

                Text {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: root.course.instructors ?? ""
                    color: Style.purpleLight
                    elide: Text.ElideRight
                    font.pixelSize: 20
                }

                Item {
                    Layout.fillHeight: true
                }

                // Progress, as in the "Your progress" popup
                Text {
                    Layout.fillWidth: true
                    text: session.lectureCount > 0
                        ? i18n("%1 of %2 lectures complete",
                               session.completedCount, session.lectureCount)
                        : " "
                    color: "white"
                    font.pixelSize: 19
                    font.weight: Font.Bold
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 6
                    radius: 3
                    color: Qt.alpha("white", 0.2)

                    Rectangle {
                        width: parent.width * session.progress
                        height: parent.height
                        radius: 3
                        color: Style.purpleLight
                        Behavior on width {
                            NumberAnimation {
                                duration: Kirigami.Units.longDuration
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: session.totalDuration.length > 0
                    text: i18n("%1 in total", session.totalDuration)
                    color: Style.border
                    font.pixelSize: 17
                }

                PrimaryButton {
                    id: continueButton

                    readonly property var resumeItem: session.item(session.resumeRow)

                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.gridUnit
                    focus: true
                    enabled: session.resumeRow >= 0
                    icon.name: "media-playback-start"
                    text: session.loading ? i18n("Loading…")
                        : session.completedCount === 0
                            && session.savedPosition(session.resumeRow) <= 0 ? i18n("Start course")
                        : i18n("Continue: %1", resumeItem.title ?? "")
                    onClicked: root.play(session.resumeRow)
                    KeyNavigation.right: contents
                }

                BigscreenUI.Label {
                    Layout.fillWidth: true
                    visible: session.error.length > 0
                    text: session.error
                    color: Kirigami.Theme.negativeTextColor
                    wrapMode: Text.Wrap
                    type: BigscreenUI.Label.Small
                }
            }
        }

        // The contents
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                Layout.topMargin: root.contentMargins.top
                Layout.bottomMargin: Kirigami.Units.gridUnit
                text: i18n("Course content")
                color: Style.text
                font.pixelSize: 30
                font.weight: Font.Bold
            }

            BigscreenUI.ListView {
                id: contents

                Layout.fillWidth: true
                Layout.fillHeight: true
                leftMargin: Kirigami.Units.gridUnit
                rightMargin: root.contentMargins.right - __focusRoom
                spacing: 0

                model: session.curriculum
                KeyNavigation.left: continueButton

                section.property: "sectionKey"
                section.criteria: ViewSection.FullString
                section.delegate: Rectangle {
                    id: sectionHeader

                    required property string section

                    readonly property int sectionIndex: parseInt(section)

                    width: ListView.view.rowWidth
                    implicitHeight: sectionLayout.implicitHeight + Kirigami.Units.gridUnit * 1.5
                    color: Style.surface
                    border.color: Style.border

                    ColumnLayout {
                        id: sectionLayout
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Kirigami.Units.gridUnit
                        anchors.rightMargin: Kirigami.Units.gridUnit
                        spacing: Kirigami.Units.smallSpacing

                        Text {
                            Layout.fillWidth: true
                            text: session.curriculum.sectionTitle(sectionHeader.sectionIndex)
                            color: Style.text
                            elide: Text.ElideRight
                            font.pixelSize: 20
                            font.weight: Font.Bold
                        }

                        Text {
                            Layout.fillWidth: true
                            // Re-evaluated when completion changes
                            text: session.curriculum.revision >= 0
                                ? session.curriculum.sectionInfo(sectionHeader.sectionIndex) : ""
                            color: Style.subtleText
                            font.pixelSize: 15
                        }
                    }
                }

                delegate: BigscreenUI.ButtonDelegate {
                    id: lectureDelegate

                    required property int index
                    required property int number
                    required property string title
                    required property string itemClass
                    required property string assetType
                    required property real duration
                    required property bool completed

                    width: ListView.view.rowWidth
                    raisedBackground: false
                    // Udemy numbers lectures through the whole course
                    text: itemClass === "lecture" && number > 0
                        ? "%1. %2".arg(number).arg(title) : title
                    description: root.describe(itemClass, assetType, duration)
                    icon.name: root.iconFor(itemClass, assetType)
                    icon.width: Kirigami.Units.iconSizes.smallMedium
                    icon.height: Kirigami.Units.iconSizes.smallMedium

                    leading: Rectangle {
                        implicitWidth: Kirigami.Units.iconSizes.smallMedium
                        implicitHeight: implicitWidth
                        radius: Kirigami.Units.cornerRadius
                        color: lectureDelegate.completed ? Style.purple : "transparent"
                        border.width: 2
                        border.color: lectureDelegate.completed ? Style.purple : Style.subtleText

                        Kirigami.Icon {
                            anchors.fill: parent
                            anchors.margins: 2
                            visible: lectureDelegate.completed
                            source: "checkmark"
                            color: "white"
                            isMask: true
                        }
                    }

                    trailing: BigscreenUI.Badge {
                        visible: lectureDelegate.index === session.resumeRow
                        text: i18n("Up next")
                    }

                    onClicked: root.play(index)

                    // The menu key toggles "completed", as the check box does on udemy.com
                    Keys.onMenuPressed: session.setCompleted(index, !completed)
                }
            }
        }
    }
}
