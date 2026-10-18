// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

// A panel from the right with one choice out of a list, such as captions or speed
BigscreenUI.ContextDrawer {
    id: root

    property string title
    property string subtitle

    // [{text, value}]
    property var options: []
    property var currentValue

    signal chosen(var value)

    function openWith(title: string, options: var, currentValue: var, onChosen: var): void {
        root.title = title;
        root.options = options;
        root.currentValue = currentValue;
        root.__onChosen = onChosen;
        open();
    }

    property var __onChosen: null

    openFocusItem: list

    header: BigscreenUI.ContextDrawerHeader {
        title: root.title
        subtitle: root.subtitle
    }

    content: ListView {
        id: list

        clip: true
        spacing: Kirigami.Units.smallSpacing
        keyNavigationEnabled: true
        model: root.options

        onActiveFocusChanged: {
            if (activeFocus) {
                const index = root.options.findIndex(option => option.value === root.currentValue);
                currentIndex = Math.max(0, index);
                positionViewAtIndex(currentIndex, ListView.Contain);
            }
        }

        delegate: BigscreenUI.ButtonDelegate {
            required property var modelData
            required property int index

            width: ListView.view.width
            text: modelData.text
            description: modelData.description ?? ""
            focus: ListView.isCurrentItem
            icon.name: modelData.value === root.currentValue ? "checkmark" : ""
            trailing: Item {
                implicitWidth: Kirigami.Units.iconSizes.smallMedium
            }

            onClicked: {
                root.currentValue = modelData.value;
                root.chosen(modelData.value);

                if (root.__onChosen) {
                    root.__onChosen(modelData.value);
                }

                root.close();
            }
        }
    }
}
