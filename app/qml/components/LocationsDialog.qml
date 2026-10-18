// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI
import org.kde.plank.player

// The places to browse or a folder to type in
BigscreenUI.Dialog {
    id: root

    property var places: []
    property int currentIndex: 0
    property url currentFolder

    signal folderPicked(url folder)
    signal dismissed()

    property url __pickedFolder
    property bool __typingPath: false

    function __pick(folder: url): void {
        __pickedFolder = folder;
        close();
    }

    function __typePath(): void {
        pathField.text = MediaFiles.displayPath(currentFolder);
        pathError.visible = false;
        __typingPath = true;
        pathField.forceActiveFocus();
        pathField.selectAll();
    }

    title: __typingPath ? i18nc("@title:window", "Go to Folder") : i18nc("@title:window", "Locations")
    openFocusItem: placesList

    BigscreenUI.BackHandler.enabled: visible && !__typingPath

    onAboutToShow: {
        placesList.currentIndex = currentIndex;
        __pickedFolder = "";
        __typingPath = false;
    }
    onClosed: {
        if (__pickedFolder.toString().length > 0) {
            folderPicked(__pickedFolder);
        } else {
            dismissed();
        }
    }

    footer: null

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Kirigami.Units.smallSpacing

        ListView {
            id: placesList

            Layout.fillWidth: true
            implicitHeight: Math.min(contentHeight, Math.round((root.parent?.height ?? 0) * 0.6))
            visible: !root.__typingPath

            clip: true
            spacing: Kirigami.Units.smallSpacing
            keyNavigationEnabled: true
            boundsBehavior: Flickable.StopAtBounds
            highlightRangeMode: ListView.ApplyRange
            preferredHighlightBegin: 0
            preferredHighlightEnd: height
            highlightMoveDuration: Kirigami.Units.longDuration

            model: [...root.places, { name: i18n("Type a folder…"), icon: "folder-open" }]

            delegate: BigscreenUI.ButtonDelegate {
                required property int index
                required property var modelData

                readonly property bool isPlace: index < root.places.length

                width: ListView.view.width
                text: modelData.name
                description: isPlace ? MediaFiles.displayPath(modelData.url) : ""
                icon.name: modelData.icon
                trailing: Kirigami.Icon {
                    implicitWidth: Kirigami.Units.iconSizes.small
                    implicitHeight: Kirigami.Units.iconSizes.small
                    visible: index === root.currentIndex
                    source: "checkmark"
                }

                onClicked: isPlace ? root.__pick(modelData.url) : root.__typePath()
            }
        }

        BigscreenUI.TextField {
            id: pathField

            Layout.fillWidth: true
            visible: root.__typingPath
            placeholderText: i18nc("@info:placeholder", "Such as ~/Videos")
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

            BigscreenUI.BackHandler.enabled: visible
            BigscreenUI.BackHandler.onActivated: {
                root.__typingPath = false;
                placesList.forceActiveFocus();
            }

            onTextChanged: pathError.visible = false
            onAccepted: {
                const folder = Folders.resolve(text);
                if (folder.toString().length > 0) {
                    root.__pick(folder);
                } else {
                    pathError.visible = true;
                }
            }
        }

        BigscreenUI.Label {
            id: pathError

            Layout.fillWidth: true
            visible: false
            text: i18n("There's no folder at %1", pathField.text)
            color: Kirigami.Theme.negativeTextColor
            wrapMode: Text.Wrap
        }
    }
}
