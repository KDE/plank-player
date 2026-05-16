// SPDX-FileCopyrightText: 2021 Aditya Mehra <aix.m@outlook.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.bigscreen as Bigscreen

Bigscreen.Button {
    id: osdBtn
    Layout.fillWidth: true
    Layout.preferredHeight: Kirigami.Units.gridUnit * 4

    onFocusChanged: {
       hideTimer.restart()
    }

    contentItem: Item {
        Kirigami.Icon {
            id: osdBtnIcon
            source: osdBtn.icon.name
            anchors.centerIn: parent
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            color: osdBtn.checked ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
        }
    }

    Keys.onReturnPressed: (event)=> {
        clicked()
    }
 }
