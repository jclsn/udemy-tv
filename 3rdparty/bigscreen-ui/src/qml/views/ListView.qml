// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick

import org.kde.kirigami as Kirigami

/*!
   \brief A vertically scrolling list of rows, such as ButtonDelegates, lined up with the page's content margins.
 */
ListView {
    id: root

    /*!
       \brief The width of each row.
     */
    readonly property real rowWidth: width - leftMargin - rightMargin

    // Room around the rows for the focused row's effect
    readonly property real __focusRoom: Kirigami.Units.gridUnit

    leftMargin: SafeArea.margins.left - __focusRoom
    rightMargin: SafeArea.margins.right - __focusRoom
    topMargin: __focusRoom
    bottomMargin: SafeArea.margins.bottom

    // Qt doesn't auto move the rows of a vertical list when its left margin grows (ex. when a Sidebar appears)
    contentX: -leftMargin

    keyNavigationEnabled: true
    boundsBehavior: Flickable.StopAtBounds
    spacing: Kirigami.Units.smallSpacing
    clip: true

    // Keep the current row away from the edges, so the rows around it stay in view
    highlightRangeMode: ListView.ApplyRange
    preferredHighlightBegin: Kirigami.Units.gridUnit * 2
    preferredHighlightEnd: height - Kirigami.Units.gridUnit * 6
    highlightMoveDuration: Kirigami.Units.veryLongDuration
    highlightMoveVelocity: -1

    layer.enabled: contentHeight > height - topMargin - bottomMargin
    layer.effect: EdgeFadeEffect {
        topFadeLength: root.topMargin
        bottomFadeLength: root.bottomMargin
    }

    onWidthChanged: __ensureCurrent()
    onActiveFocusChanged: __ensureCurrent()

    function __ensureCurrent(): void {
        if (currentIndex < 0 && count > 0 && width > 0) {
            currentIndex = 0;
        }
    }
}
