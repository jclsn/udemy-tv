// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami

/*!
   \brief A page of an app.

   The content fills the whole page, so it can reach the edges of the screen, such as a row
   of media that scrolls off the side. Keep text and controls within \l contentMargins, clear
   of the edges of the screen.

   For a page with margins automatically applied, use ScrollablePage.

   \code
   BigscreenUI.Page {
       background: BigscreenUI.BackdropImage {
           source: "backdrop.jpg"
       }

       BigscreenUI.HeroBanner {
           x: parent.contentMargins.left
           y: parent.contentMargins.top
           ...
       }
   }
   \endcode
 */
T.Page {
    id: root

    /*!
       \qmlproperty real Page::contentMargins.left
       \qmlproperty real Page::contentMargins.right
       \qmlproperty real Page::contentMargins.top
       \qmlproperty real Page::contentMargins.bottom
       \brief How far text and controls should keep from each edge of the page's content.
     */
    readonly property Margins contentMargins: Margins {
        left: Math.max(root.__horizontalScreenMargin - root.__navigationLeft, Units.contentSpacing)
        right: root.__horizontalScreenMargin
        top: Math.max(root.__verticalScreenMargin - root.__navigationTop, Units.contentSpacing)
        bottom: root.__verticalScreenMargin
    }

    readonly property int __horizontalScreenMargin: Units.horizontalScreenMarginFor(Window.width > 0 ? Window.width : width)
    readonly property int __verticalScreenMargin: Units.verticalScreenMarginFor(Window.height > 0 ? Window.height : height)

    component Margins: QtObject {
        property real left
        property real right
        property real top
        property real bottom
    }

    // The navigation over the page, when ApplicationWindow shows it under the navigation
    readonly property real __navigationTop: T.StackView.view?.__navigationTop ?? 0
    readonly property real __navigationLeft: T.StackView.view?.__navigationLeft ?? 0

    // HACK: SafeArea doesn't pass margins while item is being created
    Component.onCompleted: {
        SafeArea.additionalMargins.left = Qt.binding(() => __navigationLeft + contentMargins.left);
        SafeArea.additionalMargins.right = Qt.binding(() => contentMargins.right);
        SafeArea.additionalMargins.top = Qt.binding(() => __navigationTop + contentMargins.top);
        SafeArea.additionalMargins.bottom = Qt.binding(() => contentMargins.bottom);
    }

    // The title already keeps clear of the navigation
    topPadding: title.length > 0 ? 0 : __navigationTop
    leftPadding: __navigationLeft

    header: Label {
        visible: text.length > 0
        text: root.title
        leftPadding: root.__navigationLeft + root.contentMargins.left
        rightPadding: root.contentMargins.right
        topPadding: root.__navigationTop + root.contentMargins.top
        type: Label.Title
        elide: Text.ElideRight
        Accessible.role: Accessible.Heading
    }
}
