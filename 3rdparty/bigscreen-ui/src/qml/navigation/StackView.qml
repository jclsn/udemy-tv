// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami

/*!
   \brief A stack of pages that crossfades when pages are pushed, popped or replaced.
 */
T.StackView {
    id: root

    pushEnter: Transition {
        OpacityAnimator { from: 0; to: 1; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
    }
    pushExit: Transition {
        OpacityAnimator { from: 1; to: 0; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
    }
    popEnter: Transition {
        OpacityAnimator { from: 0; to: 1; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
    }
    popExit: Transition {
        OpacityAnimator { from: 1; to: 0; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
    }
    replaceEnter: Transition {
        OpacityAnimator { from: 0; to: 1; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
    }
    replaceExit: Transition {
        OpacityAnimator { from: 1; to: 0; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
    }
}
