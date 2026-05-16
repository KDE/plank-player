// SPDX-FileCopyrightText: 2021 Aditya Mehra <aix.m@outlook.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami
import org.kde.bigscreen as Bigscreen

Bigscreen.Button {
    id: menuBtn
    width: listView.width
    height: Kirigami.Units.gridUnit * 3

    readonly property Flickable listView: {
        var candidate = parent;
        while (candidate) {
            if (candidate instanceof Flickable) {
                return candidate;
            }
            candidate = candidate.parent;
        }
        return null;
    }

    Keys.onReturnPressed: (event)=> {
        clicked()
    }
 }
