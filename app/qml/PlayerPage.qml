// SPDX-FileCopyrightText: 2021 Aditya Mehra <aix.m@outlook.com>
// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import QtMultimedia

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI
import org.kde.plank.player

BigscreenUI.Page {
    id: root

    property url source

    property var queue: [source]

    // Start the first item from the beginning
    property bool startOver: false

    readonly property int queueIndex: queue.findIndex(url => url.toString() === source.toString())
    readonly property bool hasPrevious: queueIndex > 0
    readonly property bool hasNext: queueIndex >= 0 && queueIndex < queue.length - 1

    readonly property bool loaded: player.mediaStatus !== MediaPlayer.NoMedia && player.mediaStatus !== MediaPlayer.LoadingMedia
    readonly property bool failed: player.error !== MediaPlayer.NoError || player.mediaStatus === MediaPlayer.InvalidMedia
    readonly property bool audioOnly: loaded && !player.hasVideo

    readonly property string mediaTitle: player.metaData.stringValue(MediaMetaData.Title) || MediaFiles.title(source)
    readonly property string artist: player.metaData.stringValue(MediaMetaData.ContributingArtist) || player.metaData.stringValue(MediaMetaData.AlbumArtist)

    // Whether playback picked up from where it was left
    property bool __resumed: false

    function playAt(index: int): void {
        saveProgress();
        startOver = false;
        source = queue[index];
    }

    function saveProgress(): void {
        if (player.duration > 0) {
            const position = player.mediaStatus === MediaPlayer.EndOfMedia ? player.duration : player.position;
            History.update(source, mediaTitle, position, player.duration);
        }
    }

    function close(): void {
        saveProgress();
        T.StackView.view.pop();
    }

    Component.onCompleted: player.play()

    Connections {
        target: root.T.ApplicationWindow.window
        function onClosing(): void {
            root.saveProgress();
        }
    }

    BigscreenUI.BackHandler.enabled: visible
    BigscreenUI.BackHandler.onActivated: {
        // Hide the controls first, then leave the player
        if (overlay.shown && player.playing) {
            overlay.hide();
        } else {
            root.close();
        }
    }

    background: Rectangle { color: "black" }

    MediaPlayer {
        id: player

        source: root.source
        videoOutput: videoOutput
        audioOutput: AudioOutput {
            id: audioOutput
        }

        onSourceChanged: {
            root.__resumed = false;
            play();
        }

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia && !root.__resumed) {
                root.__resumed = true;

                // Load saved settings for media
                const settings = PlaybackSettings.load(root.source);
                playbackRate = settings.playbackRate;
                videoOutput.fillMode = settings.fillMode;
                if (settings.audioTrack >= 0 && settings.audioTrack < audioTracks.length) {
                    activeAudioTrack = settings.audioTrack;
                }
                if (settings.subtitleTrack >= -1 && settings.subtitleTrack < subtitleTracks.length) {
                    activeSubtitleTrack = settings.subtitleTrack;
                }

                const position = root.startOver ? 0 : History.resumePosition(root.source);
                // Not worth resuming right at the start
                if (position > 10000 && seekable) {
                    setPosition(position);
                    toast.show(i18n("Resuming from %1", MediaFiles.formatTime(position)), "media-playback-start");
                }
            } else if (mediaStatus === MediaPlayer.EndOfMedia) {
                if (root.hasNext) {
                    root.playAt(root.queueIndex + 1);
                } else {
                    root.close();
                }
            }
        }
    }

    // Save progress every 10 seconds
    Timer {
        interval: 10000
        repeat: true
        running: player.playing
        onTriggered: root.saveProgress()
    }

    VideoOutput {
        id: videoOutput

        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectFit
        visible: !root.audioOnly
    }

    // Audio files show their cover art
    Loader {
        anchors.fill: parent
        active: root.audioOnly
        opacity: status === Loader.Ready ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Kirigami.Units.veryLongDuration
            }
        }

        sourceComponent: Item {
            AudioBackground {
                anchors.fill: parent
                source: MediaFiles.thumbnail(root.source)
            }

            AudioCover {
                anchors.fill: parent
                source: MediaFiles.thumbnail(root.source)
                playing: player.playing
                title: root.artist.length > 0 ? i18nc("@info song title and artist", "%1 — %2", root.mediaTitle, root.artist) : root.mediaTitle
                titleVisible: !overlay.shown
            }
        }
    }

    Item {
        anchors.fill: parent

        // Tapping the picture shows or hides the controls
        TapHandler {
            onTapped: overlay.shown ? overlay.hide() : overlay.show()
            onDoubleTapped: player.playing ? player.pause() : player.play()
        }
    }

    BigscreenUI.PlaceholderMessage {
        id: errorMessage

        anchors.centerIn: parent
        width: Math.min(parent.width - root.contentMargins.left - root.contentMargins.right, implicitWidth)
        visible: root.failed

        Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
        Kirigami.Theme.inherit: false

        iconName: "dialog-error-symbolic"
        text: i18n("This file can't be played")
        explanation: player.errorString.length > 0 ? player.errorString : MediaFiles.displayPath(root.source)
        helpfulAction: Kirigami.Action {
            text: root.hasNext ? i18n("Play next") : i18n("Go back")
            icon.name: root.hasNext ? "media-skip-forward" : "go-previous"
            onTriggered: root.hasNext ? root.playAt(root.queueIndex + 1) : root.close()
        }
        onVisibleChanged: if (visible) forceActiveFocus()
    }

    BigscreenUI.PlayerOverlay {
        id: overlay

        anchors.fill: parent
        focus: true
        visible: !root.failed

        Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
        Kirigami.Theme.inherit: false

        overline: root.queue.length > 1 ? i18nc("@info position in the play queue", "%1 of %2", root.queueIndex + 1, root.queue.length) : ""
        title: root.mediaTitle
        metadata: {
            const parts = [];
            if (root.artist.length > 0) {
                parts.push(root.artist);
            }
            const resolution = player.metaData.value(MediaMetaData.Resolution);
            if (resolution && resolution.height > 0) {
                parts.push(i18nc("@info video height, such as 1080p", "%1p", resolution.height));
            }
            parts.push(MediaFiles.suffix(root.source).toUpperCase());
            if (player.playbackRate !== 1) {
                parts.push(i18nc("@info playback speed", "%1×", player.playbackRate));
            }
            return parts;
        }

        position: player.position
        duration: player.duration
        playing: player.playing
        busy: !root.failed && (player.mediaStatus === MediaPlayer.LoadingMedia || player.mediaStatus === MediaPlayer.BufferingMedia || player.mediaStatus === MediaPlayer.StalledMedia)
        hasPrevious: root.hasPrevious
        hasNext: root.hasNext

        onPlayPauseRequested: player.playing ? player.pause() : player.play()
        onSeekRequested: position => player.setPosition(position)
        onPreviousRequested: {
            if (player.position > 5000) {
                player.setPosition(0);
            } else {
                root.playAt(root.queueIndex - 1);
            }
        }
        onNextRequested: root.playAt(root.queueIndex + 1)

        actions: [
            Kirigami.Action {
                text: i18n("Audio track")
                icon.name: "audio-volume-high"
                visible: player.audioTracks.length > 1
                onTriggered: optionsDrawer.openSection(PlaybackOptionsDrawer.AudioTrack)
            },
            Kirigami.Action {
                text: i18n("Subtitles")
                icon.name: "media-view-subtitles-symbolic"
                visible: player.subtitleTracks.length > 0
                onTriggered: optionsDrawer.openSection(PlaybackOptionsDrawer.Subtitles)
            },
            Kirigami.Action {
                text: i18n("Playback speed")
                icon.name: "speedometer"
                onTriggered: optionsDrawer.openSection(PlaybackOptionsDrawer.Speed)
            },
            Kirigami.Action {
                text: i18n("Picture")
                icon.name: "zoom-fit-best"
                visible: !root.audioOnly
                onTriggered: optionsDrawer.openSection(PlaybackOptionsDrawer.Picture)
            }
        ]
    }

    PlaybackOptionsDrawer {
        id: optionsDrawer
        player: player
        videoOutput: videoOutput
    }

    BigscreenUI.Toast {
        id: toast
    }

    Shortcut {
        sequences: ["Media Play", "Toggle Media Play/Pause"]
        enabled: root.visible
        onActivated: player.playing ? player.pause() : player.play()
    }
    Shortcut {
        sequence: "Media Pause"
        enabled: root.visible
        onActivated: player.pause()
    }
    Shortcut {
        sequence: "Media Stop"
        enabled: root.visible
        onActivated: root.close()
    }
    Shortcut {
        sequence: "Media Next"
        enabled: root.visible && root.hasNext
        onActivated: root.playAt(root.queueIndex + 1)
    }
    Shortcut {
        sequence: "Media Previous"
        enabled: root.visible && root.hasPrevious
        onActivated: root.playAt(root.queueIndex - 1)
    }
}
