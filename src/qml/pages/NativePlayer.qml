// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import QtMultimedia
import QtQuick.Pdf

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

import io.github.udemytv

// Plays a lecture. Lectures with slides and a speaker show both, in one of three layouts
// that "Switch view" (or ▲ while the controls are hidden, or S) goes through.
FocusScope {
    id: root

    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
    Kirigami.Theme.inherit: false

    enum Layout {
        SideBySide,
        SlidesLarge,
        SpeakerLarge
    }

    required property CourseSession session
    required property int row
    required property var lecture

    property bool hasNext: false
    property bool hasPrevious: false
    property string nextTitle

    signal nextRequested()
    signal previousRequested()
    signal webPlayerRequested()

    readonly property var item: session.item(row)
    readonly property bool dual: lecture.kind === "mashup"
    readonly property bool slidesOnly: lecture.kind === "presentation"
    readonly property bool hasSlides: dual || slidesOnly
    // Encrypted lectures play through Widevine (ProtectedVideo), the rest with Qt Multimedia
    readonly property bool protectedVideo: lecture.protected ?? false
    readonly property ProtectedVideo protectedPlayer: protectedLoader.item as ProtectedVideo

    // The state of whichever of the two plays the lecture
    readonly property real position: protectedVideo ? (protectedPlayer?.position ?? 0)
                                                    : media.position
    readonly property real duration: protectedVideo ? (protectedPlayer?.duration ?? 0)
                                                    : media.duration
    readonly property bool playing: protectedVideo
        ? (protectedPlayer?.playing ?? false)
        : media.playbackState === MediaPlayer.PlayingState
    readonly property bool busy: protectedVideo ? (protectedPlayer?.busy ?? true)
        : media.mediaStatus === MediaPlayer.LoadingMedia
            || media.mediaStatus === MediaPlayer.BufferingMedia
            || media.mediaStatus === MediaPlayer.StalledMedia
    readonly property string errorText: protectedVideo ? (protectedPlayer?.errorString ?? "")
        : media.error !== MediaPlayer.NoError ? media.errorString : ""

    function play(): void {
        if (protectedVideo) {
            protectedPlayer?.play();
        } else {
            media.play();
        }
    }

    function pause(): void {
        if (protectedVideo) {
            protectedPlayer?.pause();
        } else {
            media.pause();
        }
    }

    function seekTo(milliseconds: real): void {
        if (protectedVideo) {
            protectedPlayer?.seek(milliseconds);
        } else {
            media.position = milliseconds;
        }
    }

    readonly property bool completed: session.curriculum.revision >= 0
        && (session.item(row).completed ?? false)

    property int layoutMode: Preferences.dualLayout

    // Slides
    readonly property var slides: lecture.slides ?? []
    readonly property bool timedSlides: lecture.timedSlides ?? false
    readonly property bool pdfSlides: (lecture.slidesPdf ?? "").length > 0
    readonly property int slideCount: slides.length > 0 ? slides.length
        : (pdfSlides ? pdf.pageCount : 0)
    property int manualSlide: 0
    readonly property int slideIndex: {
        if (!timedSlides) {
            return manualSlide;
        }

        const seconds = root.position / 1000;
        let index = 0;

        for (let i = 0; i < slides.length; ++i) {
            if (slides[i].time >= 0 && slides[i].time <= seconds) {
                index = i;
            }
        }

        return index;
    }

    readonly property var currentSlide: slides[slideIndex] ?? ({})
    readonly property int currentPage: slides.length > 0 ? (currentSlide.page ?? slideIndex)
        : manualSlide

    // Streams and captions
    property string source: lecture.source ?? ""
    property var captionTrack: null
    property bool resumed: false
    property bool completionSent: false
    // Where to continue once a new stream has loaded, such as after changing the quality
    property real seekOnLoad: -1

    function formatTime(milliseconds: real): string {
        const total = Math.max(0, Math.round(milliseconds / 1000));
        const minutes = Math.floor(total / 60);
        const seconds = String(total % 60).padStart(2, "0");

        return `${minutes}:${seconds}`;
    }

    function layoutName(mode: int): string {
        switch (mode) {
        case NativePlayer.SlidesLarge:
            return i18n("Slides large");
        case NativePlayer.SpeakerLarge:
            return i18n("Speaker large");
        default:
            return i18n("Slides and speaker side by side");
        }
    }

    function cycleLayout(): void {
        layoutMode = (layoutMode + 1) % 3;
        Preferences.dualLayout = layoutMode;
        toast.show(layoutName(layoutMode), "view-split-left-right");
    }

    function stepSlide(delta: int): void {
        manualSlide = Math.max(0, Math.min(slideCount - 1, manualSlide + delta));
        overlay.show();
    }

    function pickCaptions(): var {
        const tracks = lecture.captions ?? [];
        let language = Preferences.captions;

        if (language === "off" || tracks.length === 0) {
            return null;
        }

        if (language === "auto") {
            language = Qt.locale().name.split("_")[0];
        }

        const prefix = language.toLowerCase();

        return tracks.find(track => track.locale.toLowerCase().startsWith(prefix)) ?? null;
    }

    function resume(): void {
        resumed = true;

        if (seekOnLoad >= 0) {
            seekTo(seekOnLoad);
            seekOnLoad = -1;

            return;
        }

        const local = session.savedPosition(row);
        const seconds = local > 0 ? local : (lecture.resumePosition ?? 0);
        const duration = root.duration / 1000;

        if (seconds > 5 && (duration <= 0 || seconds < duration - 15)) {
            seekTo(seconds * 1000);
            toast.show(i18n("Continuing at %1", formatTime(seconds * 1000)),
                       "media-playback-start");
        }
    }

    function savePosition(): void {
        if (root.duration > 0) {
            session.reportPosition(row, root.position / 1000, root.duration / 1000);
        }
    }

    function markCompleted(): void {
        if (!completionSent) {
            completionSent = true;
            session.setCompleted(row, true);
        }
    }

    function finished(): void {
        markCompleted();
        savePosition();

        if (Preferences.autoplay && hasNext) {
            upNext.start();
        } else {
            overlay.show();
        }
    }

    Component.onCompleted: {
        captionTrack = pickCaptions();

        if (!slidesOnly && !protectedVideo) {
            media.play();
        }

        if (dual) {
            hintTimer.start();
        }
    }

    Component.onDestruction: savePosition()

    MediaPlayer {
        id: media

        source: root.slidesOnly || root.protectedVideo ? "" : root.source
        videoOutput: video
        audioOutput: AudioOutput {}
        playbackRate: Preferences.playbackRate

        onMediaStatusChanged: {
            const loaded = mediaStatus === MediaPlayer.LoadedMedia
                || mediaStatus === MediaPlayer.BufferedMedia;

            if (!root.resumed && loaded && duration > 0) {
                root.resume();
            } else if (mediaStatus === MediaPlayer.EndOfMedia) {
                root.finished();
            }
        }
    }

    // After "Continuing at…", so both can be read
    Timer {
        id: hintTimer
        interval: 4500
        onTriggered: toast.show(i18n("Press ▲ to switch between slides and speaker"),
                                "view-split-left-right")
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.playing
        onTriggered: {
            root.savePosition();

            // Udemy counts a video as watched shortly before its end
            if (root.duration > 0 && root.position >= root.duration - 10000) {
                root.markCompleted();
            }
        }
    }

    // Where the slides and the speaker go in each layout
    readonly property real gap: Kirigami.Units.gridUnit
    readonly property rect fullRect: Qt.rect(0, 0, width, height)
    readonly property rect pipRect: {
        const w = Math.round(width * 0.24);
        const h = Math.round(w * 9 / 16);

        return Qt.rect(width - w - gap * 2, gap * 2, w, h);
    }

    readonly property rect sideMainRect: {
        const w = Math.round((width - gap * 3) * 0.66);
        const h = Math.min(Math.round(w * 9 / 16), height - gap * 2);

        return Qt.rect(gap, Math.round((height - h) / 2), w, h);
    }

    readonly property rect sideSecondRect: {
        const x = sideMainRect.x + sideMainRect.width + gap;
        const w = width - x - gap;
        const h = Math.round(w * 9 / 16);

        return Qt.rect(x, Math.round((height - h) / 2), w, h);
    }

    readonly property rect slidesRect: !dual ? fullRect
        : layoutMode === NativePlayer.SideBySide ? sideMainRect
        : layoutMode === NativePlayer.SlidesLarge ? fullRect
        : pipRect
    readonly property rect speakerRect: !dual ? fullRect
        : layoutMode === NativePlayer.SideBySide ? sideSecondRect
        : layoutMode === NativePlayer.SpeakerLarge ? fullRect
        : pipRect

    component Pane: Rectangle {
        id: pane

        required property rect target
        // Outlined, when shown small beside or over the other pane
        property bool framed: false

        x: target.x
        y: target.y
        width: target.width
        height: target.height
        clip: true
        border.width: framed ? 2 : 0
        border.color: Qt.alpha("white", 0.7)

        Behavior on x {
            NumberAnimation {
                duration: Kirigami.Units.veryLongDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: Kirigami.Units.veryLongDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: Kirigami.Units.veryLongDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: Kirigami.Units.veryLongDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    Pane {
        id: speakerPane

        target: root.speakerRect
        framed: root.dual && root.speakerRect.width < root.width * 0.5
        visible: !root.slidesOnly
        color: "black"
        z: root.dual && root.layoutMode === NativePlayer.SlidesLarge ? 2 : 1

        // Audio lectures have nothing to show but the course picture
        Image {
            anchors.fill: parent
            visible: root.lecture.audioOnly ?? false
            source: root.session.course.imageLarge ?? ""
            fillMode: Image.PreserveAspectFit
        }

        VideoOutput {
            id: video
            anchors.fill: parent
            anchors.margins: parent.border.width
            fillMode: VideoOutput.PreserveAspectFit
            visible: !root.protectedVideo
        }

        Loader {
            id: protectedLoader

            anchors.fill: parent
            anchors.margins: parent.border.width
            active: root.protectedVideo

            sourceComponent: ProtectedVideo {
                source: root.lecture.protectedSource ?? ""
                licenseToken: root.lecture.licenseToken ?? ""
                playbackRate: Preferences.playbackRate

                onLoadedChanged: {
                    if (loaded && !root.resumed) {
                        root.resume();
                    }
                }

                onFinished: root.finished()
            }
        }
    }

    Pane {
        id: slidesPane

        target: root.slidesRect
        framed: root.dual && root.slidesRect.width < root.width * 0.5
        visible: root.hasSlides
        color: "white"
        z: root.dual && root.layoutMode === NativePlayer.SpeakerLarge ? 2 : 1

        Image {
            anchors.fill: parent
            anchors.margins: parent.border.width
            visible: !root.pdfSlides
            source: root.currentSlide.image ?? ""
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
            sourceSize.width: 1920
            sourceSize.height: 1080
        }

        RemoteFile {
            id: pdfFile
            source: root.pdfSlides ? root.lecture.slidesPdf : ""
        }

        PdfDocument {
            id: pdf
            source: pdfFile.localUrl
        }

        PdfPageImage {
            anchors.fill: parent
            anchors.margins: parent.border.width
            visible: root.pdfSlides && pdf.status === PdfDocument.Ready
            document: pdf
            currentFrame: Math.min(root.currentPage, Math.max(0, pdf.pageCount - 1))
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            sourceSize.width: 1920
            sourceSize.height: 1080
        }

        BigscreenUI.BusyIndicator {
            anchors.centerIn: parent
            running: pdfFile.loading
        }

        // "3 / 12", for slides that do not follow the video
        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Kirigami.Units.largeSpacing
            visible: !root.timedSlides && root.slideCount > 1
            implicitWidth: pageLabel.implicitWidth + Kirigami.Units.largeSpacing * 2
            implicitHeight: pageLabel.implicitHeight + Kirigami.Units.smallSpacing * 2
            radius: Kirigami.Units.cornerRadius
            color: Qt.alpha("black", 0.6)

            Text {
                id: pageLabel
                anchors.centerIn: parent
                text: "%1 / %2".arg(root.currentPage + 1).arg(root.slideCount)
                color: "white"
                font.pixelSize: 18
            }
        }
    }

    CaptionTrack {
        id: captions
        source: root.captionTrack?.url ?? ""
        position: root.position
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: overlay.shown ? Kirigami.Units.gridUnit * 13
                                            : Kirigami.Units.gridUnit * 3
        z: 3
        width: Math.min(captionText.implicitWidth, root.width * 0.8) + Kirigami.Units.gridUnit * 2
        height: captionText.implicitHeight + Kirigami.Units.gridUnit
        visible: captionText.text.length > 0
        radius: Kirigami.Units.cornerRadius
        color: Qt.alpha("black", 0.75)

        Behavior on anchors.bottomMargin {
            NumberAnimation { duration: Kirigami.Units.longDuration }
        }

        Text {
            id: captionText
            anchors.centerIn: parent
            width: Math.min(implicitWidth, root.width * 0.8)
            text: captions.text
            color: "white"
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 36
        }
    }

    BigscreenUI.PlayerOverlay {
        id: overlay

        anchors.fill: parent
        z: 4
        focus: !upNext.active

        overline: root.session.course.title ?? ""
        title: (root.item.number ?? 0) > 0
            ? "%1. %2".arg(root.item.number).arg(root.item.title)
            : (root.item.title ?? "")
        metadata: [root.item.sectionTitle ?? "", root.completed ? i18n("Completed") : ""]
        position: root.position
        duration: root.duration
        playing: root.playing
        busy: root.busy || pdfFile.loading
        hasPrevious: root.hasPrevious
        hasNext: root.hasNext

        onPlayPauseRequested: root.playing ? root.pause() : root.play()
        onSeekRequested: position => root.seekTo(position)
        onPreviousRequested: root.previousRequested()
        onNextRequested: root.nextRequested()

        actions: [
            Kirigami.Action {
                text: i18n("Switch view")
                icon.name: "view-split-left-right"
                visible: root.dual
                onTriggered: root.cycleLayout()
            },
            Kirigami.Action {
                text: i18n("Previous slide")
                icon.name: "go-previous"
                visible: root.hasSlides && !root.timedSlides && root.slideCount > 1
                onTriggered: root.stepSlide(-1)
            },
            Kirigami.Action {
                text: i18n("Next slide")
                icon.name: "go-next"
                visible: root.hasSlides && !root.timedSlides && root.slideCount > 1
                onTriggered: root.stepSlide(1)
            },
            Kirigami.Action {
                text: i18n("Captions")
                icon.name: "media-view-subtitles-symbolic"
                visible: (root.lecture.captions ?? []).length > 0
                onTriggered: {
                    const tracks = root.lecture.captions;
                    const options = [{ text: i18n("Off"), value: "" }].concat(tracks.map(track => ({
                        text: track.label,
                        description: track.automatic ? i18n("Generated automatically") : "",
                        value: track.url
                    })));
                    const current = root.captionTrack?.url ?? "";
                    drawer.openWith(i18n("Captions"), options, current, value => {
                        root.captionTrack = tracks.find(track => track.url === value) ?? null;
                        // Remember the language for the next lectures
                        Preferences.captions = root.captionTrack
                            ? root.captionTrack.locale.split("_")[0] : "off";
                    });
                }
            },
            Kirigami.Action {
                text: i18n("Speed")
                icon.name: "speedometer"
                visible: !root.slidesOnly
                onTriggered: {
                    const options = [0.5, 0.75, 1, 1.25, 1.5, 1.75, 2].map(rate => ({
                        text: rate === 1 ? i18n("Normal")
                            : i18n("%1×", rate.toLocaleString(Qt.locale())),
                        value: rate
                    }));
                    drawer.openWith(i18n("Playback speed"), options, Preferences.playbackRate,
                                    value => Preferences.playbackRate = value);
                }
            },
            Kirigami.Action {
                text: i18n("Quality")
                icon.name: "video-television"
                visible: (root.lecture.sources ?? []).length > 1
                onTriggered: {
                    const options = root.lecture.sources.map(source => ({
                        text: source.label,
                        value: source.url
                    }));
                    drawer.openWith(i18n("Quality"), options, root.source, value => {
                        if (value === root.source) {
                            return;
                        }

                        root.seekOnLoad = root.position;
                        root.resumed = false;
                        root.source = value;
                        media.play();
                    });
                }
            },
            Kirigami.Action {
                text: root.completed ? i18n("Mark as not completed") : i18n("Mark as completed")
                icon.name: root.completed ? "edit-undo" : "checkmark"
                onTriggered: {
                    root.completionSent = !root.completed;
                    root.session.setCompleted(root.row, !root.completed);
                }
            }
        ]
    }

    // Quick keys: ▲ switches the view while the controls are hidden; S always does
    Shortcut {
        sequence: "Up"
        enabled: root.dual && !overlay.shown && overlay.activeFocus
        onActivated: root.cycleLayout()
    }

    Shortcut {
        sequence: "S"
        enabled: root.dual && root.activeFocus
        onActivated: root.cycleLayout()
    }

    Shortcut {
        sequences: ["Media Play", "Media Pause", "Toggle Media Play/Pause", "Space"]
        enabled: root.activeFocus && !root.slidesOnly
        onActivated: root.playing ? root.pause() : root.play()
    }

    Shortcut {
        sequence: "Media Next"
        enabled: root.activeFocus && root.hasNext
        onActivated: root.nextRequested()
    }

    Shortcut {
        sequence: "Media Previous"
        enabled: root.activeFocus && root.hasPrevious
        onActivated: root.previousRequested()
    }

    OptionsDrawer {
        id: drawer
        onClosed: overlay.forceActiveFocus()
    }

    BigscreenUI.Toast {
        id: toast
        z: 5
        timeout: 4000
        anchors.bottomMargin: overlay.shown ? Kirigami.Units.gridUnit * 13
                                            : Kirigami.Units.gridUnit * 3
    }

    // "Up next" with a countdown, as Udemy shows at the end of a lecture
    FocusScope {
        id: upNext

        property bool active: false
        property int remaining: 0

        function start(): void {
            remaining = 8;
            active = true;
            playNowButton.forceActiveFocus();
            countdown.restart();
        }

        function cancel(): void {
            countdown.stop();
            active = false;
            overlay.show();
            overlay.forceActiveFocus();
        }

        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Kirigami.Units.gridUnit * 3
        width: Kirigami.Units.gridUnit * 26
        height: upNextLayout.implicitHeight + Kirigami.Units.gridUnit * 3
        z: 6
        visible: active
        focus: active

        BigscreenUI.BackHandler.enabled: active
        BigscreenUI.BackHandler.onActivated: cancel()

        Timer {
            id: countdown
            interval: 1000
            repeat: true
            onTriggered: {
                if (--upNext.remaining <= 0) {
                    stop();
                    upNext.active = false;
                    root.nextRequested();
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Kirigami.Units.cornerRadius * 2
            color: Style.band
            border.color: Qt.alpha("white", 0.2)
        }

        ColumnLayout {
            id: upNextLayout

            anchors.fill: parent
            anchors.margins: Kirigami.Units.gridUnit * 1.5
            spacing: Kirigami.Units.gridUnit

            Text {
                text: i18n("Up next in %1", upNext.remaining)
                color: Style.purpleLight
                font.pixelSize: 18
                font.weight: Font.Bold
            }

            Text {
                Layout.fillWidth: true
                text: root.nextTitle
                color: "white"
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.pixelSize: 26
                font.weight: Font.Bold
            }

            RowLayout {
                spacing: Kirigami.Units.gridUnit

                PrimaryButton {
                    id: playNowButton
                    text: i18n("Play now")
                    icon.name: "media-playback-start"
                    onDark: true
                    onClicked: {
                        countdown.stop();
                        upNext.active = false;
                        root.nextRequested();
                    }

                    KeyNavigation.right: cancelButton
                }

                PrimaryButton {
                    id: cancelButton
                    text: i18n("Cancel")
                    secondary: true
                    onDark: true
                    onClicked: upNext.cancel()
                }
            }
        }
    }

    // Playback failed; Udemy's own player may still manage
    MessageView {
        anchors.fill: parent
        z: 7
        visible: root.errorText.length > 0
        focus: visible
        iconName: "dialog-error"
        text: i18n("This video could not be played")
        explanation: root.errorText
        primaryText: i18n("Open in Udemy's web player")
        onPrimaryClicked: root.webPlayerRequested()
        secondaryText: root.hasNext ? i18n("Next lecture") : ""
        onSecondaryClicked: root.nextRequested()

        onVisibleChanged: {
            if (visible) {
                forceActiveFocus();
            }
        }
    }
}
