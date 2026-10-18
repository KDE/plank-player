// SPDX-FileCopyrightText: 2021 Aditya Mehra <aix.m@outlook.com>
// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

BigscreenUI.ApplicationWindow {
    id: root

    required property url initialUrl

    width: 1280
    height: 720
    minimumWidth: 500
    minimumHeight: 500
    visible: true
    title: i18n("Plank Player")

    function play(url: url, queue: var): void {
        pageStack.push(playerPage, {
            source: url,
            queue: queue && queue.length > 0 ? queue : [url]
        });
    }

    // Plays from the beginning, not where it was left
    function playFromStart(url: url): void {
        pageStack.push(playerPage, {
            source: url,
            queue: [url],
            startOver: true
        });
    }

    // Shows the library at the folder
    function browse(folder: url): void {
        libraryPage.openFolder(folder);
        navigationBar.currentIndex = pageActions.indexOf(libraryAction);
        showPage(libraryPage);
        libraryPage.focusContent();
    }

    readonly property list<T.Action> pageActions: [
        Kirigami.Action {
            text: i18n("Home")
            icon.name: "go-home"
            onTriggered: root.showPage(homePage)
        },
        Kirigami.Action {
            id: libraryAction
            text: i18n("Library")
            icon.name: "folder-videos"
            onTriggered: root.showPage(libraryPage)
        },
        Kirigami.Action {
            text: i18n("Settings")
            icon.name: "settings-configure"
            onTriggered: root.showPage(settingsPage)
        }
    ]

    readonly property list<Item> pages: [
        HomePage {
            id: homePage
        },
        LibraryPage {
            id: libraryPage
        },
        SettingsPage {
            id: settingsPage
        }
    ]

    initialPage: homePage

    navigationBar: BigscreenUI.NavigationBar {
        id: navigationBar

        actions: root.pageActions

        leading: RowLayout {
            spacing: Kirigami.Units.largeSpacing * 2

            Kirigami.Icon {
                implicitWidth: Kirigami.Units.iconSizes.medium
                implicitHeight: Kirigami.Units.iconSizes.medium
                source: "qrc:/org.kde.plank-player.svg"
            }
            BigscreenUI.Label {
                text: i18n("Plank Player")
                type: BigscreenUI.Label.Heading
                font.weight: Font.Light
            }
        }
    }

    Component {
        id: playerPage
        PlayerPage {}
    }

    Component.onCompleted: {
        // Play media immediately if given initial URL
        if (initialUrl.toString().length > 0) {
            play(initialUrl, [initialUrl]);
        }
    }
}
