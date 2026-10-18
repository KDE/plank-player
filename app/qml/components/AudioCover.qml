// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

// The cover art of the audio being played with its title under it
Item {
    id: root

    property url source
    property bool playing
    property string title
    property bool titleVisible: true

    ColumnLayout {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -Kirigami.Units.gridUnit * 3 // avoid controls
        spacing: Kirigami.Units.gridUnit * 2

        Kirigami.ShadowedImage {
            id: cover

            readonly property real size: Math.round(Math.min(root.width, root.height) * 0.42)

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: size
            Layout.preferredHeight: size

            source: root.source
            sourceSize.width: size
            sourceSize.height: size
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            radius: BigscreenUI.Units.cardCornerRadius
            color: Kirigami.Theme.alternateBackgroundColor
            shadow.size: Kirigami.Units.gridUnit * 3
            shadow.yOffset: Kirigami.Units.largeSpacing
            shadow.color: Qt.rgba(0, 0, 0, 0.6)

            scale: root.playing ? 1 : 0.94
            Behavior on scale { NumberAnimation { duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutCubic } }

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.enormous
                height: width
                visible: cover.status !== Image.Ready
                source: "audio-x-generic"
                opacity: 0.6
            }
        }

        BigscreenUI.Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: root.width * 0.6
            visible: root.titleVisible
            text: root.title
            type: BigscreenUI.Label.Heading
            elide: Text.ElideRight
        }
    }
}
