// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Effects

/*!
   \brief Fades the top and bottom edges of an item to transparent.

   Use it as the layer effect of a scrolling view, so content leaving the view fades
   instead of being cut off at a hard edge.

   The layer renders the view to a texture, so only enable it while the view can scroll.

   \code
   GridView {
       topMargin: Kirigami.Units.gridUnit * 2
       layer.enabled: contentHeight > height
       layer.effect: BigscreenUI.EdgeFadeEffect {
           topFadeLength: Kirigami.Units.gridUnit * 2
       }
   }
   \endcode
 */
MultiEffect {
    id: root

    /*!
       \brief The distance over which the top edge fades in, in pixels.
       \default 0
     */
    property real topFadeLength: 0

    /*!
       \brief The distance over which the bottom edge fades out, in pixels.
       \default 0
     */
    property real bottomFadeLength: 0

    maskEnabled: true
    maskSource: mask
    // Use the mask's alpha as a smooth ramp rather than a hard threshold
    maskThresholdMin: 0.5
    maskSpreadAtMin: 1

    Rectangle {
        id: mask

        width: root.width
        height: root.height
        visible: false
        layer.enabled: true

        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.topFadeLength > 0 ? "transparent" : "black"
            }
            GradientStop {
                position: mask.height > 0 ? Math.min(root.topFadeLength / mask.height, 0.5) : 0
                color: "black"
            }
            GradientStop {
                position: mask.height > 0 ? Math.max(1 - root.bottomFadeLength / mask.height, 0.5) : 1
                color: "black"
            }
            GradientStop {
                position: 1
                color: root.bottomFadeLength > 0 ? "transparent" : "black"
            }
        }
    }
}
