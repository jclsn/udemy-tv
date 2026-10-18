// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

/*!
   \brief Large title, metadata and description for a featured or focused piece of media,
   with a row of actions underneath.

   \code
   BigscreenUI.HeroBanner {
       overline: i18n("Featured")
       title: movie.title
       metadata: [movie.year, movie.runtime, movie.genres]
       badges: ["4K", "13+"]
       description: movie.synopsis

       BigscreenUI.Button { text: i18n("Play"); icon.name: "media-playback-start" }
       BigscreenUI.Button { text: i18n("More info"); icon.name: "documentinfo" }
   }
   \endcode
 */
ColumnLayout {
    id: root

    /*!
       \brief Short text shown above the title, such as the name of the current rail.
     */
    property string overline

    /*!
       \brief The title of the media.
     */
    property string title

    /*!
       \brief Pieces of metadata shown under the title, separated by dots.
     */
    property list<string> metadata

    /*!
       \brief Short labels shown after the metadata.
     */
    property list<string> badges

    /*!
       \brief The description of the media.
     */
    property string description

    /*!
       \brief Pixel size of the title.
     */
    property int titlePixelSize: Window.width > 0 ? Math.round(Math.max(Units.sectionFontPixelSize, Math.min(Units.displayFontPixelSize, Window.width / 26))) : Units.displayFontPixelSize

    /*!
       \brief Whether the actions are shown.
       \default true
     */
    property bool actionsVisible: true

    /*!
       \qmlproperty list<Item> actions
       \brief Items shown in a row under the description, usually Buttons. Left and right move focus between them.
     */
    default property alias actions: actionRow.data

    /*!
       \qmlproperty RowLayout actionRow
       \brief The row holding the actions.
     */
    property alias actionRow: actionRow

    spacing: 0

    onTitleChanged: fadeIn.restart()

    NumberAnimation {
        id: fadeIn
        targets: [overlineLabel, titleLabel, metadataRow, descriptionLabel]
        property: "opacity"
        from: 0
        to: 1
        duration: Kirigami.Units.longDuration
        easing.type: Easing.OutCubic
    }

    Label {
        id: overlineLabel
        Layout.fillWidth: true
        visible: text.length > 0
        text: root.overline
        color: Kirigami.Theme.disabledTextColor
        type: Label.Heading
        elide: Text.ElideRight
    }

    Label {
        id: titleLabel
        Layout.fillWidth: true
        Layout.bottomMargin: Kirigami.Units.largeSpacing * 2
        text: root.title
        font.pixelSize: root.titlePixelSize
        font.weight: Font.Light
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight
        Accessible.role: Accessible.Heading
    }

    RowLayout {
        id: metadataRow
        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing
        visible: root.metadata.length > 0 || root.badges.length > 0

        Label {
            visible: text.length > 0
            text: root.metadata.filter(part => part.length > 0).join("  ·  ")
            color: Kirigami.Theme.disabledTextColor
            type: Label.Heading
        }

        Repeater {
            model: root.badges
            delegate: Badge {
                required property string modelData
                text: modelData
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }

    Label {
        id: descriptionLabel
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.largeSpacing * 2
        visible: text.length > 0
        text: root.description
        type: Label.Heading
        lineHeight: 1.2
        wrapMode: Text.Wrap
        maximumLineCount: 3
        elide: Text.ElideRight
    }

    RowLayout {
        id: actionRow
        Layout.topMargin: Kirigami.Units.gridUnit * 2
        spacing: Kirigami.Units.largeSpacing * 2
        visible: children.length > 0
        opacity: root.actionsVisible ? 1 : 0

        // Left and right move between the actions
        KeyNavigationGroup.orientation: Qt.Horizontal

        Behavior on opacity {
            NumberAnimation {
                duration: Kirigami.Units.longDuration
            }
        }
    }
}
