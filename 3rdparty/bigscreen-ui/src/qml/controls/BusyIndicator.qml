// SPDX-FileCopyrightText: 2018 The Qt Company Ltd.
// SPDX-FileCopyrightText: 2020 Noah Davis <noahadvs@gmail.com>
// SPDX-FileCopyrightText: 2022 ivan tkachenko <me@ratijas.tk>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami

/*!
   \brief Indicator for background activity
 */
// From qqc2-breeze-style
T.BusyIndicator {
    id: root

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 0

    hoverEnabled: false

    contentItem: Item {
        readonly property bool animationShouldBeRunning: visible
            && Window.visibility !== Window.Hidden
            && Kirigami.Units.longDuration > 1

        implicitWidth: Kirigami.Units.iconSizes.huge
        implicitHeight: Kirigami.Units.iconSizes.huge

        visible: root.running || opacityAnimator.running
        opacity: root.running ? 1 : 0
        Behavior on opacity {
            enabled: Kirigami.Units.shortDuration > 0
            OpacityAnimator {
                id: opacityAnimator
                duration: Kirigami.Units.shortDuration
                easing.type: Easing.OutCubic
            }
        }

        onAnimationShouldBeRunningChanged: startOrStopAnimation()

        function startOrStopAnimation(): void {
            if (rotationAnimator.running === animationShouldBeRunning) {
                return;
            }
            if (animationShouldBeRunning) {
                const startAngle = ((Date.now() % rotationAnimator.duration) / rotationAnimator.duration) * 360;
                rotationAnimator.from = startAngle;
                rotationAnimator.to = startAngle + 360;
            }
            rotationAnimator.running = animationShouldBeRunning;
        }

        Kirigami.Icon {
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height)
            height: width

            source: "process-working-symbolic"
            smooth: true

            RotationAnimator on rotation {
                id: rotationAnimator
                from: 0
                to: 360
                duration: 2000
                loops: Animation.Infinite
                running: false
            }
        }

        Component.onCompleted: startOrStopAnimation()
    }
}
