// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

import io.github.udemytv

// A course in the store, set out like its page on udemy.com: what it is in a dark band, the
// purchase card beside it, and below everything the course page tells. The buttons have the
// remote first; ◀ moves into the text, which ▲ and ▼ then scroll.
BigscreenUI.Page {
    id: root

    required property var course
    required property bool enrolled

    readonly property url landingUrl:
        UdemyClient.absoluteUrl((course.url ?? "").replace(/learn\/?$/, ""))
    readonly property url checkoutUrl:
        UdemyClient.absoluteUrl("/payment/checkout/express/course/%1/".arg(course.id))

    readonly property real sideMargin: contentMargins.left
    readonly property int students: (course.students ?? 0) > 0 ? course.students : details.students

    // As udemy.com, list the first sections only; long courses have a hundred
    readonly property int shownSections: 10
    readonly property real readingStep: height * 0.4

    function scrollBy(delta: real): void {
        const end = Math.max(0, reader.contentHeight - reader.height);
        scroll.to = Math.max(0, Math.min(end, reader.contentY + delta));
        scroll.restart();
    }

    function captionsText(): string {
        const languages = details.captionLanguages;

        if (languages.length <= 3) {
            return languages.join(", ");
        }

        return i18n("%1 and %2 more", languages.slice(0, 3).join(", "), languages.length - 3);
    }

    BigscreenUI.BackHandler.enabled: visible
    BigscreenUI.BackHandler.onActivated: T.StackView.view.pop()

    CourseDetails {
        id: details
        courseId: root.course.id ?? 0
    }

    background: Rectangle {
        color: "white"
    }

    // The band behind the purchase card, scrolling along with the one in the text
    Rectangle {
        x: reader.width
        y: -reader.contentY
        width: root.width - reader.width
        height: band.height
        color: Style.dark
    }

    Flickable {
        id: reader

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: card.left
        anchors.rightMargin: Kirigami.Units.gridUnit * 3
        contentHeight: column.implicitHeight + Kirigami.Units.gridUnit * 4
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        NumberAnimation {
            id: scroll
            target: reader
            property: "contentY"
            duration: Kirigami.Units.longDuration
            easing.type: Easing.OutCubic
        }

        ColumnLayout {
            id: column

            width: reader.width
            spacing: Kirigami.Units.gridUnit * 2

            Rectangle {
                id: band

                Layout.fillWidth: true
                implicitHeight: bandLayout.implicitHeight + Kirigami.Units.gridUnit * 5
                color: Style.dark

                ColumnLayout {
                    id: bandLayout

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: root.sideMargin
                    spacing: Kirigami.Units.gridUnit

                    Text {
                        Layout.fillWidth: true
                        text: root.course.title ?? ""
                        color: "white"
                        wrapMode: Text.Wrap
                        font.pixelSize: 48
                        font.weight: Font.Bold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.course.headline ?? ""
                        color: "white"
                        wrapMode: Text.Wrap
                        font.pixelSize: 24
                    }

                    RowLayout {
                        spacing: Kirigami.Units.gridUnit

                        StarRating {
                            onDark: true
                            pixelSize: 20
                            rating: root.course.rating ?? 0
                            reviews: root.course.numReviews ?? 0
                        }

                        Text {
                            visible: root.students > 0
                            text: i18n("%1 students",
                                       root.students.toLocaleString(Qt.locale(), "f", 0))
                            color: "white"
                            font.pixelSize: 20
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: (root.course.instructors ?? "").length > 0
                        text: i18n("Created by <font color=\"%1\"><u>%2</u></font>",
                                   Style.purpleLight, root.course.instructors)
                        textFormat: Text.StyledText
                        wrapMode: Text.Wrap
                        color: "white"
                        font.pixelSize: 20
                    }

                    Text {
                        Layout.fillWidth: true
                        text: [
                            details.lastUpdated.length > 0
                                ? i18n("Last updated %1", details.lastUpdated) : "",
                            details.language,
                            details.captionLanguages.length > 0
                                ? i18n("Captions: %1", root.captionsText()) : "",
                        ].filter(part => part.length > 0).join("   ·   ")
                        wrapMode: Text.Wrap
                        color: "white"
                        font.pixelSize: 18
                    }

                    Text {
                        Layout.fillWidth: true
                        text: [root.course.level, root.course.contentInfo]
                            .filter(part => part && part.length > 0)
                            .join("   ·   ")
                        color: Style.purpleLight
                        font.pixelSize: 18
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: root.sideMargin
                spacing: Kirigami.Units.gridUnit * 2

                BigscreenUI.BusyIndicator {
                    Layout.alignment: Qt.AlignHCenter
                    running: details.loading
                    visible: running
                }

                // What you'll learn, in a box as on udemy.com
                Rectangle {
                    Layout.fillWidth: true
                    visible: details.objectives.length > 0
                    implicitHeight: learnLayout.implicitHeight + Kirigami.Units.gridUnit * 3
                    border.color: Style.border
                    color: "white"

                    ColumnLayout {
                        id: learnLayout

                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.gridUnit * 1.5
                        spacing: Kirigami.Units.gridUnit

                        Heading {
                            text: i18n("What you'll learn")
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: Kirigami.Units.gridUnit * 2
                            rowSpacing: Kirigami.Units.largeSpacing

                            Repeater {
                                model: details.objectives

                                delegate: Point {
                                    required property string modelData

                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 1
                                    Layout.alignment: Qt.AlignTop
                                    mark: "✓"
                                    text: modelData
                                }
                            }
                        }
                    }
                }

                // The outline of the course
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: details.sections.length > 0
                    spacing: 0

                    Heading {
                        text: i18n("Course content")
                    }

                    Text {
                        Layout.bottomMargin: Kirigami.Units.gridUnit
                        text: i18n("%1 sections · %2 lectures · %3 total length",
                                   details.sections.length, details.lectureCount,
                                   details.totalLength)
                        color: Style.subtleText
                        font.pixelSize: 18
                    }

                    Repeater {
                        model: details.sections.slice(0, root.shownSections)

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            implicitHeight: sectionLayout.implicitHeight + Kirigami.Units.gridUnit
                            color: Style.surface
                            border.color: Style.border

                            RowLayout {
                                id: sectionLayout

                                anchors.fill: parent
                                anchors.leftMargin: Kirigami.Units.gridUnit
                                anchors.rightMargin: Kirigami.Units.gridUnit
                                spacing: Kirigami.Units.gridUnit

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.title
                                    color: Style.text
                                    elide: Text.ElideRight
                                    font.pixelSize: 19
                                    font.weight: Font.Bold
                                }

                                Text {
                                    text: [i18np("%1 lecture", "%1 lectures", modelData.lectures),
                                           modelData.length]
                                        .filter(part => part.length > 0)
                                        .join(" · ")
                                    color: Style.subtleText
                                    font.pixelSize: 17
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.topMargin: -Kirigami.Units.gridUnit
                    visible: details.sections.length > root.shownSections
                    text: i18np("… and %1 more section", "… and %1 more sections",
                                details.sections.length - root.shownSections)
                    color: Style.subtleText
                    font.pixelSize: 18
                }

                PointList {
                    title: i18n("Requirements")
                    points: details.prerequisites
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: details.description.length > 0
                    spacing: Kirigami.Units.gridUnit

                    Heading {
                        text: i18n("Description")
                    }

                    Text {
                        Layout.fillWidth: true
                        text: details.description
                        textFormat: Text.RichText
                        wrapMode: Text.Wrap
                        color: Style.text
                        linkColor: Style.purple
                        font.pixelSize: 21
                        lineHeight: 1.3
                    }
                }

                PointList {
                    title: i18n("Who this course is for:")
                    points: details.targetAudiences
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: details.instructors.length > 0
                    spacing: Kirigami.Units.gridUnit

                    Heading {
                        text: i18n("Instructors")
                    }

                    Repeater {
                        model: details.instructors

                        delegate: RowLayout {
                            required property var modelData

                            spacing: Kirigami.Units.gridUnit

                            Kirigami.ShadowedImage {
                                implicitWidth: Kirigami.Units.gridUnit * 4
                                implicitHeight: implicitWidth
                                radius: width / 2
                                color: Style.surface
                                source: modelData.image
                                fillMode: Image.PreserveAspectCrop
                            }

                            ColumnLayout {
                                spacing: Kirigami.Units.smallSpacing

                                Text {
                                    text: modelData.name
                                    color: Style.purple
                                    font.pixelSize: 21
                                    font.weight: Font.Bold
                                    font.underline: true
                                }

                                Text {
                                    visible: text.length > 0
                                    text: modelData.jobTitle
                                    color: Style.subtleText
                                    font.pixelSize: 18
                                }
                            }
                        }
                    }
                }

                BigscreenUI.Label {
                    visible: details.error.length > 0
                    text: i18n("Could not load the course page: %1", details.error)
                    color: Kirigami.Theme.negativeTextColor
                    wrapMode: Text.Wrap
                }
            }
        }
    }

    // Shows the text has the remote, along its left edge
    Rectangle {
        x: Kirigami.Units.largeSpacing
        y: Kirigami.Units.gridUnit * 2
        width: 5
        height: root.height - Kirigami.Units.gridUnit * 4
        radius: width / 2
        color: Style.purple
        visible: textKeys.activeFocus
    }

    Item {
        id: textKeys

        Keys.onUpPressed: root.scrollBy(-root.readingStep)
        Keys.onDownPressed: root.scrollBy(root.readingStep)
        Keys.onRightPressed: buyButton.forceActiveFocus()
        Keys.onPressed: event => {
            if (event.key === Qt.Key_PageDown) {
                root.scrollBy(reader.height * 0.9);
                event.accepted = true;
            } else if (event.key === Qt.Key_PageUp) {
                root.scrollBy(-reader.height * 0.9);
                event.accepted = true;
            }
        }
    }

    // The purchase card, as in the sidebar of a course page
    Rectangle {
        id: card

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: root.contentMargins.right
        anchors.topMargin: root.contentMargins.top
        width: Kirigami.Units.gridUnit * 24
        implicitHeight: cardLayout.implicitHeight
        color: "white"
        border.color: Style.border
        radius: Kirigami.Units.cornerRadius * 2

        ColumnLayout {
            id: cardLayout

            width: parent.width
            spacing: Kirigami.Units.gridUnit

            Image {
                Layout.fillWidth: true
                Layout.preferredHeight: width * 9 / 16
                source: root.course.imageLarge ?? root.course.image ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.gridUnit * 1.5
                Layout.topMargin: 0
                spacing: Kirigami.Units.gridUnit

                Text {
                    text: root.enrolled ? i18n("You own this course") : (root.course.price ?? "")
                    color: Style.text
                    font.pixelSize: root.enrolled ? 24 : 40
                    font.weight: Font.Bold
                }

                PrimaryButton {
                    id: buyButton

                    Layout.fillWidth: true
                    focus: true
                    text: root.enrolled ? i18n("Go to course") : i18n("Buy now")
                    icon.name: root.enrolled ? "media-playback-start" : ""
                    onClicked: {
                        if (root.enrolled) {
                            Window.window.openCourse(root.course);
                        } else {
                            Window.window.openWeb(root.checkoutUrl, i18n("Checkout"));
                        }
                    }

                    KeyNavigation.down: pageButton
                    KeyNavigation.left: textKeys
                }

                PrimaryButton {
                    id: pageButton

                    Layout.fillWidth: true
                    secondary: true
                    text: i18n("See the course on Udemy")
                    icon.name: "internet-services"
                    onClicked: Window.window.openWeb(root.landingUrl, root.course.title)

                    KeyNavigation.up: buyButton
                    KeyNavigation.left: textKeys
                }

                BigscreenUI.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    type: BigscreenUI.Label.Small
                    color: Style.subtleText
                    text: root.enrolled
                        ? i18n("Press ◀ to read about the course.")
                        : i18n("You pay on Udemy's checkout page, with the payment methods saved "
                            + "in your account. Press ◀ to read about the course.")
                }
            }
        }
    }

    component Heading: Text {
        Layout.fillWidth: true
        color: Style.text
        wrapMode: Text.Wrap
        font.pixelSize: 28
        font.weight: Font.Bold
    }

    // A line with a mark in front, such as a check mark or a bullet
    component Point: RowLayout {
        property string mark: "•"
        property string text

        spacing: Kirigami.Units.largeSpacing

        Text {
            Layout.alignment: Qt.AlignTop
            text: parent.mark
            color: Style.text
            font.pixelSize: 20
        }

        Text {
            Layout.fillWidth: true
            text: parent.text
            color: Style.text
            wrapMode: Text.Wrap
            font.pixelSize: 20
        }
    }

    component PointList: ColumnLayout {
        id: pointList

        property string title
        property list<string> points

        Layout.fillWidth: true
        visible: points.length > 0
        spacing: Kirigami.Units.largeSpacing

        Heading {
            text: pointList.title
        }

        Repeater {
            model: pointList.points

            delegate: Point {
                required property string modelData

                Layout.fillWidth: true
                text: modelData
            }
        }
    }
}
