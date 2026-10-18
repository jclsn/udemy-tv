// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami

/*!
   \brief A top-level window with a stack of pages, and an optional navigation bar and sidebar.

   \code
   BigscreenUI.ApplicationWindow {
       id: root

       readonly property list<Kirigami.Action> pageActions: [
           Kirigami.Action { text: "Home"; onTriggered: root.showPage(homePage) },
           Kirigami.Action { text: "Settings"; onTriggered: root.showPage(settingsPage) }
       ]

       readonly property list<BigscreenUI.Page> pages: [
           HomePage { id: homePage },
           SettingsPage { id: settingsPage }
       ]

       initialPage: homePage
       navigationBar: BigscreenUI.NavigationBar {
           actions: root.pageActions
       }
   }
   \endcode
 */
T.ApplicationWindow {
    id: root

    /*!
       \brief The stack of pages.
     */
    readonly property alias pageStack: stack

    /*!
       \brief The page shown first.
     */
    property var initialPage

    /*!
       \brief A NavigationBar, shown across the top of the window (optional).
     */
    property Item navigationBar

    /*!
       \brief A Sidebar, shown along the left of the window (optional).
     */
    property Item sidebar

    /*!
       \brief The dialog opened when back is pressed on the sidebar, or on the navigation bar
       when there is no sidebar. Set it to \c null to stay in the app instead.
     */
    property T.Popup quitDialog: defaultQuitDialog

    /*!
       \brief Replace all pages (including stacked ones) with the given page.
     */
    function showPage(page: var): void {
        if (stack.depth > 1) {
            stack.popToIndex(0);
        }
        if (sections.currentItem !== page) {
            sections.replace(page);
        }

        // Focus the page to close the sidebar if it's open
        const fromSidebar = sidebar ? sidebar.activeFocus : false;
        if (fromSidebar && sections.currentItem) {
            sections.currentItem.forceActiveFocus();
        }
    }

    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false

    color: Kirigami.Theme.backgroundColor

    StackView {
        id: stack

        anchors.fill: parent
        focus: true
        initialItem: home

        // Pages pushed over the navigation take focus from it
        onDepthChanged: {
            if (depth > 1) {
                forceActiveFocus();
            }
        }

        FocusScope {
            id: home
            focus: true

            StackView {
                id: sections

                readonly property real __navigationTop: navbarHolder.height
                readonly property real __navigationLeft: sidebarHolder.collapsedWidth

                anchors.fill: parent
                focus: true

                initialItem: root.initialPage

                Keys.onUpPressed: event => {
                    event.accepted = root.navigationBar !== null;
                    if (event.accepted) {
                        root.navigationBar.forceActiveFocus();
                    }
                }
                Keys.onLeftPressed: event => {
                    event.accepted = root.sidebar !== null;
                    if (event.accepted) {
                        root.sidebar.forceActiveFocus();
                    }
                }

                // Back from a page goes to the navigation bar or sidebar
                BackHandler.enabled: root.navigationBar !== null || root.sidebar !== null
                BackHandler.onActivated: (root.navigationBar ?? root.sidebar).forceActiveFocus()
            }

            FocusScope {
                id: navbarHolder

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: sidebarHolder.collapsedWidth
                height: root.navigationBar ? root.navigationBar.height : 0
                children: root.navigationBar ? [root.navigationBar] : []

                SafeArea.additionalMargins.left: Math.max(Units.horizontalScreenMarginFor(root.width) - sidebarHolder.collapsedWidth, Units.contentSpacing)
                SafeArea.additionalMargins.right: Units.horizontalScreenMarginFor(root.width)

                Keys.onDownPressed: sections.currentItem?.forceActiveFocus()

                // Back from the navigation bar goes on to the sidebar, or asks to quit
                BackHandler.enabled: root.sidebar !== null || root.quitDialog !== null
                BackHandler.onActivated: {
                    if (root.sidebar) {
                        root.sidebar.forceActiveFocus();
                    } else {
                        root.quitDialog.open();
                    }
                }

                Binding {
                    target: root.navigationBar
                    property: "width"
                    value: navbarHolder.width
                }
            }

            FocusScope {
                id: sidebarHolder

                readonly property real collapsedWidth: root.sidebar ? root.sidebar.collapsedWidth ?? root.sidebar.width : 0

                // Fills the window, so the sidebar can dim the page while it is expanded over it
                anchors.fill: parent
                children: root.sidebar ? [root.sidebar] : []

                Keys.onRightPressed: sections.currentItem?.forceActiveFocus()

                // Back from the sidebar asks to quit
                BackHandler.enabled: root.sidebar !== null && root.quitDialog !== null
                BackHandler.onActivated: root.quitDialog.open()

                Connections {
                    target: root.sidebar
                    ignoreUnknownSignals: true
                    function onDismissRequested() {
                        sections.currentItem?.forceActiveFocus();
                    }
                }

                Binding {
                    target: root.sidebar
                    property: "height"
                    value: sidebarHolder.height
                }
            }
        }
    }

    QuitDialog {
        id: defaultQuitDialog
    }
}
