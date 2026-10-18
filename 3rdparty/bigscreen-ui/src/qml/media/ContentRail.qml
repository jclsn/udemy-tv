// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

/*!
   \brief A titled, horizontally scrolling row of items, usually MediaCards.

   The current item stays at the left edge while the row scrolls.

   \code
   BigscreenUI.ContentRail {
       title: i18n("Recently added")
       model: recentlyAddedModel
       delegate: BigscreenUI.MediaCard {
           required property var modelData
           text: modelData.title
           source: modelData.poster
       }
   }
   \endcode
 */
FocusScope {
    id: root

    /*!
       \brief The title shown above the row.
     */
    property string title

    /*!
       \brief The space between the left edge and the first item. By default, it lines the first
       item up with the page's content.
       \default SafeArea.margins.left
     */
    property real leftPadding: SafeArea.margins.left

    /*!
       \brief The space between the last item and the right edge. By default, it lines the last
       item up with the page's content.
       \default SafeArea.margins.right
     */
    property real rightPadding: SafeArea.margins.right

    property alias model: listView.model
    property alias delegate: listView.delegate
    property alias currentIndex: listView.currentIndex
    property alias currentItem: listView.currentItem
    property alias count: listView.count
    property alias spacing: listView.spacing

    /*!
       \qmlproperty ListView view
       \brief The ListView showing the items.
     */
    property alias view: listView

    implicitHeight: column.implicitHeight
    implicitWidth: column.implicitWidth

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing * 2

        Label {
            Layout.fillWidth: true
            Layout.leftMargin: root.leftPadding
            Layout.rightMargin: root.rightPadding
            visible: text.length > 0
            text: root.title
            elide: Text.ElideRight
            type: Label.Section
            Accessible.role: Accessible.Heading
        }

        ListView {
            id: listView

            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: currentItem ? currentItem.implicitHeight : 0

            focus: true
            orientation: ListView.Horizontal
            spacing: Kirigami.Units.gridUnit
            keyNavigationEnabled: true
            boundsBehavior: Flickable.StopAtBounds
            clip: false

            leftMargin: root.leftPadding
            rightMargin: root.rightPadding
            displayMarginBeginning: root.leftPadding
            displayMarginEnd: root.rightPadding

            highlightFollowsCurrentItem: false

            // Keep the current item at the left padding until the end of the row is reached
            onCurrentItemChanged: scrollToCurrent()
            onWidthChanged: {
                ensureCurrent();
                scrollToCurrent();
            }
            onCountChanged: ensureCurrent()
            // The padding changes with the layout, such as when a Sidebar appears, and a ListView
            // leaves its items where they were, so move them at once
            onLeftMarginChanged: {
                scrollAnimation.stop();
                contentX = targetContentX();
            }

            // ListView picks its first item as current only as items arrive, which it can skip
            // while it has no size. The rail takes its height from the current item.
            function ensureCurrent(): void {
                if (currentIndex < 0 && count > 0 && width > 0) {
                    currentIndex = 0;
                }
            }

            function scrollToCurrent(): void {
                if (!currentItem) {
                    return;
                }
                scrollAnimation.to = targetContentX();
                scrollAnimation.restart();
            }

            function targetContentX(): real {
                const minimum = originX - leftMargin;
                if (!currentItem) {
                    return minimum;
                }
                const maximum = Math.max(minimum, originX + contentWidth + rightMargin - width);
                return Math.max(minimum, Math.min(maximum, currentItem.x - root.leftPadding));
            }

            NumberAnimation {
                id: scrollAnimation
                target: listView
                property: "contentX"
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }
    }
}
