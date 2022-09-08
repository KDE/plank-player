// SPDX-FileCopyrightText: 2021 Aditya Mehra <aix.m@outlook.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12
import org.kde.kirigami 2.12 as Kirigami
import QtQuick.Controls 2.12 as Controls
import QtMultimedia 5.12

Kirigami.AbstractApplicationWindow {
    id: window
    visible: true
    title: i18n("PlankPlayer")
    color: Kirigami.Theme.backgroundColor
    width:  Screen.desktopAvailableWidth
    height: Screen.desktopAvailableHeight
    visibility: "FullScreen"
    property var videoSource
    property alias videoStatus: video.status

    Component.onCompleted: {
        console.log(HomeDirectory)
        playerOSDItem.opened = true
    }

    onVideoSourceChanged: {
        if(videoSource !== ""){
            video.source = Qt.resolvedUrl(videoSource)
            playerOSDItem.opened = true
            video.play()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"

        Menu {
            id: mainMenu
            onClosed: {
                playerOSDItem.opened = true
            }
        }

        Video {
            id: video
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: playerOSDItem.opened ? playerOSDItem.top : parent.bottom
            focus: true
            autoLoad: true
            autoPlay: false

            Keys.onDownPressed: {
                playerOSDItem.opened = true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if(!playerOSDItem.pinned){
                       playerOSDItem.opened = !playerOSDItem.opened
                    }
                }
            }

            onStatusChanged: {
                if(status == MediaPlayer.EndOfMedia){
                    video.stop()
                }
            }
        }

        PlayerOSD {
            id: playerOSDItem
            anchors.bottom: parent.bottom
            height: parent.height * 0.10
            videoItem: video
            menuOpened: mainMenu.opened
        }
    }
}
