// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

// A course as udemy.com shows it: picture, bold title, instructors, then progress for your own
// courses or rating and price in the store. It grows and gets a border when focused, like
// BigscreenUI.MediaCard.
T.ItemDelegate {
    id: root

    required property var course

    // Rating and price instead of progress
    property bool storeMode: false
    property bool enrolled: false

    property real artworkWidth: Kirigami.Units.gridUnit * 16
    property real artworkHeight: Math.round(artworkWidth * 9 / 16)

    // The height under the picture; the same for every card so rows line up
    readonly property real labelsHeight: titleMetrics.lineSpacing * 2
        + detailMetrics.lineSpacing * 2 + Kirigami.Units.largeSpacing * 3

    readonly property real progress: course.progress ?? 0

    implicitWidth: artworkWidth
    implicitHeight: artworkHeight + labelsHeight

    padding: 0
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    text: course.title ?? ""

    Accessible.name: text
    Accessible.description: course.instructors ?? ""

    onPressed: forceActiveFocus()
    Keys.onReturnPressed: click()
    Keys.onEnterPressed: click()

    onActiveFocusChanged: {
        if (!activeFocus) {
            return;
        }

        // Keep the view's current item in step when focus arrives by pointer
        const view = GridView.view ?? ListView.view;

        if (view) {
            const index = view.indexAt(x + width / 2, y + height / 2);

            if (index >= 0) {
                view.currentIndex = index;
            }
        }
    }

    FontMetrics {
        id: titleMetrics
        font.pixelSize: Style.cardTitlePixelSize
        font.weight: Font.Bold
    }

    FontMetrics {
        id: detailMetrics
        font.pixelSize: Style.cardDetailPixelSize
    }

    background: null

    contentItem: Item {
        Kirigami.ShadowedImage {
            id: artwork

            width: root.artworkWidth
            height: root.artworkHeight

            source: root.course.image ?? ""
            radius: BigscreenUI.Units.cardCornerRadius
            color: Style.surface
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: width * Screen.devicePixelRatio
            sourceSize.height: height * Screen.devicePixelRatio

            border.width: root.activeFocus ? BigscreenUI.Units.focusBorderWidth : 1
            border.color: root.activeFocus ? Style.accent : Style.border

            shadow.size: root.activeFocus ? Kirigami.Units.gridUnit * 1.5 : 0
            shadow.yOffset: root.activeFocus ? Kirigami.Units.smallSpacing * 2 : 0
            shadow.color: Qt.rgba(0, 0, 0, 0.35)

            scale: root.activeFocus ? BigscreenUI.Units.focusScale : 1.0
            Behavior on scale {
                NumberAnimation {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.OutCubic
                }
            }

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.huge
                height: width
                visible: artwork.status !== Image.Ready
                source: "applications-education"
                opacity: 0.4
            }

            // Udemy shows a play button over the picture of a course you take
            Rectangle {
                anchors.centerIn: parent
                width: Kirigami.Units.gridUnit * 3.5
                height: width
                radius: width / 2
                color: Qt.alpha("black", 0.6)
                visible: root.activeFocus && !root.storeMode
                border.width: 2
                border.color: "white"

                Kirigami.Icon {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 2
                    width: Kirigami.Units.iconSizes.medium
                    height: width
                    source: "media-playback-start"
                    color: "white"
                    isMask: true
                }
            }
        }

        ColumnLayout {
            id: labels

            // Move down with the picture as it grows on focus
            property real focusOffset: root.activeFocus ? Kirigami.Units.smallSpacing * 3 : 0
            Behavior on focusOffset {
                NumberAnimation {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.OutCubic
                }
            }

            y: artwork.height + Kirigami.Units.largeSpacing + focusOffset
            width: artwork.width
            spacing: Kirigami.Units.smallSpacing

            Text {
                Layout.fillWidth: true
                text: root.text
                color: Style.text
                font.pixelSize: Style.cardTitlePixelSize
                font.weight: Font.Bold
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.course.instructors ?? ""
                visible: text.length > 0
                color: Style.subtleText
                font.pixelSize: Style.cardDetailPixelSize
                elide: Text.ElideRight
            }

            // Your course: progress
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                implicitHeight: 4
                visible: !root.storeMode && root.progress > 0
                color: Style.border

                Rectangle {
                    width: parent.width * root.progress
                    height: parent.height
                    color: Style.purple
                }
            }

            Text {
                Layout.fillWidth: true
                visible: !root.storeMode
                text: root.progress >= 1 ? i18n("Completed")
                    : root.progress > 0 ? i18n("%1% complete", Math.round(root.progress * 100))
                    : i18n("START COURSE")
                color: root.progress > 0 ? Style.subtleText : Style.text
                font.pixelSize: Style.cardDetailPixelSize
                font.weight: root.progress > 0 ? Font.Normal : Font.Bold
            }

            // Store: rating and price
            StarRating {
                visible: root.storeMode && rating > 0
                rating: root.course.rating ?? 0
                reviews: root.course.numReviews ?? 0
            }

            RowLayout {
                visible: root.storeMode
                spacing: Kirigami.Units.largeSpacing

                Text {
                    text: root.enrolled ? i18n("Purchased") : (root.course.price ?? "")
                    color: Style.text
                    font.pixelSize: Style.cardTitlePixelSize
                    font.weight: Font.Bold
                }
            }
        }
    }
}
