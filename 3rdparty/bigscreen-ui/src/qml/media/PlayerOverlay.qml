// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami

/*!
   \brief Controls overlay over media content
 */
FocusScope {
    id: root

    /*!
       \brief Short text above the title, such as the show an episode belongs to.
     */
    property string overline

    /*!
       \brief The title of what is playing.
     */
    property string title

    /*!
       \brief Pieces of metadata shown under the title, separated by dots.
     */
    property list<string> metadata

    /*!
       \brief The playback position, in milliseconds.
     */
    property real position: 0

    /*!
       \brief The length of the media, in milliseconds.
     */
    property real duration: 0

    /*!
       \brief Whether the media is playing.
     */
    property bool playing: false

    /*!
       \brief Whether the media is loading or buffering. A busy indicator is shown in the
       middle of the screen, even while the controls are hidden.
     */
    property bool busy: false

    /*!
       \brief Whether there is an item to go back to, such as the previous file in a playlist.
       Skip buttons are shown when this or \l hasNext is true.
     */
    property bool hasPrevious: false

    /*!
       \brief Whether there is an item to go on to, such as the next file in a playlist.
     */
    property bool hasNext: false

    /*!
       \brief How far the skip buttons and the left and right keys on the seek bar move, in milliseconds.
     */
    property int seekStep: 10000

    /*!
       \brief How long the overlay stays visible without input while media plays, in milliseconds.
     */
    property int autoHideDelay: 4000

    /*!
       \brief Extra actions shown as round buttons on the right, such as subtitle selection.
       Actions with a \c visible property, such as Kirigami.Action, are hidden while it is false.
     */
    property list<T.Action> actions

    /*!
       \brief Whether the controls are currently visible.
     */
    readonly property bool shown: __shown

    signal playPauseRequested()
    signal seekRequested(real position)
    signal previousRequested()
    signal nextRequested()

    property bool __shown: true
    property Item __lastFocusItem: null

    /*!
       \brief Shows the controls and restarts the auto-hide timer.
     */
    function show(): void {
        hideTimer.restart();
        if (__shown) {
            return;
        }
        __shown = true;
        (__lastFocusItem ?? playButton).forceActiveFocus();
    }

    /*!
       \brief Hides the controls. Focus moves to an invisible item so the next key press shows them again.
     */
    function hide(): void {
        if (!__shown) {
            return;
        }
        const focusItem = Window.activeFocusItem;
        let inside = false;
        for (let item = focusItem; item; item = item.parent) {
            if (item === root) {
                inside = true;
                break;
            }
        }
        __lastFocusItem = (inside && focusItem !== wakeCatcher) ? focusItem : null;
        __shown = false;
        if (root.activeFocus) {
            wakeCatcher.forceActiveFocus();
        }
    }

    function __formatTime(milliseconds: real): string {
        const total = Math.max(0, Math.round(milliseconds / 1000));
        const hours = Math.floor(total / 3600);
        const minutes = Math.floor((total % 3600) / 60);
        const seconds = String(total % 60).padStart(2, "0");
        return hours > 0 ? `${hours}:${String(minutes).padStart(2, "0")}:${seconds}` : `${minutes}:${seconds}`;
    }

    function __seekBy(delta: real): void {
        root.seekRequested(Math.max(0, Math.min(root.duration, root.position + delta)));
        show();
    }

    onPlayingChanged: playing ? hideTimer.restart() : show()

    Timer {
        id: hideTimer
        interval: root.autoHideDelay
        // Only hide while the user is watching, not while focus is elsewhere
        running: root.__shown && root.playing && root.activeFocus
        onTriggered: root.hide()
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: root.busy
    }

    Connections {
        target: root.Window.window
        function onActiveFocusItemChanged() {
            if (root.__shown && root.activeFocus) {
                hideTimer.restart();
            }
        }
    }

    Item {
        id: wakeCatcher
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape || event.key === Qt.Key_Back) {
                event.accepted = false;
                return;
            }
            root.show();
            if (event.key === Qt.Key_Down) {
                seekBar.forceActiveFocus();
            }
            event.accepted = true;
        }
    }

    Item {
        id: chrome
        anchors.fill: parent
        opacity: root.__shown ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Kirigami.Units.veryLongDuration
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Math.round(parent.height * 0.25)
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.75) }
                GradientStop { position: 1; color: "transparent" }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.round(parent.height * 0.35)
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.45; color: Qt.rgba(0, 0, 0, 0.6) }
                GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.85) }
            }
        }

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: root.SafeArea.margins.left
            anchors.rightMargin: root.SafeArea.margins.right
            anchors.topMargin: root.SafeArea.margins.top
            spacing: Kirigami.Units.smallSpacing

            Label {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.overline
                color: Kirigami.Theme.disabledTextColor
                type: Label.Heading
                elide: Text.ElideRight
            }
            Label {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: Units.sectionFontPixelSize + 8
                font.weight: Font.Light
                elide: Text.ElideRight
            }
            Label {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.metadata.filter(part => part.length > 0).join("  ·  ")
                color: Kirigami.Theme.disabledTextColor
                type: Label.Heading
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: root.SafeArea.margins.left
            anchors.rightMargin: root.SafeArea.margins.right
            anchors.bottomMargin: root.SafeArea.margins.bottom
            spacing: Kirigami.Units.gridUnit * 1.5

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.gridUnit * 1.5

                Label {
                    Layout.minimumWidth: Kirigami.Units.gridUnit * 5
                    text: root.__formatTime(root.position)
                    type: Label.Heading
                    font.features: ({ "tnum": 1 })
                }

                SeekBar {
                    id: seekBar
                    Layout.fillWidth: true
                    from: 0
                    to: Math.max(1, root.duration)
                    value: root.position
                    stepSize: root.seekStep
                    Accessible.name: "Playback position"
                    KeyNavigation.down: playButton
                    Keys.onUpPressed: root.hide()
                    onMoved: root.seekRequested(value)
                }

                Label {
                    Layout.minimumWidth: Kirigami.Units.gridUnit * 5
                    horizontalAlignment: Text.AlignRight
                    text: "−" + root.__formatTime(root.duration - root.position)
                    type: Label.Heading
                    font.features: ({ "tnum": 1 })
                }
            }

            Item {
                id: controls
                Layout.fillWidth: true
                implicitHeight: transport.implicitHeight

                KeyNavigationGroup.orientation: Qt.Horizontal
                KeyNavigation.up: seekBar

                RowLayout {
                    id: transport
                    anchors.centerIn: parent
                    spacing: Kirigami.Units.gridUnit

                    RoundButton {
                        id: previousButton
                        text: "Previous"
                        icon.name: "media-skip-backward"
                        visible: root.hasPrevious || root.hasNext
                        enabled: root.hasPrevious
                        opacity: enabled ? 1 : 0.4
                        onClicked: {
                            root.previousRequested();
                            root.show();
                        }
                    }
                    RoundButton {
                        id: backButton
                        text: "Back %1 seconds".arg(Math.round(root.seekStep / 1000))
                        icon.name: "media-seek-backward"
                        onClicked: root.__seekBy(-root.seekStep)
                    }
                    RoundButton {
                        id: playButton
                        focus: true
                        text: root.playing ? "Pause" : "Play"
                        icon.name: root.playing ? "media-playback-pause" : "media-playback-start"
                        icon.width: Kirigami.Units.iconSizes.large
                        icon.height: Kirigami.Units.iconSizes.large
                        onClicked: {
                            root.playPauseRequested();
                            root.show();
                        }
                    }
                    RoundButton {
                        id: forwardButton
                        text: "Forward %1 seconds".arg(Math.round(root.seekStep / 1000))
                        icon.name: "media-seek-forward"
                        onClicked: root.__seekBy(root.seekStep)
                    }
                    RoundButton {
                        id: nextButton
                        text: "Next"
                        icon.name: "media-skip-forward"
                        visible: root.hasPrevious || root.hasNext
                        enabled: root.hasNext
                        opacity: enabled ? 1 : 0.4
                        onClicked: {
                            root.nextRequested();
                            root.show();
                        }
                    }
                }

                RowLayout {
                    id: extraActions
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Kirigami.Units.largeSpacing * 2

                    Repeater {
                        model: root.actions
                        delegate: RoundButton {
                            required property var modelData
                            action: modelData
                            display: T.AbstractButton.IconOnly
                            visible: !("visible" in modelData) || modelData.visible
                        }
                    }
                }
            }
        }
    }
}
