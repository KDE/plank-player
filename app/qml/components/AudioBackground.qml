// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Effects

import org.kde.bigscreen.ui as BigscreenUI

// Media player background for audio files
Item {
    id: root

    property alias source: blurSource.source

    Image {
        id: blurSource
        anchors.fill: parent
        sourceSize.width: 256
        sourceSize.height: 256
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: blurSource
        visible: blurSource.status === Image.Ready
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        saturation: 0.2
        opacity: 0.5
    }

    // Darken blurred cover art
    Rectangle {
        anchors.fill: parent
        visible: blurSource.status === Image.Ready
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.2) }
            GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.8) }
        }
    }
}
