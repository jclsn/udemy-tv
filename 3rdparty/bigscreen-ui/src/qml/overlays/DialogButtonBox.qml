// SPDX-FileCopyrightText: 2025 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import QtQuick.Effects

import org.kde.kirigami as Kirigami

T.DialogButtonBox {
    id: root

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    required property var dialog

    visible: count > 0

    topPadding: Kirigami.Units.gridUnit
    bottomPadding: Kirigami.Units.gridUnit
    leftPadding: Kirigami.Units.gridUnit
    rightPadding: Kirigami.Units.gridUnit
    alignment: Qt.AlignRight

    spacing: Kirigami.Units.mediumSpacing
    position: T.DialogButtonBox.Footer

    standardButtons: root.dialog.standardButtons

    // Focus arriving on the box goes to its first button
    onActiveFocusChanged: {
        if (activeFocus) {
            itemAt(0)?.forceActiveFocus();
        }
    }

    delegate: Button {
        icon.name: {
            switch (T.DialogButtonBox.buttonRole) {
            case T.DialogButtonBox.AcceptRole:
            case T.DialogButtonBox.YesRole:
                return "dialog-ok";
            case T.DialogButtonBox.RejectRole:
            case T.DialogButtonBox.NoRole:
                return "dialog-cancel";
            case T.DialogButtonBox.ApplyRole:
                return "dialog-ok-apply";
            case T.DialogButtonBox.ResetRole:
                return "edit-undo";
            case T.DialogButtonBox.DestructiveRole:
                return "edit-delete";
            case T.DialogButtonBox.HelpRole:
                return "help-contents";
            default:
                return "";
            }
        }
        Kirigami.MnemonicData.controlType: Kirigami.MnemonicData.DialogButton
    }

    contentItem: RowLayout {
        spacing: root.spacing
        KeyNavigationGroup.orientation: Qt.Horizontal

        Repeater {
            model: root.contentModel
        }
    }
}
