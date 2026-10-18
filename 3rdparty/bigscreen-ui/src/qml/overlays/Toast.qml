// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami

/*!
   \brief Component to show an app message.

   Place it at the bottom of the window and call show(). It fades out on its own after
   \l timeout milliseconds.
 */
T.Control {
    id: root

    /*!
       \brief The text to show on the toast.
     */
    property string text

    /*!
       \brief The name of an icon shown before the message.
     */
    property string iconName

    /*!
       \brief How long the message stays, in milliseconds.
     */
    property int timeout: 2500

    /*!
       \brief Shows \a text, with the icon \a iconName, until the timeout passes.
     */
    function show(text: string, iconName: string): void {
        root.text = text;
        root.iconName = iconName;
        opacity = 1;
        timer.restart();
    }

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: implicitContentHeight + topPadding + bottomPadding

    anchors.horizontalCenter: parent?.horizontalCenter
    anchors.bottom: parent ? parent.bottom : 0
    anchors.bottomMargin: parent ? parent.SafeArea.margins.bottom : 0

    opacity: 0
    visible: opacity > 0
    leftPadding: Kirigami.Units.gridUnit * 1.5
    rightPadding: Kirigami.Units.gridUnit * 1.5
    topPadding: Kirigami.Units.gridUnit
    bottomPadding: Kirigami.Units.gridUnit

    Accessible.role: Accessible.AlertMessage
    Accessible.name: text

    Behavior on opacity {
        NumberAnimation {
            duration: Kirigami.Units.longDuration
        }
    }

    background: Kirigami.ShadowedRectangle {
        color: Kirigami.Theme.alternateBackgroundColor
        radius: Kirigami.Units.cornerRadius
        shadow.size: Kirigami.Units.gridUnit
        shadow.color: Qt.rgba(0, 0, 0, 0.5)
    }

    contentItem: RowLayout {
        spacing: Kirigami.Units.largeSpacing * 2

        Kirigami.Icon {
            implicitWidth: Kirigami.Units.iconSizes.smallMedium
            implicitHeight: Kirigami.Units.iconSizes.smallMedium
            visible: root.iconName !== ""
            source: root.iconName
            color: Kirigami.Theme.highlightColor
        }
        Label {
            text: root.text
            type: Label.Heading
        }
    }

    Timer {
        id: timer
        interval: root.timeout
        onTriggered: root.opacity = 0
    }
}
