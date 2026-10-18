// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami

/*!
   \brief A large icon and message shown in place of content that is empty or failed
   to load, with an optional action.

   \code
   BigscreenUI.PlaceholderMessage {
       anchors.centerIn: parent
       visible: view.count === 0
       iconName: "folder-videos"
       text: i18n("No videos here")
       explanation: i18n("Videos you add to this folder will appear here.")
       helpfulAction: Kirigami.Action {
           text: i18n("Go up")
           icon.name: "go-up"
           onTriggered: console.log("Go up")
       }
   }
   \endcode
 */
FocusScope {
    id: root

    /*!
       \brief The name of the icon shown above the text.
     */
    property string iconName

    /*!
       \brief The message.
     */
    property string text

    /*!
       \brief Text shown under the message, explaining it or what to do about it.
     */
    property string explanation

    /*!
       \brief An action shown as a button under the explanation. Focusing the placeholder
       focuses the button.
     */
    property T.Action helpfulAction

    implicitWidth: Math.min(Kirigami.Units.gridUnit * 40, layout.implicitWidth)
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing * 2

        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Kirigami.Units.largeSpacing
            implicitWidth: Kirigami.Units.iconSizes.enormous
            implicitHeight: Kirigami.Units.iconSizes.enormous
            visible: root.iconName.length > 0
            source: root.iconName
            opacity: 0.5
        }

        Label {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.text
            type: Label.Section
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            Accessible.role: Accessible.Heading
        }

        Label {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.explanation
            color: Kirigami.Theme.disabledTextColor
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }

        Button {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Kirigami.Units.gridUnit
            focus: visible
            visible: root.helpfulAction !== null && (!("visible" in root.helpfulAction) || root.helpfulAction.visible)
            action: root.helpfulAction
        }
    }
}
