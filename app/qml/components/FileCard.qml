// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

import org.kde.bigscreen.ui as BigscreenUI
import org.kde.plank.player

BigscreenUI.MediaCard {
    id: root

    required property int index
    required property url fileUrl
    required property string fileName
    required property string fileSuffix
    required property bool fileIsDir
    required property real fileSize

    artworkWidth: GridView.view.cardWidth
    artworkHeight: GridView.view.artworkHeight

    source: fileIsDir ? "" : MediaFiles.thumbnail(fileUrl)
    placeholderIconName: fileIsDir ? "folder" : MediaFiles.iconName(fileUrl)
    text: fileIsDir ? fileName : MediaFiles.title(fileUrl)
    subtitle: fileIsDir ? i18n("Folder") : i18nc("@info file type and size", "%1 · %2", fileSuffix.toUpperCase(), MediaFiles.formatSize(fileSize))
    progress: fileIsDir ? -1 : History.progress(fileUrl)

    Connections {
        target: History
        enabled: !root.fileIsDir

        function onEntryChanged(url: url): void {
            if (url.toString() === root.fileUrl.toString()) {
                root.progress = History.progress(url);
            }
        }
    }
}
