// SPDX-FileCopyrightText: 2025 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

/*!
   \brief The header on a ContextDrawer, containing a title, subtitle and icon.
 */
ColumnLayout {
    id: root

    /*!
       \brief This property holds the title to display on the header.
     */
    property string title

    /*!
       \brief This property holds the subtitle to display on the header.
     */
    property string subtitle

    /*!
       \brief This property holds the icon to display on the header.
     */
    property alias iconSource: headerIcon.source

    spacing: Kirigami.Units.gridUnit

    Item { Layout.fillHeight: true }

    Kirigami.Icon {
        id: headerIcon

        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 96
        implicitHeight: 96
    }

    Label {
        id: titleLabel
        visible: text.length > 0

        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
        text: root.title
        type: Label.Section
    }

    Label {
        id: subtitleLabel
        visible: text.length > 0

        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
        text: root.subtitle
        font.weight: Font.Light
    }
}
