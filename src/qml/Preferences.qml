// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

pragma Singleton

import QtCore

Settings {
    category: "Preferences"

    // "off", "auto" (the system language) or a language code such as "en"
    property string captions: "off"
    property bool autoplay: true
    property real playbackRate: 1.0

    // How a lecture with slides and a speaker is shown, see NativePlayer.Layout
    property int dualLayout: 0
    property bool dualHintShown: false
}
