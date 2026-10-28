// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

import io.github.udemytv

BigscreenUI.ApplicationWindow {
    id: root

    required property bool startFullScreen

    readonly property bool signedIn: UdemyClient.authState === UdemyClient.LoggedIn

    width: 1920
    height: 1080
    minimumWidth: 1280
    minimumHeight: 720
    visible: true
    visibility: startFullScreen ? Window.FullScreen : Window.Windowed
    title: i18n("Udemy TV")

    function openCourse(course: var): void {
        pageStack.push(coursePage, { course: course });
    }

    function openStoreCourse(course: var, enrolled: bool): void {
        pageStack.push(storeCoursePage, { course: course, enrolled: enrolled });
    }

    function openLecture(session: CourseSession, row: int): void {
        session.setCurrentRow(row);
        pageStack.push(lecturePage, { session: session, row: row });
    }

    function openWeb(url: url, title: string): void {
        pageStack.push(webPage, { url: url, title: title });
    }

    readonly property list<T.Action> pageActions: [
        Kirigami.Action {
            text: i18n("My learning")
            onTriggered: root.showPage(homePage)
        },
        Kirigami.Action {
            text: i18n("Browse")
            onTriggered: {
                if (!root.browsePage) {
                    root.browsePage = browsePageComponent.createObject(root.contentItem,
                                                                       { visible: false });
                }

                root.showPage(root.browsePage);
            }
        },
        Kirigami.Action {
            text: i18n("Settings")
            icon.name: "settings-configure"
            displayHint: Kirigami.DisplayHint.IconOnly
            onTriggered: {
                if (!root.settingsPage) {
                    root.settingsPage = settingsPageComponent.createObject(root.contentItem,
                                                                           { visible: false });
                }

                root.showPage(root.settingsPage);
            }
        },
        // Not a page, but a switch: the moon turns the colors dark, the sun light again
        Kirigami.Action {
            text: AppTheme.dark ? i18n("Use light colors") : i18n("Use dark colors")
            icon.name: AppTheme.dark ? "weather-clear-symbolic" : "weather-clear-night-symbolic"
            displayHint: Kirigami.DisplayHint.IconOnly
            onTriggered: Preferences.theme = AppTheme.dark ? "light" : "dark"
        }
    ]

    // Where the color switch sits in the navigation bar
    readonly property int colorSwitchIndex: pageActions.length - 1

    readonly property list<Item> pages: [
        HomePage {
            id: homePage
        }
    ]

    // Made when first opened, so the app starts sooner
    property BrowsePage browsePage: null
    property SettingsPage settingsPage: null

    initialPage: homePage

    navigationBar: BigscreenUI.NavigationBar {
        id: navigation

        // The tab of the page shown, which the color switch must not take over
        property int pageIndex: 0

        actions: root.pageActions

        onActivated: index => {
            if (index === root.colorSwitchIndex) {
                Qt.callLater(keepPageSelected);

                return;
            }

            pageIndex = index;
        }

        // Selecting the page's tab again moves the focus there too; the bar keeps its list of
        // tabs to itself, so find it to give the focus back to the switch
        function keepPageSelected(): void {
            currentIndex = pageIndex;
            const tabs = findTabs(navigation);

            if (tabs) {
                tabs.currentIndex = root.colorSwitchIndex;
                tabs.currentItem?.forceActiveFocus();
            }
        }

        function findTabs(item: Item): ListView {
            for (const child of item.children) {
                if (child instanceof ListView && child.count === navigation.actions.length) {
                    return child;
                }

                const found = findTabs(child);

                if (found) {
                    return found;
                }
            }

            return null;
        }

        leading: Wordmark {}
        trailing: Avatar {
            user: UdemyClient.user
        }
    }

    // Starting the browser engine behind the bridge holds up the window for a moment, so the
    // first page is shown before
    Loader {
        id: bridge

        z: item?.z ?? 0
        active: false
        sourceComponent: ApiBridge {}
    }

    Connections {
        target: root
        enabled: !bridge.active

        function onFrameSwapped(): void {
            bridge.active = true;
        }
    }

    // Light or dark, as chosen in the settings
    Binding {
        target: AppTheme
        property: "dark"
        value: Preferences.theme === "dark"
            || (Preferences.theme === "system" && Qt.styleHints.colorScheme === Qt.ColorScheme.Dark)
    }

    // Before signing in: the splash while connecting, then the login pages, over everything else
    BigscreenUI.StackView {
        id: gate

        anchors.fill: parent
        z: 100
        visible: !root.signedIn || busy
        enabled: !root.signedIn
        focus: !root.signedIn

        initialItem: splashPage

        function update(): void {
            if (UdemyClient.authState === UdemyClient.LoggedOut) {
                gate.replace(null, loginPage);
                gate.forceActiveFocus();
            } else if (UdemyClient.authState === UdemyClient.Connecting
                       && !(gate.currentItem instanceof SplashPage)) {
                // Keep a login web page open while it signs in
                if (gate.depth <= 1) {
                    gate.replace(null, splashPage);
                }
            } else if (UdemyClient.authState === UdemyClient.LoggedIn) {
                root.showPage(homePage);
                homePage.forceActiveFocus();
                gate.replace(null, splashPage);
            }
        }

        Connections {
            target: UdemyClient
            function onAuthStateChanged(): void {
                gate.update();
            }
        }

        Component.onCompleted: update()
    }

    Component {
        id: splashPage
        SplashPage {}
    }

    Component {
        id: loginPage
        LoginPage {
            onWebLoginRequested: gate.push(loginWebPage)
            onTokenRequested: gate.push(tokenPage, { mode: TokenPage.Token })
            onBusinessRequested: gate.push(tokenPage, { mode: TokenPage.Business })
        }
    }

    Component {
        id: loginWebPage
        WebPage {
            title: i18n("Log in to Udemy")
            hint: i18n("Move with the arrow keys, select with OK. Type with the on-screen keyboard "
                + "or a phone with KDE Connect.")
            url: UdemyClient.loginUrl
            onCloseRequested: gate.pop()
        }
    }

    Component {
        id: tokenPage
        TokenPage {
            onCloseRequested: gate.pop()
            onBusinessLoginRequested: gate.replace(loginWebPage)
        }
    }

    Component {
        id: browsePageComponent
        BrowsePage {}
    }

    Component {
        id: settingsPageComponent
        SettingsPage {}
    }

    Component {
        id: coursePage
        CoursePage {}
    }

    Component {
        id: storeCoursePage
        StoreCoursePage {}
    }

    Component {
        id: lecturePage
        LecturePage {}
    }

    Component {
        id: webPage
        WebPage {
            onCloseRequested: root.pageStack.pop()
        }
    }
}
