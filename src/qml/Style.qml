// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

pragma Singleton

import QtQuick

// The parts of udemy.com's look that the color scheme can't carry
QtObject {
    readonly property color purple: "#6d28d2"
    readonly property color purpleDark: "#5022c3"
    readonly property color purpleLight: "#c0c4fc"
    readonly property color text: "#2d2f31"
    readonly property color subtleText: "#6a6f73"
    readonly property color border: "#d1d7dc"
    readonly property color surface: "#f7f9fa"
    readonly property color dark: "#1d1e27"
    readonly property color ratingText: "#b4690e"
    readonly property color star: "#e59819"

    // Udemy sets big headings in a serif face
    readonly property string serifFamily: "Noto Serif"

    readonly property int cardTitlePixelSize: 19
    readonly property int cardDetailPixelSize: 15
}
