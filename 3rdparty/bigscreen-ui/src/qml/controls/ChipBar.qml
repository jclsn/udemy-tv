// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick

import org.kde.kirigami as Kirigami

/*!
   \brief A horizontal row of Chips where one is selected at a time.

   \code
   BigscreenUI.ChipBar {
       model: [i18n("All"), i18n("Drama"), i18n("Comedy")]
       onActivated: index => filter = model[index]
   }
   \endcode
 */
ListView {
    id: root

    /*!
       \brief The index of the selected chip.
     */
    property int selectedIndex: 0

    /*!
       \brief This signal is emitted when the chip at \a index is activated.
     */
    signal activated(int index)

    implicitWidth: contentWidth
    implicitHeight: currentItem ? currentItem.implicitHeight : Kirigami.Units.gridUnit * 3

    orientation: ListView.Horizontal
    spacing: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
    keyNavigationEnabled: true
    boundsBehavior: Flickable.StopAtBounds
    clip: false
    highlightMoveDuration: Kirigami.Units.longDuration
    highlightRangeMode: ListView.ApplyRange
    preferredHighlightBegin: 0
    preferredHighlightEnd: width

    onActiveFocusChanged: {
        if (activeFocus) {
            currentIndex = selectedIndex;
        }
    }

    delegate: Chip {
        required property int index
        required property var modelData

        text: modelData
        checked: index === root.selectedIndex
        onClicked: {
            root.selectedIndex = index;
            root.activated(index);
        }
    }
}
