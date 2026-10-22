// SPDX-FileCopyrightText: 2021 Aditya Mehra <aix.m@outlook.com>
// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import QtCore

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI
import org.kde.plank.player

BigscreenUI.Page {
    id: root

    readonly property T.ApplicationWindow window: T.ApplicationWindow.window

    readonly property var places: [
        { name: i18n("Videos"), icon: "folder-videos", url: StandardPaths.writableLocation(StandardPaths.MoviesLocation) },
        { name: i18n("Music"), icon: "folder-music", url: StandardPaths.writableLocation(StandardPaths.MusicLocation) },
        { name: i18n("Downloads"), icon: "folder-download", url: StandardPaths.writableLocation(StandardPaths.DownloadLocation) },
        { name: i18n("Home"), icon: "user-home", url: StandardPaths.writableLocation(StandardPaths.HomeLocation) },
        { name: i18n("Computer"), icon: "computer", url: "file:///" }
    ]

    readonly property var filters: [
        { name: i18n("All"), nameFilters: [...MediaFiles.videoFilters, ...MediaFiles.audioFilters] },
        { name: i18n("Videos"), nameFilters: MediaFiles.videoFilters },
        { name: i18n("Music"), nameFilters: MediaFiles.audioFilters }
    ]

    property int placeIndex: 0
    readonly property url placeUrl: places[placeIndex].url

    property int filterIndex: 0

    readonly property bool atPlace: folderModel.folder.toString() === placeUrl.toString()

    readonly property Item breadcrumbs: grid.headerItem?.breadcrumbs ?? null

    function openFolder(folder: url): void {
        const path = folder.toString();
        let best = places.length - 1;
        for (let i = 0; i < places.length; ++i) {
            const place = places[i].url.toString();
            if ((path === place || path.startsWith(place + "/")) && place.length > places[best].url.toString().length) {
                best = i;
            }
        }
        placeIndex = best;
        showFolder(folder);
    }

    function showFolder(folder: url): void {
        folderModel.folder = folder;
        grid.currentIndex = 0;
    }

    function goUp(): void {
        pendingFocusFolder = folderModel.folder.toString();
        folderModel.folder = folderModel.parentFolder;
    }

    property string pendingFocusFolder

    function focusFiles(): void {
        if (grid.count > 0) {
            grid.currentIndex = Math.max(grid.currentIndex, 0);
            grid.currentItem.forceActiveFocus();
        } else {
            (atPlace ? breadcrumbs : emptyMessage).forceActiveFocus();
        }
    }

    function focusContent(): void {
        focusFilesWhenLoaded = grid.count === 0;
        focusFiles();
    }

    property bool focusFilesWhenLoaded: false

    function playableFiles(): var {
        const files = [];
        for (let i = 0; i < folderModel.count; ++i) {
            if (!folderModel.get(i, "fileIsDir")) {
                files.push(folderModel.get(i, "fileUrl"));
            }
        }
        return files;
    }

    background: BigscreenUI.AmbientBackground {}

    readonly property bool __filesFocused: grid.activeFocus && !(grid.headerItem?.activeFocus ?? false)

    BigscreenUI.BackHandler.enabled: visible && __filesFocused
    BigscreenUI.BackHandler.onActivated: breadcrumbs.forceActiveFocus()

    function __moveFocusOffGrid(): void {
        if (Window.activeFocusItem === grid && !folderModel.loading) {
            focusFiles();
        }
    }

    Connections {
        target: root.Window.window
        function onActiveFocusItemChanged(): void {
            Qt.callLater(root.__moveFocusOffGrid);
        }
    }

    MediaFolderModel {
        id: folderModel

        folder: root.placeUrl
        nameFilters: root.filters[root.filterIndex].nameFilters

        onLoadingChanged: {
            if (loading) {
                return;
            }
            if (root.focusFilesWhenLoaded) {
                root.focusFilesWhenLoaded = false;
                root.focusFiles();
            }
            root.__moveFocusOffGrid();

            const index = indexOf(root.pendingFocusFolder);
            root.pendingFocusFolder = "";
            if (index >= 0) {
                grid.currentIndex = index;
                grid.positionViewAtIndex(index, GridView.Contain);
            }
        }
    }

    BigscreenUI.MediaGrid {
        id: grid

        anchors.fill: parent
        model: folderModel

        onCurrentIndexChanged: {
            if (root.__filesFocused) {
                Qt.callLater(() => {
                    grid.forceLayout();
                    grid.scrollToCurrent();
                });
            }
        }

        Keys.priority: Keys.AfterItem
        Keys.onUpPressed: event => {
            event.accepted = !headerItem.activeFocus;
            if (event.accepted) {
                root.breadcrumbs.forceActiveFocus();
            }
        }

        header: LibraryHeader {
            width: grid.width - grid.leftMargin - grid.rightMargin - grid.columnSpacing
            height: implicitHeight + Kirigami.Units.gridUnit * 2

            place: root.places[root.placeIndex].name
            placeUrl: root.placeUrl
            placeIconName: root.places[root.placeIndex].icon
            folder: folderModel.folder
            filters: root.filters.map(filter => filter.name)
            filterIndex: root.filterIndex

            onPlacesRequested: placesDialog.open()
            onFolderClicked: folder => root.showFolder(folder)
            onFilterActivated: index => {
                root.filterIndex = index;
                grid.currentIndex = 0;
            }
            onFilesRequested: root.focusFiles()
        }

        delegate: FileCard {
            onClicked: {
                if (fileIsDir) {
                    root.showFolder(fileUrl);
                } else {
                    root.window.play(fileUrl, root.playableFiles());
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        anchors.topMargin: grid.topMargin + (grid.headerItem?.height ?? 0)
        visible: grid.count === 0 && !folderModel.loading

        BigscreenUI.PlaceholderMessage {
            id: emptyMessage

            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.max(0, (parent.height - height) / 2)
            width: Math.min(parent.width - root.contentMargins.left - root.contentMargins.right, implicitWidth)

            iconName: "folder-open"
            text: i18n("Nothing to play here")
            explanation: i18n("Videos, music and folders in %1 will appear here.", MediaFiles.displayPath(folderModel.folder))
            helpfulAction: Kirigami.Action {
                text: i18n("Go up")
                icon.name: "go-up"
                visible: !root.atPlace
                onTriggered: root.goUp()
            }

            Keys.onUpPressed: root.breadcrumbs.forceActiveFocus()
        }
    }

    LocationsDialog {
        id: placesDialog

        places: root.places
        currentIndex: root.placeIndex
        currentFolder: folderModel.folder

        onFolderPicked: folder => {
            root.openFolder(folder);
            root.focusContent();
        }
        onDismissed: root.breadcrumbs.forceActiveFocus()
    }
}
