// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import QtMultimedia

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI
import org.kde.plank.player

BigscreenUI.ContextDrawer {
    id: root

    enum Section {
        AudioTrack,
        Subtitles,
        Speed,
        Picture
    }

    required property MediaPlayer player
    required property VideoOutput videoOutput

    property int section: PlaybackOptionsDrawer.AudioTrack

    property Item returnFocusItem: null

    function openSection(section: int): void {
        root.section = section;
        open();
    }

    function trackName(track: var, index: int): string {
        const title = track.stringValue(MediaMetaData.Title);
        const language = track.stringValue(MediaMetaData.Language);
        if (title.length > 0 && language.length > 0 && title !== language) {
            return i18nc("@item track title and language", "%1 (%2)", title, language);
        }
        return title || language || i18nc("@item numbered track", "Track %1", index + 1);
    }

    readonly property var options: {
        switch (section) {
        case PlaybackOptionsDrawer.AudioTrack:
            return player.audioTracks.map((track, index) => ({ text: trackName(track, index), value: index }));
        case PlaybackOptionsDrawer.Subtitles:
            return [
                { text: i18nc("@item no subtitles", "Off"), value: -1 },
                ...player.subtitleTracks.map((track, index) => ({ text: trackName(track, index), value: index }))
            ];
        case PlaybackOptionsDrawer.Speed:
            return [0.5, 0.75, 1, 1.25, 1.5, 2].map(rate => ({
                text: rate === 1 ? i18nc("@item playback speed", "Normal") : i18nc("@item playback speed", "%1×", rate),
                value: rate
            }));
        case PlaybackOptionsDrawer.Picture:
            return [
                { text: i18nc("@item video fill mode", "Fit to screen"), value: VideoOutput.PreserveAspectFit },
                { text: i18nc("@item video fill mode", "Fill screen"), value: VideoOutput.PreserveAspectCrop },
                { text: i18nc("@item video fill mode", "Stretch"), value: VideoOutput.Stretch }
            ];
        }
        return [];
    }

    readonly property var currentValue: {
        switch (section) {
        case PlaybackOptionsDrawer.AudioTrack:
            return player.activeAudioTrack;
        case PlaybackOptionsDrawer.Subtitles:
            return player.activeSubtitleTrack;
        case PlaybackOptionsDrawer.Speed:
            return player.playbackRate;
        case PlaybackOptionsDrawer.Picture:
            return videoOutput.fillMode;
        }
        return undefined;
    }

    readonly property int currentOptionIndex: options.findIndex(option => option.value === currentValue)

    function apply(value: var): void {
        switch (section) {
        case PlaybackOptionsDrawer.AudioTrack:
            player.activeAudioTrack = value;
            PlaybackSettings.save(player.source, { audioTrack: value });
            break;
        case PlaybackOptionsDrawer.Subtitles:
            player.activeSubtitleTrack = value;
            PlaybackSettings.save(player.source, { subtitleTrack: value });
            break;
        case PlaybackOptionsDrawer.Speed:
            player.playbackRate = value;
            PlaybackSettings.save(player.source, { playbackRate: value });
            break;
        case PlaybackOptionsDrawer.Picture:
            videoOutput.fillMode = value;
            PlaybackSettings.save(player.source, { fillMode: value });
            break;
        }
    }

    onAboutToShow: {
        returnFocusItem = videoOutput.Window.activeFocusItem;
        optionList.currentIndex = Math.max(0, currentOptionIndex);
    }
    onAboutToHide: returnFocusItem?.forceActiveFocus()

    openFocusItem: optionList

    header: BigscreenUI.ContextDrawerHeader {
        title: {
            switch (root.section) {
            case PlaybackOptionsDrawer.AudioTrack: return i18n("Audio track");
            case PlaybackOptionsDrawer.Subtitles: return i18n("Subtitles");
            case PlaybackOptionsDrawer.Speed: return i18n("Playback speed");
            case PlaybackOptionsDrawer.Picture: return i18n("Picture");
            }
            return "";
        }
        iconSource: {
            switch (root.section) {
            case PlaybackOptionsDrawer.AudioTrack: return "audio-volume-high";
            case PlaybackOptionsDrawer.Subtitles: return "media-view-subtitles-symbolic";
            case PlaybackOptionsDrawer.Speed: return "speedometer";
            case PlaybackOptionsDrawer.Picture: return "zoom-fit-best";
            }
            return "";
        }
    }

    content: ListView {
        id: optionList

        clip: true
        spacing: Kirigami.Units.smallSpacing
        keyNavigationEnabled: true
        model: root.options

        delegate: BigscreenUI.ButtonDelegate {
            required property var modelData
            required property int index

            width: ListView.view.width
            text: modelData.text
            textItem.wrapMode: Text.Wrap
            textItem.maximumLineCount: root.section === PlaybackOptionsDrawer.AudioTrack || root.section === PlaybackOptionsDrawer.Subtitles ? 2 : 1
            focus: ListView.isCurrentItem

            trailing: Kirigami.Icon {
                implicitWidth: Kirigami.Units.iconSizes.medium
                implicitHeight: Kirigami.Units.iconSizes.medium
                source: "checkmark"
                visible: index === root.currentOptionIndex
            }

            onClicked: {
                root.apply(modelData.value);
                root.close();
            }
        }
    }
}
