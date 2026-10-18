// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami

/*!
   \brief A focusable piece of media artwork.

   The artwork is drawn at \l artworkWidth by \l artworkHeight. The title (\c text) and
   \l subtitle are shown underneath it when set.

   \code
   BigscreenUI.MediaCard {
       artworkWidth: Kirigami.Units.gridUnit * 20
       artworkHeight: artworkWidth * 9 / 16
       source: episode.thumbnail
       placeholderIconName: "video-x-generic"
       text: episode.title
       subtitle: i18n("%1 min left", episode.minutesLeft)
       progress: episode.position / episode.duration
       onClicked: player.play(episode.url)
   }
   \endcode
 */
T.ItemDelegate {
    id: root

    /*!
       \brief The source of the artwork image.
     */
    property alias source: artwork.source

    /*!
       \brief Secondary text shown under the title.
     */
    property string subtitle

    /*!
       \brief How far into the media the user is.
       A progress bar is shown over the artwork if between 0 and 1.
       \default -1
     */
    property real progress: -1

    /*!
       \brief Whether to mark the media as watched.
     */
    property bool watched: false

    /*!
       \brief The width of the artwork.
     */
    property real artworkWidth: Kirigami.Units.gridUnit * 12

    /*!
       \brief The height of the artwork. Defaults to 2:3 poster ratio.
     */
    property real artworkHeight: artworkWidth * 1.5

    /*!
       \brief The name of an icon shown in place of the artwork while it is missing or loading,
       such as a folder or a generic video icon.
     */
    property string placeholderIconName

    /*!
       \qmlproperty ShadowedImage artworkItem
       \brief The item that draws the artwork.
     */
    property alias artworkItem: artwork

    readonly property bool hasLabels: text.length > 0 || subtitle.length > 0

    implicitWidth: artworkWidth
    implicitHeight: artworkHeight + (hasLabels ? labels.implicitHeight + Kirigami.Units.largeSpacing : 0)

    padding: 0
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true

    Accessible.name: subtitle.length > 0 ? text + ", " + subtitle : text

    onPressed: root.forceActiveFocus()
    Keys.onReturnPressed: click()
    Keys.onEnterPressed: click()

    onActiveFocusChanged: {
        if (!activeFocus) {
            return;
        }
        // Keep the view's current item in sync when focus arrives by mouse or touch
        const view = ListView.view ?? GridView.view;
        if (view) {
            const index = view.indexAt(x + width / 2, y + height / 2);
            if (index >= 0) {
                view.currentIndex = index;
            }
        }
    }

    background: null

    contentItem: Item {
        Kirigami.ShadowedImage {
            id: artwork

            width: root.artworkWidth
            height: root.artworkHeight

            radius: Units.cardCornerRadius
            color: Kirigami.Theme.alternateBackgroundColor
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: width * Screen.devicePixelRatio
            sourceSize.height: height * Screen.devicePixelRatio

            border.width: root.activeFocus ? Units.focusBorderWidth : 0
            border.color: Kirigami.Theme.highlightColor

            shadow.size: root.activeFocus ? Kirigami.Units.gridUnit * 1.5 : Kirigami.Units.largeSpacing
            shadow.yOffset: root.activeFocus ? Kirigami.Units.smallSpacing * 2 : Kirigami.Units.smallSpacing
            shadow.color: Qt.rgba(0, 0, 0, 0.5)

            scale: root.activeFocus ? Units.focusScale : 1.0
            Behavior on scale {
                NumberAnimation {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.OutCubic
                }
            }

            // Placeholder icon
            Loader {
                anchors.centerIn: parent
                width: Math.min(Kirigami.Units.iconSizes.enormous, Math.round(Math.min(parent.width, parent.height) * 0.5))
                height: width
                active: root.placeholderIconName.length > 0 && artwork.status !== Image.Ready

                sourceComponent: Kirigami.Icon {
                    source: root.placeholderIconName
                    opacity: 0.6
                }
            }

            ProgressBar {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
                visible: root.progress > 0 && root.progress < 1
                value: root.progress
            }

            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: Kirigami.Units.largeSpacing
                visible: root.watched
                width: Kirigami.Units.iconSizes.medium
                height: width
                radius: width / 2
                color: Kirigami.Theme.highlightColor

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.small
                    height: width
                    source: "checkmark"
                    color: Kirigami.Theme.highlightedTextColor
                    isMask: true
                }
            }
        }

        ColumnLayout {
            id: labels

            // Move labels down when item is focused (since the card grows)
            property real focusOffset: root.activeFocus ? Kirigami.Units.smallSpacing * 2 : 0
            Behavior on focusOffset {
                NumberAnimation {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.OutCubic
                }
            }

            y: artwork.height + Kirigami.Units.largeSpacing + focusOffset
            width: artwork.width
            spacing: 0
            visible: root.hasLabels

            Label {
                Layout.fillWidth: true
                text: root.text
                visible: text.length > 0
                elide: Text.ElideRight
                Accessible.ignored: true
            }
            Label {
                Layout.fillWidth: true
                text: root.subtitle
                visible: text.length > 0
                elide: Text.ElideRight
                color: Kirigami.Theme.disabledTextColor
                type: Label.Small
                Accessible.ignored: true
            }
        }
    }
}
