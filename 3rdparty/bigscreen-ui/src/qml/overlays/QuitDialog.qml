// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Templates as T

/*!
   \brief A dialog that asks the user to confirm quitting the app.
 */
Dialog {
    id: root

    title: i18nd("bigscreen-ui", "Quit %1?", Qt.application.displayName)
    standardButtons: T.Dialog.Ok | T.Dialog.Cancel
    openFocusItem: standardButton(T.Dialog.Ok)

    onAccepted: Qt.quit()

    Component.onCompleted: {
        const quitButton = standardButton(T.Dialog.Ok);
        quitButton.text = i18nd("bigscreen-ui", "Quit");
        quitButton.icon.name = "application-exit";
    }
}
