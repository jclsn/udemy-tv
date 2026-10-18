// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

import io.github.udemytv

// "My learning", as on udemy.com: a dark band with the tabs, then the courses in a grid
BigscreenUI.Page {
    id: root

    enum Tab {
        AllCourses,
        MyLists,
        Wishlist,
        Archived
    }

    property int tab: HomePage.AllCourses

    // When the courses were last loaded, to refresh them after a while away (such as a purchase)
    property double loadedAt: 0

    function reload(): void {
        courses.reload();
        loadedAt = Date.now();
    }

    onVisibleChanged: {
        if (visible && loadedAt > 0 && Date.now() - loadedAt > 60 * 1000) {
            reload();
        }
    }

    background: Rectangle {
        color: "white"
    }

    CourseListModel {
        id: courses

        source: [
            CourseListModel.Enrolled,
            CourseListModel.Collections,
            CourseListModel.Wishlist,
            CourseListModel.Archived
        ][root.tab]
        onLoadingChanged: {
            if (!loading) {
                root.loadedAt = Date.now();
            }
        }
    }

    readonly property var progressFilters: [
        { text: i18n("All"), value: CourseListModel.AnyProgress },
        { text: i18n("In progress"), value: CourseListModel.InProgress },
        { text: i18n("Not started"), value: CourseListModel.NotStarted },
        { text: i18n("Completed"), value: CourseListModel.Completed }
    ]
    readonly property var orderings: [
        { text: i18n("Recently accessed"), value: CourseListModel.RecentlyAccessed },
        { text: i18n("Title: A-to-Z"), value: CourseListModel.TitleAscending },
        { text: i18n("Title: Z-to-A"), value: CourseListModel.TitleDescending }
    ]

    BigscreenUI.MediaGrid {
        id: grid

        anchors.fill: parent
        focus: true
        model: courses
        minimumCardWidth: Kirigami.Units.gridUnit * 17
        labelHeight: cardMetrics.labelsHeight
        rowSpacing: Kirigami.Units.gridUnit * 1.5

        // The grid can get focus before the courses arrive; then nothing would look focused
        onCountChanged: {
            if (currentIndex < 0 && count > 0) {
                currentIndex = 0;
            }

            moveFocusToHeaderIfEmpty();
        }

        onActiveFocusChanged: moveFocusToHeaderIfEmpty()

        // Focusing the grid itself would hand focus back to the header, which is part of it and
        // had it last, so focus the course instead
        function focusCourses(): bool {
            if (count === 0) {
                return false;
            }

            if (currentIndex < 0) {
                currentIndex = 0;
            }

            currentItem?.forceActiveFocus();

            return true;
        }

        // With no courses, such as after an error, the filters or the search are what is left
        function moveFocusToHeaderIfEmpty(): void {
            if (activeFocus && count === 0 && headerItem && !headerItem.activeFocus) {
                headerItem.forceActiveFocus();
            }
        }

        // Up from the first row goes to the filters and tabs in the header
        Keys.onUpPressed: event => {
            if (headerItem && !headerItem.activeFocus && currentIndex < columns) {
                headerItem.forceActiveFocus();
                event.accepted = true;
            } else {
                event.accepted = false;
            }
        }

        header: FocusScope {
            id: header

            width: grid.width - grid.leftMargin - grid.rightMargin
            implicitHeight: headerLayout.implicitHeight + Kirigami.Units.gridUnit * 2

            Keys.onDownPressed: event => event.accepted = grid.focusCourses()

            // The band reaches the edges of the screen
            Rectangle {
                x: -grid.leftMargin
                y: -grid.topMargin
                width: grid.width
                height: band.height + grid.topMargin
                color: Style.dark
            }

            ColumnLayout {
                id: headerLayout

                width: parent.width
                spacing: Kirigami.Units.gridUnit * 1.5

                ColumnLayout {
                    id: band
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.gridUnit

                    Text {
                        Layout.topMargin: Kirigami.Units.gridUnit
                        text: i18n("My learning")
                        color: "white"
                        font.family: Style.serifFamily
                        font.pixelSize: 54
                        font.weight: Font.Bold
                    }

                    UdemyTabBar {
                        id: tabBar
                        focus: true
                        tabs: [i18n("All courses"), i18n("My Lists"), i18n("Wishlist"),
                               i18n("Archived")]
                        currentIndex: root.tab
                        onActivated: index => root.tab = index
                        KeyNavigation.down: chips.visible ? chips : null
                    }
                }

                RowLayout {
                    id: chipRow
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.gridUnit * 2
                    visible: chips.count > 0

                    BigscreenUI.ChipBar {
                        id: chips

                        Layout.fillWidth: true
                        KeyNavigation.up: tabBar
                        KeyNavigation.right: sortChip.visible ? sortChip : null

                        // Lists choose which list; elsewhere, filter by progress
                        model: root.tab === HomePage.MyLists ? courses.collections
                            : root.tab === HomePage.AllCourses
                                ? root.progressFilters.map(filter => filter.text)
                            : []
                        selectedIndex: root.tab === HomePage.MyLists ? courses.collectionIndex
                            : root.progressFilters.findIndex(
                                filter => filter.value === courses.progressFilter)
                        onActivated: index => {
                            if (root.tab === HomePage.MyLists) {
                                courses.collectionIndex = index;
                            } else {
                                courses.progressFilter = root.progressFilters[index].value;
                            }
                        }
                    }

                    BigscreenUI.Chip {
                        id: sortChip
                        visible: root.tab === HomePage.AllCourses
                        text: i18n("Sort: %1", root.orderings.find(
                            ordering => ordering.value === courses.ordering).text)
                        KeyNavigation.up: tabBar
                        KeyNavigation.left: chips
                        onClicked: {
                            const orderings = root.orderings;
                            const index = orderings.findIndex(
                                ordering => ordering.value === courses.ordering);
                            courses.ordering = orderings[(index + 1) % orderings.length].value;
                        }
                    }
                }

                BigscreenUI.Label {
                    Layout.fillWidth: true
                    visible: root.tab === HomePage.MyLists && courses.collections.length === 0
                        && !courses.loading
                    text: i18n("Lists you make on udemy.com appear here.")
                    color: Style.subtleText
                }
            }
        }

        delegate: CourseCard {
            required property var model

            artworkWidth: GridView.view.cardWidth
            artworkHeight: GridView.view.artworkHeight
            storeMode: root.tab === HomePage.Wishlist
            enrolled: model.enrolled

            onClicked: {
                if (root.tab === HomePage.Wishlist) {
                    Window.window.openStoreCourse(course, enrolled);
                } else {
                    Window.window.openCourse(course);
                }
            }
        }
    }

    // Measures the card labels, so the grid can reserve room for them
    CourseCard {
        id: cardMetrics
        visible: false
        course: ({})
    }

    BigscreenUI.BusyIndicator {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: Kirigami.Units.gridUnit * 6
        running: courses.loading && courses.count === 0
    }

    BigscreenUI.PlaceholderMessage {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: Kirigami.Units.gridUnit * 6
        width: parent.width * 0.6
        visible: !courses.loading && courses.count === 0
            && (root.tab !== HomePage.MyLists || courses.collections.length > 0)
        iconName: courses.error.length > 0 ? "network-disconnect" : "applications-education"
        text: courses.error.length > 0 ? i18n("Could not load your courses")
            : root.tab === HomePage.Wishlist ? i18n("Your wishlist is empty")
            : root.tab === HomePage.Archived ? i18n("No archived courses")
            : courses.totalCount > 0 ? i18n("No courses match this filter")
            : i18n("No courses yet")
        explanation: courses.error.length > 0 ? courses.error
            : root.tab === HomePage.AllCourses && courses.totalCount === 0
                ? i18n("Find something to learn under Browse.") : ""
        helpfulAction: Kirigami.Action {
            visible: courses.error.length > 0
            text: i18n("Try again")
            icon.name: "view-refresh"
            onTriggered: root.reload()
        }
    }
}
