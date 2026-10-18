// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

import io.github.udemytv

// A course in the store, set out like its page on udemy.com
BigscreenUI.Page {
    id: root

    required property var course
    required property bool enrolled

    readonly property url landingUrl:
        UdemyClient.absoluteUrl((course.url ?? "").replace(/learn\/?$/, ""))
    readonly property url checkoutUrl:
        UdemyClient.absoluteUrl("/payment/checkout/express/course/%1/".arg(course.id))

    BigscreenUI.BackHandler.enabled: visible
    BigscreenUI.BackHandler.onActivated: T.StackView.view.pop()

    background: Rectangle {
        color: "white"

        Rectangle {
            width: parent.width
            height: parent.height * 0.62
            color: Style.dark
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.contentMargins.left
        anchors.rightMargin: root.contentMargins.right
        anchors.topMargin: root.contentMargins.top
        anchors.bottomMargin: root.contentMargins.bottom
        spacing: Kirigami.Units.gridUnit * 4

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: Kirigami.Units.gridUnit * 2
            spacing: Kirigami.Units.gridUnit

            Text {
                Layout.fillWidth: true
                text: root.course.title ?? ""
                color: "white"
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                font.pixelSize: 52
                font.weight: Font.Bold
            }

            Text {
                Layout.fillWidth: true
                text: root.course.headline ?? ""
                color: "white"
                wrapMode: Text.Wrap
                font.pixelSize: 26
            }

            StarRating {
                Layout.topMargin: Kirigami.Units.largeSpacing
                onDark: true
                pixelSize: 22
                rating: root.course.rating ?? 0
                reviews: root.course.numReviews ?? 0
            }

            Text {
                Layout.fillWidth: true
                visible: (root.course.students ?? 0) > 0
                text: i18n("%1 students",
                           (root.course.students ?? 0).toLocaleString(Qt.locale(), "f", 0))
                color: "white"
                font.pixelSize: 20
            }

            Text {
                Layout.fillWidth: true
                visible: (root.course.instructors ?? "").length > 0
                text: i18n("Created by <font color=\"%1\"><u>%2</u></font>",
                           Style.purpleLight, root.course.instructors)
                textFormat: Text.StyledText
                color: "white"
                font.pixelSize: 20
            }

            Text {
                Layout.fillWidth: true
                text: [root.course.level, root.course.contentInfo]
                    .filter(part => part && part.length > 0)
                    .join("  ·  ")
                color: Style.purpleLight
                font.pixelSize: 20
            }
        }

        // The purchase card, as in the sidebar of a course page
        Rectangle {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: Kirigami.Units.gridUnit * 26
            implicitHeight: card.implicitHeight
            color: "white"
            border.color: Style.border
            radius: Kirigami.Units.cornerRadius * 2

            ColumnLayout {
                id: card
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
                        text: root.enrolled ? i18n("You own this course")
                            : (root.course.price ?? "")
                        color: Style.text
                        font.pixelSize: root.enrolled ? 24 : 40
                        font.weight: Font.Bold
                    }

                    PrimaryButton {
                        id: buyButton
                        Layout.fillWidth: true
                        focus: true
                        text: root.enrolled ? i18n("Go to course") : i18n("Buy now")
                        icon.name: root.enrolled ? "media-playback-start" : "cart-shopping"
                        onClicked: {
                            if (root.enrolled) {
                                Window.window.openCourse(root.course);
                            } else {
                                Window.window.openWeb(root.checkoutUrl, i18n("Checkout"));
                            }
                        }

                        KeyNavigation.down: pageButton
                    }

                    PrimaryButton {
                        id: pageButton
                        Layout.fillWidth: true
                        secondary: true
                        text: i18n("See the course on Udemy")
                        icon.name: "internet-services"
                        onClicked: Window.window.openWeb(root.landingUrl, root.course.title)
                    }

                    BigscreenUI.Label {
                        Layout.fillWidth: true
                        visible: !root.enrolled
                        wrapMode: Text.Wrap
                        type: BigscreenUI.Label.Small
                        color: Style.subtleText
                        text: i18n("You pay on Udemy's checkout page, with the payment methods "
                            + "saved in your account. The course appears under My learning "
                            + "afterwards.")
                    }
                }
            }
        }
    }
}
