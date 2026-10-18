// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Templates as T

import org.kde.bigscreen.ui as BigscreenUI

BigscreenUI.Page {
    id: root

    property url source

    property alias overline: hero.overline
    property alias metadata: hero.metadata
    property alias description: hero.description

    default property alias actions: hero.actions

    BigscreenUI.BackHandler.enabled: visible
    BigscreenUI.BackHandler.onActivated: T.StackView.view.pop()

    background: BigscreenUI.BackdropImage {
        source: root.source
        useAmbientFallback: true
    }

    header: null

    BigscreenUI.HeroBanner {
        id: hero

        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.contentMargins.left
        anchors.bottomMargin: root.contentMargins.bottom
        width: Math.min(Math.round(parent.width * 0.55), parent.width - root.contentMargins.left - root.contentMargins.right)

        title: root.title
    }
}
