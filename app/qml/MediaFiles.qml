// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma Singleton

import QtQml

QtObject {
    id: root

    readonly property list<string> videoSuffixes: [
        "264", "3g2", "3gp", "3mm", "3p2", "avchd", "avi", "divx", "dvm", "dvr", "dvx", "f4v", "flv", "m2ts", "m2v", "m4e", "m4p", "m4u", "m4v", "mj2", "mjp", "mk3d", "mkv", "mov", "mp2", "mp4", "mp4v", "mpe", "mpeg", "mpg", "mpg2", "mpv", "mqv", "mts", "ogv", "qt", "ts", "vob", "vro", "webm", "wmv", "xvid"
    ]

    readonly property list<string> audioSuffixes: [
        "aac", "aif", "aiff", "alac", "ape", "flac", "m4a", "mka", "mp3", "mpc", "oga", "ogg", "opus", "wav", "wma", "wv"
    ]

    readonly property list<string> videoFilters: root.__filtersFor(videoSuffixes)
    readonly property list<string> audioFilters: root.__filtersFor(audioSuffixes)

    function __filtersFor(suffixes: list<string>): list<string> {
        const filters = [];
        for (const suffix of suffixes) {
            filters.push("*." + suffix, "*." + suffix.toUpperCase());
        }
        return filters;
    }

    function suffix(url: url): string {
        const name = fileName(url);
        const dot = name.lastIndexOf(".");
        return dot > 0 ? name.slice(dot + 1).toLowerCase() : "";
    }

    function isAudio(url: url): bool {
        return audioSuffixes.includes(suffix(url));
    }

    function iconName(url: url): string {
        return isAudio(url) ? "audio-x-generic" : "video-x-generic";
    }

    // The file name without its folder
    function fileName(url: url): string {
        const path = decodeURIComponent(url.toString());
        return path.slice(path.lastIndexOf("/") + 1);
    }

    // The file name without its folder or suffix, as a title
    function title(url: url): string {
        const name = fileName(url);
        const dot = name.lastIndexOf(".");
        return dot > 0 ? name.slice(0, dot) : name;
    }

    // The path of a local folder or file, for showing to the user
    function displayPath(url: url): string {
        return decodeURIComponent(url.toString().replace(/^file:\/\//, ""));
    }

    function thumbnail(url: url): string {
        const encoded = encodeURIComponent(url.toString());
        let hex = "";
        for (let i = 0; i < encoded.length; ++i) {
            hex += encoded.charCodeAt(i).toString(16).padStart(2, "0");
        }
        return "image://thumbnail/" + hex;
    }

    function formatTime(milliseconds: real): string {
        const total = Math.max(0, Math.round(milliseconds / 1000));
        const hours = Math.floor(total / 3600);
        const minutes = Math.floor((total % 3600) / 60);
        const seconds = String(total % 60).padStart(2, "0");
        return hours > 0 ? `${hours}:${String(minutes).padStart(2, "0")}:${seconds}` : `${minutes}:${seconds}`;
    }

    function formatSize(bytes: real): string {
        const units = [i18nc("@info bytes", "B"), i18nc("@info kilobytes", "KB"), i18nc("@info megabytes", "MB"), i18nc("@info gigabytes", "GB")];
        let size = bytes;
        let unit = 0;
        while (size >= 1000 && unit < units.length - 1) {
            size /= 1000;
            ++unit;
        }
        return i18nc("@info file size, e.g. 1.2 GB", "%1 %2", size.toFixed(unit > 1 ? 1 : 0), units[unit]);
    }

    function formatRemaining(position: real, duration: real): string {
        const minutes = Math.max(1, Math.round((duration - position) / 60000));
        return i18ncp("@info time left to watch", "%1 min left", "%1 min left", minutes);
    }
}
