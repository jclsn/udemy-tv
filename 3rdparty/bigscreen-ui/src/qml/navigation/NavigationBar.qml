// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami

/*!
   \brief A row of tabs across the top of the screen for switching between the main
   pages of an application.

   \code
   BigscreenUI.NavigationBar {
       leading: Label { text: i18n("Media Center") }
       actions: [
           Kirigami.Action { text: i18n("Home") },
           Kirigami.Action { text: i18n("Movies") },
           Kirigami.Action {
               text: i18n("Search")
               icon.name: "search"
               displayHint: Kirigami.DisplayHint.IconOnly
           }
       ]
       onActivated: index => pages.currentIndex = index
   }
   \endcode
 */
FocusScope {
    id: root

    /*!
       \brief The actions shown as tabs.
     */
    property list<T.Action> actions

    /*!
       \brief The index of the selected tab.
     */
    property int currentIndex: 0

    /*!
       \brief An item shown before the tabs, such as the application name.
     */
    property Item leading

    /*!
       \brief An item shown at the far end of the bar, such as a clock.
     */
    property Item trailing

    /*!
       \brief This signal is emitted when the tab at \a index is activated.
     */
    signal activated(int index)

    implicitHeight: layout.implicitHeight + topPadding + bottomPadding
    implicitWidth: layout.implicitWidth + layout.anchors.leftMargin + layout.anchors.rightMargin

    property real topPadding: Kirigami.Units.gridUnit * 2
    property real bottomPadding: Kirigami.Units.gridUnit

    onActiveFocusChanged: {
        if (activeFocus) {
            tabs.currentIndex = root.currentIndex;
        }
    }
    // Focus follows the selected tab when it changes from elsewhere, such as Back going Home
    onCurrentIndexChanged: tabs.currentIndex = currentIndex

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.leftMargin: root.SafeArea.margins.left
        anchors.rightMargin: root.SafeArea.margins.right
        anchors.topMargin: root.topPadding
        anchors.bottomMargin: root.bottomPadding
        spacing: Kirigami.Units.gridUnit * 2

        // Handle focus between leading <-> tabs <-> trailing
        KeyNavigationGroup.orientation: Qt.Horizontal

        T.Control {
            implicitWidth: implicitContentWidth + leftPadding + rightPadding
            implicitHeight: implicitContentHeight + topPadding + bottomPadding
            visible: root.leading
            contentItem: root.leading
            leftPadding: 0
            rightPadding: 0
            topPadding: 0
            bottomPadding: 0
        }

        ListView {
            id: tabs

            Layout.preferredWidth: contentWidth
            Layout.preferredHeight: currentItem ? currentItem.implicitHeight : Kirigami.Units.gridUnit * 3

            focus: true
            orientation: ListView.Horizontal
            spacing: Kirigami.Units.smallSpacing
            keyNavigationEnabled: true
            interactive: false
            highlightFollowsCurrentItem: false

            model: root.actions
            delegate: NavigationTab {
                required property int index
                required property var modelData

                action: modelData
                selected: index === root.currentIndex

                onActiveFocusChanged: {
                    if (activeFocus) {
                        ListView.view.currentIndex = index;
                    }
                }
                onClicked: {
                    root.currentIndex = index;
                    root.activated(index);
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        T.Control {
            implicitWidth: implicitContentWidth + leftPadding + rightPadding
            implicitHeight: implicitContentHeight + topPadding + bottomPadding
            visible: root.trailing
            contentItem: root.trailing
            leftPadding: 0
            rightPadding: 0
            topPadding: 0
            bottomPadding: 0
        }
    }
}
