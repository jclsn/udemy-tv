// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Window

import org.kde.kirigami as Kirigami

/*!
   \brief A page that can scroll. The selected item is kept in the visible view.

   Give the page a single content item, such as a ColumnLayout.

   The content keeps within the page's \l {Page::contentMargins}{contentMargins}, and fades
   out as it scrolls into them. It never scrolls under the navigation.

   \code
   BigscreenUI.ScrollablePage {
       title: i18n("Settings")

       ColumnLayout {
           ...
       }
   }
   \endcode
 */
Page {
    id: root

    /*!
       \brief The content of the page.
     */
    default property alias content: flickable.flickableData

    /*!
       \qmlproperty Flickable flickable
       \brief The Flickable that scrolls the content.
     */
    property alias flickable: flickable

    padding: Kirigami.Units.gridUnit * 2

    // The title, when there is one, already keeps clear of the top
    topPadding: title.length > 0 ? padding : __navigationTop + contentMargins.top
    bottomPadding: contentMargins.bottom
    leftPadding: __navigationLeft + contentMargins.left
    rightPadding: contentMargins.right

    /*!
       \brief Scrolls so that \a item is fully visible, with some margin around it.
     */
    function ensureVisible(item: Item): void {
        const position = item.mapToItem(flickable.contentItem, 0, 0);
        const margin = Kirigami.Units.gridUnit;

        const top = flickable.contentY + flickable.topMargin;
        const bottom = flickable.contentY + flickable.height - flickable.bottomMargin;
        let target = flickable.contentY;
        if (position.y - margin < top) {
            target = position.y - margin - flickable.topMargin;
        } else if (position.y + item.height + margin > bottom) {
            target = position.y + item.height + margin + flickable.bottomMargin - flickable.height;
        }
        scrollTo(target);
    }

    /*!
       \brief Scrolls back to the start of the content.
     */
    function scrollToTop(): void {
        scrollTo(-flickable.topMargin);
    }

    function scrollTo(contentY: real): void {
        const minimum = -flickable.topMargin;
        const maximum = Math.max(minimum, flickable.contentHeight + flickable.bottomMargin - flickable.height);
        scrollAnimation.to = Math.max(minimum, Math.min(maximum, contentY));
        scrollAnimation.restart();
    }

    contentItem: Item {
        Flickable {
            id: flickable

            readonly property real leftOverflow: root.contentMargins.left
            readonly property real rightOverflow: root.contentMargins.right
            readonly property real topOverflow: root.title.length > 0 ? root.topPadding : root.contentMargins.top
            readonly property real bottomOverflow: root.contentMargins.bottom

            x: -leftOverflow
            y: -topOverflow
            width: parent.width + leftOverflow + rightOverflow
            height: parent.height + topOverflow + bottomOverflow

            leftMargin: leftOverflow
            rightMargin: rightOverflow
            topMargin: topOverflow
            bottomMargin: bottomOverflow

            clip: true
            layer.enabled: contentHeight > height - topMargin - bottomMargin
            layer.effect: EdgeFadeEffect {
                topFadeLength: flickable.topOverflow
                bottomFadeLength: flickable.bottomOverflow
            }
            contentWidth: parent.width
            contentHeight: contentItem.childrenRect.height
            boundsBehavior: Flickable.StopAtBounds

            Component.onCompleted: {
                contentY = -topMargin;
                updateContentWidth();
            }

            function updateContentWidth(): void {
                for (const child of contentItem.children) {
                    child.width = Qt.binding(() => root.availableWidth);
                }
            }

            Connections {
                target: flickable.contentItem
                function onChildrenChanged() {
                    flickable.updateContentWidth();
                }
            }

            NumberAnimation {
                id: scrollAnimation
                target: flickable
                property: "contentY"
                duration: Kirigami.Units.veryLongDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    // When scrolling past the top or bottom, snap the view to the end of the page
    Keys.onUpPressed: event => {
        scrollToTop();
        event.accepted = false;
    }
    Keys.onDownPressed: event => {
        scrollTo(flickable.contentHeight);
        event.accepted = false;
    }

    Connections {
        target: root.Window.window

        // If an item is focused in the page, call ensureVisible(item) on it so the view scrolls there
        function onActiveFocusItemChanged() {
            const item = root.Window.activeFocusItem;
            for (let parent = item; parent; parent = parent.parent) {
                if (parent === flickable.contentItem) {
                    root.ensureVisible(item);
                    return;
                }
            }
        }
    }
}
