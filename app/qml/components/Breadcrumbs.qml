// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

ListView {
    id: root

    property string rootName
    property url rootUrl
    property string rootIconName

    // A folder in the root
    property url folder

    signal rootClicked()
    signal folderClicked(url folder)

    implicitHeight: currentItem?.implicitHeight ?? Kirigami.Units.gridUnit * 3

    clip: true
    orientation: ListView.Horizontal
    keyNavigationEnabled: true
    boundsBehavior: Flickable.StopAtBounds
    highlightMoveDuration: Kirigami.Units.longDuration
    highlightRangeMode: ListView.ApplyRange
    preferredHighlightBegin: 0
    preferredHighlightEnd: width

    model: {
        const crumbs = [{ name: rootName, url: rootUrl }];
        let url = rootUrl.toString().replace(/\/$/, "");
        for (const part of folder.toString().slice(url.length).split("/")) {
            if (part.length > 0) {
                url += "/" + part;
                crumbs.push({ name: decodeURIComponent(part), url: url });
            }
        }
        return crumbs;
    }

    onCountChanged: currentIndex = count - 1
    onActiveFocusChanged: {
        if (activeFocus) {
            currentIndex = count - 1;
        }
    }

    delegate: FocusScope {
        id: crumb

        required property int index
        required property var modelData

        implicitWidth: crumbRow.implicitWidth
        implicitHeight: crumbRow.implicitHeight

        RowLayout {
            id: crumbRow

            anchors.fill: parent
            spacing: 0

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                visible: crumb.index > 0
                source: "go-next-symbolic"
                opacity: 0.6
            }

            BigscreenUI.Button {
                flat: true
                focus: true
                text: crumb.modelData.name
                icon.name: crumb.index === 0 ? root.rootIconName : ""
                Accessible.name: crumb.index === 0 ? i18nc("@action:button", "%1, choose location", text) : text

                contentItem: RowLayout {
                    spacing: Kirigami.Units.largeSpacing

                    Kirigami.Icon {
                        implicitWidth: Kirigami.Units.iconSizes.smallMedium
                        implicitHeight: Kirigami.Units.iconSizes.smallMedium
                        visible: source.length > 0
                        source: crumb.index === 0 ? root.rootIconName : ""
                    }
                    BigscreenUI.Label {
                        text: crumb.modelData.name
                        type: BigscreenUI.Label.Heading
                        Accessible.ignored: true
                    }
                    Kirigami.Icon {
                        implicitWidth: Kirigami.Units.iconSizes.small
                        implicitHeight: Kirigami.Units.iconSizes.small
                        visible: crumb.index === 0
                        source: "arrow-down"
                        opacity: 0.7
                    }
                }

                onActiveFocusChanged: {
                    if (activeFocus) {
                        root.currentIndex = crumb.index;
                    }
                }
                onClicked: {
                    if (crumb.index === 0) {
                        root.rootClicked();
                    } else {
                        root.folderClicked(crumb.modelData.url);
                    }
                }
            }
        }
    }
}
