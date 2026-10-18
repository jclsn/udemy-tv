// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami

T.Label {
    enum Type {
        Body,    // Units.defaultFontPixelSize
        Small,   // Units.smallFontPixelSize
        Heading, // Units.headingFontPixelSize
        Section, // Units.sectionFontPixelSize, light
        Title,   // Units.titleFontPixelSize, light
        Display  // Units.displayFontPixelSize, light
    }

    /*!
       \brief The style of the text in the type scale.
       \default Label.Body
     */
    property int type: Label.Body

    color: Kirigami.Theme.textColor
    linkColor: Kirigami.Theme.linkColor
    verticalAlignment: Text.AlignVCenter

    font.pixelSize: {
        switch (type) {
        case Label.Small: return Units.smallFontPixelSize;
        case Label.Heading: return Units.headingFontPixelSize;
        case Label.Section: return Units.sectionFontPixelSize;
        case Label.Title: return Units.titleFontPixelSize;
        case Label.Display: return Units.displayFontPixelSize;
        default: return Units.defaultFontPixelSize;
        }
    }
    font.weight: {
        switch (type) {
        case Label.Section:
        case Label.Title:
        case Label.Display:
            return Font.Light;
        default:
            return Font.Normal;
        }
    }
}
