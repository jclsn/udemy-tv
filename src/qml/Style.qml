// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

pragma Singleton

import QtQuick

// The parts of udemy.com's look that the color scheme can't carry, light or dark
QtObject {
    readonly property bool dark: AppTheme.dark

    readonly property color purple: "#6d28d2"
    readonly property color purpleDark: "#5022c3"
    readonly property color purpleLight: "#c0c4fc"

    // Pages, and boxes and cards on them
    readonly property color background: dark ? "#16161d" : "#ffffff"
    readonly property color card: dark ? "#1f2029" : "#ffffff"
    readonly property color surface: dark ? "#1f2029" : "#f7f9fa"
    readonly property color border: dark ? "#3a3d4a" : "#d1d7dc"

    readonly property color text: dark ? "#f7f9fa" : "#2d2f31"
    readonly property color subtleText: dark ? "#b6bac4" : "#6a6f73"

    // The bands with white text, such as the one with "My learning"
    readonly property color band: dark ? "#262838" : "#1d1e27"

    // Focus rings and links, which need to stand out on the background
    readonly property color accent: dark ? purpleLight : purple

    readonly property color ratingText: dark ? "#f69c08" : "#b4690e"
    readonly property color star: "#e59819"

    // Udemy sets big headings in a serif face
    readonly property string serifFamily: "Noto Serif"

    readonly property int cardTitlePixelSize: 19
    readonly property int cardDetailPixelSize: 15
}
