// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import QtCore

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

BigscreenUI.Page {
    id: root

    readonly property T.ApplicationWindow window: T.ApplicationWindow.window

    readonly property var places: [
        { name: i18n("Videos"), icon: "folder-videos", url: StandardPaths.writableLocation(StandardPaths.MoviesLocation) },
        { name: i18n("Music"), icon: "folder-music", url: StandardPaths.writableLocation(StandardPaths.MusicLocation) },
        { name: i18n("Downloads"), icon: "folder-download", url: StandardPaths.writableLocation(StandardPaths.DownloadLocation) },
        { name: i18n("Home"), icon: "user-home", url: StandardPaths.writableLocation(StandardPaths.HomeLocation) }
    ]

    readonly property real cardScale: Math.max(0.6, Math.min(1, width / 1600))

    readonly property var featured: History.lastUnfinished ?? null

    readonly property url backdropSource: {
        if (rails.currentIndex > 0) {
            return rails.currentItem?.currentItem?.source ?? "";
        }
        return featured ? MediaFiles.thumbnail(featured.url) : "";
    }

    function metadataFor(entry: historyEntry): list<string> {
        const suffix = MediaFiles.suffix(entry.url).toUpperCase();
        if (entry.finished || entry.position <= 0) {
            return [MediaFiles.formatTime(entry.duration), suffix];
        }
        return [MediaFiles.formatRemaining(entry.position, entry.duration), suffix];
    }

    function openDetails(entry: historyEntry, rail: string): void {
        window.pageStack.push(detailsPage, { entry: entry, rail: rail });
    }

    background: BigscreenUI.BackdropImage {
        useAmbientFallback: true
        source: root.backdropSource
    }

    BigscreenUI.RailView {
        id: rails

        anchors.fill: parent
        anchors.topMargin: root.contentMargins.top - topMargin
        bottomMargin: root.contentMargins.bottom
        focus: true

        FocusScope {
            implicitHeight: hero.implicitHeight

            BigscreenUI.HeroBanner {
                id: hero

                x: root.contentMargins.left
                width: Math.min(parent.width - root.contentMargins.left - root.contentMargins.right,
                                Math.max(Math.round(parent.width * 0.55), Kirigami.Units.gridUnit * 24))

                overline: root.featured ? i18n("Continue watching") : i18n("Welcome")
                title: root.featured ? root.featured.title : i18n("Play your media")
                metadata: root.featured ? root.metadataFor(root.featured) : []

                BigscreenUI.Button {
                    focus: true
                    text: root.featured ? i18n("Resume") : i18n("Browse videos")
                    icon.name: root.featured ? "media-playback-start" : "folder-videos"
                    onClicked: {
                        if (root.featured) {
                            root.window.play(root.featured.url, []);
                        } else {
                            root.window.browse(root.places[0].url);
                        }
                    }
                }
                BigscreenUI.Button {
                    text: root.featured ? i18n("Start over") : i18n("Browse music")
                    icon.name: root.featured ? "media-playlist-repeat" : "folder-music"
                    onClicked: {
                        if (root.featured) {
                            root.window.playFromStart(root.featured.url);
                        } else {
                            root.window.browse(root.places[1].url);
                        }
                    }
                }
            }
        }

        BigscreenUI.ContentRail {
            id: continueRail
            title: i18n("Continue watching")
            model: HistoryFilterModel {
                sourceModel: History
                filter: HistoryFilterModel.Unfinished
            }
            delegate: BigscreenUI.MediaCard {
                required property historyEntry entry

                artworkWidth: Math.round(Kirigami.Units.gridUnit * 20 * root.cardScale)
                artworkHeight: artworkWidth * 9 / 16
                source: MediaFiles.thumbnail(entry.url)
                placeholderIconName: MediaFiles.iconName(entry.url)
                text: entry.title
                subtitle: MediaFiles.formatRemaining(entry.position, entry.duration)
                progress: entry.progress

                onClicked: root.window.play(entry.url, [])
                onPressAndHold: root.openDetails(entry, continueRail.title)
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Menu || event.key === Qt.Key_Info) {
                        root.openDetails(entry, continueRail.title);
                        event.accepted = true;
                    }
                }
            }
        }

        BigscreenUI.ContentRail {
            id: recentRail
            title: i18n("Recently played")
            model: HistoryFilterModel {
                sourceModel: History
                filter: HistoryFilterModel.Finished
            }
            delegate: BigscreenUI.MediaCard {
                required property historyEntry entry

                artworkWidth: Math.round(Kirigami.Units.gridUnit * 16 * root.cardScale)
                artworkHeight: artworkWidth * 9 / 16
                source: MediaFiles.thumbnail(entry.url)
                placeholderIconName: MediaFiles.iconName(entry.url)
                text: entry.title
                subtitle: MediaFiles.formatTime(entry.duration)
                watched: true

                onClicked: root.window.play(entry.url, [])
                // Clicking plays, so Menu, Info or a long press shows more about it
                onPressAndHold: root.openDetails(entry, recentRail.title)
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Menu || event.key === Qt.Key_Info) {
                        root.openDetails(entry, recentRail.title);
                        event.accepted = true;
                    }
                }
            }
        }

        BigscreenUI.ContentRail {
            title: i18n("Folders")
            model: root.places
            delegate: BigscreenUI.MediaCard {
                required property var modelData

                artworkWidth: Math.round(Kirigami.Units.gridUnit * 14 * root.cardScale)
                artworkHeight: artworkWidth * 9 / 16
                placeholderIconName: modelData.icon
                text: modelData.name

                onClicked: root.window.browse(modelData.url)
            }
        }
    }

    Component {
        id: detailsPage

        DetailsPage {
            id: details

            required property historyEntry entry
            required property string rail

            readonly property bool resumable: entry.position > 0 && !entry.finished

            source: MediaFiles.thumbnail(entry.url)
            overline: rail
            title: entry.title
            metadata: root.metadataFor(entry)
            description: MediaFiles.displayPath(entry.url)

            BigscreenUI.Button {
                focus: true
                text: details.resumable ? i18n("Resume") : i18n("Play")
                icon.name: "media-playback-start"
                onClicked: root.window.play(details.entry.url, [])
            }
            BigscreenUI.Button {
                visible: details.resumable
                text: i18n("Start over")
                icon.name: "media-playlist-repeat"
                onClicked: root.window.playFromStart(details.entry.url)
            }
            BigscreenUI.Button {
                text: i18n("Remove from history")
                icon.name: "edit-delete-remove"
                onClicked: {
                    History.remove(details.entry.url);
                    root.window.pageStack.pop();
                }
            }
        }
    }
}
