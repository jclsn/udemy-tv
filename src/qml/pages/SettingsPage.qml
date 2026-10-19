// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

import io.github.udemytv

BigscreenUI.ScrollablePage {
    id: root

    title: i18n("Settings")

    readonly property var captionOptions: [
        { text: i18n("Off"), value: "off" },
        { text: i18n("Language of this TV"), value: "auto" },
        { text: "English", value: "en" },
        { text: "Deutsch", value: "de" },
        { text: "Español", value: "es" },
        { text: "Français", value: "fr" },
        { text: "Italiano", value: "it" },
        { text: "Português", value: "pt" },
        { text: "Nederlands", value: "nl" },
        { text: "Polski", value: "pl" },
        { text: "Türkçe", value: "tr" },
        { text: "日本語", value: "ja" }
    ]
    readonly property var themeOptions: [
        { text: i18n("Light"), value: "light" },
        { text: i18n("Dark"), value: "dark" },
        { text: i18n("Same as the TV"), value: "system" }
    ]
    readonly property var speedOptions: [0.75, 1, 1.25, 1.5, 1.75, 2].map(rate => ({
        text: rate === 1 ? i18n("Normal") : i18n("%1×", rate.toLocaleString(Qt.locale())),
        value: rate
    }))
    readonly property var layoutOptions: [
        { text: i18n("Side by side"), value: NativePlayer.SideBySide },
        { text: i18n("Slides large, speaker small"), value: NativePlayer.SlidesLarge },
        { text: i18n("Speaker large, slides small"), value: NativePlayer.SpeakerLarge }
    ]

    background: Rectangle {
        color: Style.background
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        // ▲ and ▼ go through every setting; the headings between them are skipped
        BigscreenUI.KeyNavigationGroup.orientation: Qt.Vertical

        BigscreenUI.Label {
            text: i18n("Account")
            type: BigscreenUI.Label.Heading
            font.weight: Font.Bold
        }

        BigscreenUI.TextDelegate {
            // Information only, but reachable with the remote like every row
            focusPolicy: Qt.StrongFocus
            focus: true
            Layout.fillWidth: true
            text: UdemyClient.user.display_name ?? ""
            description: UdemyClient.demoMode ? i18n("Demo mode: sample courses, no account")
                : UdemyClient.portal === "www" ? (UdemyClient.user.email ?? "udemy.com")
                : i18n("Udemy Business: %1.udemy.com", UdemyClient.portal)
            leading: Avatar {
                user: UdemyClient.user
            }
        }

        BigscreenUI.ButtonDelegate {
            id: signOutButton
            Layout.fillWidth: true
            visible: !UdemyClient.demoMode
            text: i18n("Sign out")
            description: i18n("Removes your login from this TV")
            icon.name: "system-log-out"
            onClicked: signOutDialog.open()
        }

        BigscreenUI.Label {
            Layout.topMargin: Kirigami.Units.gridUnit
            text: i18n("Appearance")
            type: BigscreenUI.Label.Heading
            font.weight: Font.Bold
        }

        BigscreenUI.ComboBoxDelegate {
            Layout.fillWidth: true
            text: i18n("Colors")
            icon.name: "color-management"
            model: root.themeOptions
            textRole: "text"
            valueRole: "value"
            currentIndex: Math.max(0, root.themeOptions.findIndex(
                option => option.value === Preferences.theme))
            onActivated: index => Preferences.theme = root.themeOptions[index].value
        }

        BigscreenUI.Label {
            Layout.topMargin: Kirigami.Units.gridUnit
            text: i18n("Playback")
            type: BigscreenUI.Label.Heading
            font.weight: Font.Bold
        }

        BigscreenUI.ComboBoxDelegate {
            Layout.fillWidth: true
            text: i18n("Captions")
            icon.name: "media-view-subtitles-symbolic"
            model: root.captionOptions
            textRole: "text"
            valueRole: "value"
            currentIndex: Math.max(0, root.captionOptions.findIndex(
                option => option.value === Preferences.captions))
            onActivated: index => Preferences.captions = root.captionOptions[index].value
        }

        BigscreenUI.ComboBoxDelegate {
            Layout.fillWidth: true
            text: i18n("Playback speed")
            icon.name: "speedometer"
            model: root.speedOptions
            textRole: "text"
            valueRole: "value"
            currentIndex: Math.max(0, root.speedOptions.findIndex(
                option => option.value === Preferences.playbackRate))
            onActivated: index => Preferences.playbackRate = root.speedOptions[index].value
        }

        BigscreenUI.SwitchDelegate {
            Layout.fillWidth: true
            text: i18n("Play the next lecture automatically")
            icon.name: "media-skip-forward"
            checked: Preferences.autoplay
            onToggled: Preferences.autoplay = checked
        }

        BigscreenUI.ComboBoxDelegate {
            Layout.fillWidth: true
            text: i18n("Lectures with slides and a speaker")
            icon.name: "view-split-left-right"
            model: root.layoutOptions
            textRole: "text"
            valueRole: "value"
            currentIndex: Math.max(0, root.layoutOptions.findIndex(
                option => option.value === Preferences.dualLayout))
            onActivated: index => Preferences.dualLayout = root.layoutOptions[index].value
        }

        BigscreenUI.Label {
            Layout.topMargin: Kirigami.Units.gridUnit
            text: i18n("About")
            type: BigscreenUI.Label.Heading
            font.weight: Font.Bold
        }

        BigscreenUI.TextDelegate {
            // Information only, but reachable with the remote like every row
            focusPolicy: Qt.StrongFocus
            Layout.fillWidth: true
            text: i18n("Udemy TV %1", Qt.application.version)
            description: i18n("An unofficial app, not made or endorsed by Udemy, Inc. Your courses "
                + "stay subject to Udemy's terms of use.")
            icon.name: "help-about"
        }

        BigscreenUI.TextDelegate {
            // Information only, but reachable with the remote like every row
            focusPolicy: Qt.StrongFocus
            Layout.fillWidth: true
            text: UdemyClient.drmAvailable ? i18n("Copy-protected lectures: supported")
                : i18n("Copy-protected lectures: not supported")
            description: UdemyClient.drmAvailable
                ? i18n("They play in Udemy's own player, with the Widevine module found on "
                    + "this TV.")
                : i18n("Install Chromium and play a protected video there once, so it downloads "
                    + "the Widevine module.")
            icon.name: UdemyClient.drmAvailable ? "security-high" : "security-low"
        }
    }

    BigscreenUI.Dialog {
        id: signOutDialog

        title: i18n("Sign out of Udemy?")
        standardButtons: T.Dialog.Ok | T.Dialog.Cancel
        openFocusItem: standardButton(T.Dialog.Cancel)

        onAccepted: UdemyClient.logout()
        onClosed: signOutButton.forceActiveFocus()

        Component.onCompleted: {
            standardButton(T.Dialog.Ok).text = i18n("Sign out");
        }

        BigscreenUI.Label {
            width: parent.width
            wrapMode: Text.Wrap
            text: i18n("You can sign in again at any time.")
        }
    }
}
