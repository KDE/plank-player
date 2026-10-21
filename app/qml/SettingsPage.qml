// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

BigscreenUI.ScrollablePage {
    id: root

    background: BigscreenUI.AmbientBackground {}

    ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        BigscreenUI.Label {
            Layout.bottomMargin: Kirigami.Units.largeSpacing
            text: i18nc("@title", "Appearance")
            type: BigscreenUI.Label.Section
        }

        BigscreenUI.ColorSchemeDelegate {
            id: colorSchemeDelegate

            focus: true

            KeyNavigation.down: saveHistoryDelegate
        }

        BigscreenUI.Label {
            Layout.topMargin: Kirigami.Units.gridUnit
            Layout.bottomMargin: Kirigami.Units.largeSpacing
            text: i18nc("@title", "History")
            type: BigscreenUI.Label.Section
        }

        BigscreenUI.SwitchDelegate {
            id: saveHistoryDelegate

            text: i18n("Save watch history")
            icon.name: "view-history"
            checked: History.saving

            KeyNavigation.up: colorSchemeDelegate
            KeyNavigation.down: clearHistoryDelegate

            onToggled: History.saving = checked
        }

        BigscreenUI.ButtonDelegate {
            id: clearHistoryDelegate

            enabled: History.count > 0
            text: i18n("Clear watch history")
            icon.name: "edit-clear-history"

            onClicked: clearHistoryDialog.open()
        }
    }

    BigscreenUI.Dialog {
        id: clearHistoryDialog

        title: i18n("Clear watch history?")
        standardButtons: T.Dialog.Ok | T.Dialog.Cancel
        openFocusItem: standardButton(T.Dialog.Cancel)

        onAccepted: History.clear()
        onClosed: (clearHistoryDelegate.enabled ? clearHistoryDelegate : saveHistoryDelegate).forceActiveFocus()

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right

            BigscreenUI.Label {
                Layout.fillWidth: true
                text: i18n("Your recently watched media and playback positions will be cleared.")
                wrapMode: Text.Wrap
            }
        }

        Component.onCompleted: {
            const clearButton = standardButton(T.Dialog.Ok);
            clearButton.text = i18n("Clear");
            clearButton.icon.name = "edit-clear-history";
        }
    }
}
