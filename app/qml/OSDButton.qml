// SPDX-FileCopyrightText: 2021 Aditya Mehra <aix.m@outlook.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Templates 2.12 as QQCT
import org.kde.kirigami 2.12 as Kirigami

QQCT.Button {
     id: osdBtn
     Layout.fillWidth: true
     Layout.preferredHeight: Kirigami.Units.gridUnit * 4
     property alias iconSource: osdBtnIcon.source

     background: Rectangle {
         color: osdBtn.activeFocus ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
         border.color: Kirigami.Theme.disabledTextColor
     }

     onFocusChanged: {
        hideTimer.restart()
     }

     contentItem: Item {
         Kirigami.Icon {
             id: osdBtnIcon
             anchors.centerIn: parent
             Layout.preferredWidth: Kirigami.Units.iconSizes.medium
             Layout.preferredHeight: Kirigami.Units.iconSizes.medium
             color: osdBtn.checked ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
         }
     }

     Keys.onReturnPressed: {
         clicked()
     }
 }
