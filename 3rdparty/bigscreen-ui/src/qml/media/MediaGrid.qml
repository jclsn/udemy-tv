// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

/*!
   \brief A vertically scrolling grid of MediaCards, such as the contents of a folder or a
   library.

   A GridView that fits as many columns as it can, with cards at least \l minimumCardWidth
   wide, and stretches them to fill the width. Bind each card's \c artworkWidth and
   \c artworkHeight to \l cardWidth and \l artworkHeight.

   \code
   BigscreenUI.MediaGrid {
       anchors.fill: parent
       model: videosModel
       delegate: BigscreenUI.MediaCard {
           required property string title
           required property url thumbnail
           artworkWidth: GridView.view.cardWidth
           artworkHeight: GridView.view.artworkHeight
           text: title
           source: thumbnail
       }
   }
   \endcode
 */
BigscreenUI.GridView {
    id: root

    /*!
       \brief The smallest width of a card; cards grow from it to fill the row.
     */
    property real minimumCardWidth: Kirigami.Units.gridUnit * 16

    /*!
       \brief The width divided by the height of the artwork.
       \default 16 / 9
     */
    property real artworkAspectRatio: 16 / 9

    /*!
       \brief The height reserved under the artwork for the card's title and subtitle.
     */
    property real labelHeight: titleMetrics.height + subtitleMetrics.height + Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing * 2

    /*!
       \brief The number of columns of cards.
     */
    readonly property int columns: Math.max(1, Math.floor((width - leftMargin - rightMargin) / (minimumCardWidth + columnSpacing)))

    /*!
       \brief The width of each card's artwork.
     */
    readonly property real cardWidth: Math.floor(cellWidth - columnSpacing)

    /*!
       \brief The height of each card's artwork.
     */
    readonly property real artworkHeight: Math.round(cardWidth / artworkAspectRatio)

    columnSpacing: Kirigami.Units.gridUnit * 1.5
    rowSpacing: Kirigami.Units.gridUnit * 2

    cellWidth: (width - leftMargin - rightMargin) / columns
    cellHeight: artworkHeight + labelHeight + rowSpacing

    FontMetrics {
        id: titleMetrics
        font.pixelSize: Units.defaultFontPixelSize
    }

    FontMetrics {
        id: subtitleMetrics
        font.pixelSize: Units.smallFontPixelSize
    }
}
