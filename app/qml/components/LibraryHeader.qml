// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

FocusScope {
    id: root

    property alias place: breadcrumbs.rootName
    property alias placeUrl: breadcrumbs.rootUrl
    property alias placeIconName: breadcrumbs.rootIconName
    property alias folder: breadcrumbs.folder

    property alias filters: filterChipBar.model
    property int filterIndex: 0

    readonly property alias breadcrumbs: breadcrumbs

    signal placesRequested()
    signal filesRequested()
    signal folderClicked(url folder)
    signal filterActivated(int index)

    implicitHeight: layout.implicitHeight

    GridLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        // The type chips go under the breadcrumbs when there isn't room for both
        columns: width >= filterChipBar.contentWidth + columnSpacing + Kirigami.Units.gridUnit * 10 ? 2 : 1
        columnSpacing: Kirigami.Units.gridUnit * 2
        rowSpacing: Kirigami.Units.largeSpacing * 2

        Breadcrumbs {
            id: breadcrumbs

            Layout.fillWidth: true
            focus: true

            KeyNavigation.priority: KeyNavigation.AfterItem
            KeyNavigation.right: filterChipBar
            Keys.onDownPressed: {
                if (layout.columns === 1) {
                    filterChipBar.forceActiveFocus();
                } else {
                    root.filesRequested();
                }
            }

            onRootClicked: root.placesRequested()
            onFolderClicked: folder => root.folderClicked(folder)
        }

        BigscreenUI.ChipBar {
            id: filterChipBar

            Layout.preferredWidth: contentWidth

            KeyNavigation.priority: KeyNavigation.AfterItem
            KeyNavigation.left: breadcrumbs
            Keys.onUpPressed: event => {
                event.accepted = layout.columns === 1;
                if (event.accepted) {
                    breadcrumbs.forceActiveFocus();
                }
            }
            Keys.onDownPressed: root.filesRequested()

            onActivated: index => root.filterActivated(index)

            Binding on selectedIndex {
                value: root.filterIndex
            }
        }
    }
}
