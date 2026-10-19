// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

import io.github.udemytv

// Search the catalog, to find and buy new courses
BigscreenUI.Page {
    id: root

    readonly property list<string> suggestions: [
        i18n("Python"), i18n("Web Development"), i18n("Data Science"), i18n("Machine Learning"),
        i18n("Excel"), i18n("Photography"), i18n("Drawing"), i18n("Guitar"), i18n("Linux"),
        i18n("Kubernetes")
    ]

    function search(text: string): void {
        results.query = text;
    }

    background: Rectangle {
        color: Style.background
    }

    CourseListModel {
        id: results
        source: CourseListModel.Search
        query: root.suggestions[0]
    }

    BigscreenUI.MediaGrid {
        id: grid

        anchors.fill: parent
        focus: true
        model: results
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

        Keys.onUpPressed: event => {
            if (headerItem && !headerItem.activeFocus && currentIndex < columns) {
                headerItem.forceActiveFocus();
                event.accepted = true;
            } else {
                event.accepted = false;
            }
        }

        header: FocusScope {
            width: grid.width - grid.leftMargin - grid.rightMargin
            implicitHeight: headerLayout.implicitHeight + Kirigami.Units.gridUnit * 2

            Keys.onDownPressed: event => event.accepted = grid.focusCourses()

            Rectangle {
                x: -grid.leftMargin
                y: -grid.topMargin
                width: grid.width
                height: band.height + grid.topMargin
                color: Style.band
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
                        text: i18n("What do you want to learn?")
                        color: "white"
                        font.family: Style.serifFamily
                        font.pixelSize: 54
                        font.weight: Font.Bold
                    }

                    BigscreenUI.TextField {
                        id: searchField
                        Layout.fillWidth: true
                        Layout.maximumWidth: Kirigami.Units.gridUnit * 50
                        Layout.bottomMargin: Kirigami.Units.gridUnit * 1.5
                        focus: true
                        placeholderText: i18n("Search for anything")
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onAccepted: root.search(text)
                        KeyNavigation.down: chips
                    }
                }

                BigscreenUI.ChipBar {
                    id: chips
                    Layout.fillWidth: true
                    model: root.suggestions
                    selectedIndex: root.suggestions.indexOf(results.query)
                    KeyNavigation.up: searchField
                    onActivated: index => {
                        searchField.text = "";
                        root.search(root.suggestions[index]);
                    }
                }

                BigscreenUI.Label {
                    visible: results.query.length > 0 && !results.loading
                    text: i18np("%1 result for “%2”", "%1 results for “%2”",
                                results.count, results.query)
                    type: BigscreenUI.Label.Heading
                    font.weight: Font.Bold
                    color: Style.text
                }
            }
        }

        delegate: CourseCard {
            required property var model

            artworkWidth: GridView.view.cardWidth
            artworkHeight: GridView.view.artworkHeight
            storeMode: true
            enrolled: model.enrolled
            onClicked: Window.window.openStoreCourse(course, enrolled)
        }
    }

    CourseCard {
        id: cardMetrics
        visible: false
        course: ({})
    }

    BigscreenUI.BusyIndicator {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: Kirigami.Units.gridUnit * 6
        running: results.loading
    }

    BigscreenUI.PlaceholderMessage {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: Kirigami.Units.gridUnit * 6
        width: parent.width * 0.6
        visible: !results.loading && results.count === 0 && results.query.length > 0
        iconName: results.error.length > 0 ? "network-disconnect" : "search"
        text: results.error.length > 0 ? i18n("Could not search Udemy") : i18n("Nothing found")
        explanation: results.error
    }
}
