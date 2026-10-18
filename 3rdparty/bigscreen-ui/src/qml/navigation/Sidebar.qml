// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami

/*!
   \brief A sidebar for switching between the sections of an app.

   \code
   BigscreenUI.Sidebar {
       id: sidebar
       height: parent.height
       title: "Media Center"
       iconName: "applications-multimedia"
       KeyNavigation.right: pages.children[pages.currentIndex]
       onActivated: pages.children[pages.currentIndex].forceActiveFocus()

       actions: [
           Kirigami.Action { text: "Home"; icon.name: "go-home" },
           Kirigami.Action { text: "Movies"; icon.name: "folder-videos" },
           Kirigami.Action { separator: true },
           Kirigami.Action { text: "Settings"; icon.name: "configure" }
       ]
   }

   StackLayout {
       id: pages
       anchors.fill: parent
       anchors.leftMargin: sidebar.collapsedWidth
       currentIndex: sidebar.currentIndex
       ...
   }
   \endcode
 */
FocusScope {
    id: root

    enum Mode {
        Rail,     // Collapses to a rail of icons
        Expanded, // Always fully shown
        Hidden    // Hides completely until it has focus
    }

    /*!
       \brief How the sidebar looks while focus is elsewhere.
       \default Sidebar.Rail
     */
    property int mode: Sidebar.Rail

    /*!
       \brief The entries of the sidebar.
     */
    property list<T.Action> actions

    /*!
       \brief The index of the current sidebar entry.
     */
    property int currentIndex: 0

    /*!
       \brief The app name shown at the top of the sidebar.
     */
    property string title

    /*!
       \brief The icon shown at the top of the sidebar, next to the title.
     */
    property string iconName

    /*!
       \brief The footer of the sidebar.
     */
    property Item footer

    /*!
       \brief The width of the sidebar when it shows its labels.
     */
    property real expandedWidth: Kirigami.Units.gridUnit * 16

    /*!
       \brief Whether the sidebar shows its labels.
     */
    readonly property bool expanded: mode === Sidebar.Expanded || activeFocus

    /*!
       \brief Whether the sidebar is expanded over the pages, rather than beside them
     */
    readonly property bool overlaying: expanded && mode !== Sidebar.Expanded

    /*!
       \brief The width the sidebar takes up while focus is elsewhere.
     */
    readonly property real collapsedWidth: mode === Sidebar.Expanded ? expandedWidth : mode === Sidebar.Hidden ? 0 : railWidth

    readonly property bool hasSeparator: {
        for (const action of actions) {
            if (("separator" in action) && action.separator) {
                return true;
            }
        }
        return false;
    }

    readonly property real railWidth: Kirigami.Units.iconSizes.medium + (padding + Units.horizontalPadding) * 2
    readonly property real padding: Kirigami.Units.largeSpacing

    signal activated(int index)

    /*!
       \brief This signal is emitted when the sidebar wants to close (e.g. user taps in empty space)
       Move focus to the page, so the sidebar collapses.
     */
    signal dismissRequested()

    // In Hidden mode, the sidebar keeps its width and slides in from off screen
    width: expanded || mode === Sidebar.Hidden ? expandedWidth : collapsedWidth
    Behavior on width {
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.OutCubic
        }
    }
    transform: Translate {
        x: root.mode === Sidebar.Hidden && !root.expanded ? -root.width : 0
        Behavior on x {
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false

    // Focus always arrives on the current entry
    onActiveFocusChanged: {
        if (activeFocus) {
            (entries.itemAt(currentIndex) ?? entryColumn.children.find(entry => entry.activeFocusOnTab && entry.enabled))?.forceActiveFocus();
        }
    }

    // Dims the pages while the sidebar is expanded over them
    Rectangle {
        z: -1
        width: root.parent ? root.parent.width : 0
        height: root.height
        color: "black"
        opacity: root.overlaying ? 0.45 : 0
        Behavior on opacity {
            OpacityAnimator {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }

        // Tapping the dimmed area causes sidebar to request for close
        MouseArea {
            anchors.fill: parent
            anchors.leftMargin: root.width
            enabled: root.overlaying
            onClicked: root.dismissRequested()
        }
    }

    // While expanded over the pages, the sidebar is above them and casts a shadow on them
    Rectangle {
        anchors.left: parent.right
        width: Kirigami.Units.largeSpacing * 3
        height: parent.height
        opacity: root.overlaying ? 0.3 : 0
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "black" }
            GradientStop { position: 1; color: "transparent" }
        }
        Behavior on opacity {
            OpacityAnimator { duration: Kirigami.Units.longDuration }
        }
    }

    Item {
        anchors.fill: parent

        // Open full view when sidebar is tapped in rail mode
        MouseArea {
            anchors.fill: parent
            enabled: root.mode === Sidebar.Rail
            onClicked: {
                if (!root.overlaying) {
                    root.forceActiveFocus();
                }
            }
        }

        // While collapsed, the rail fades into the page so it sits on top of artwork
        Rectangle {
            anchors.fill: parent
            opacity: root.expanded ? 0 : 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.85) }
                GradientStop { position: 1; color: "transparent" }
            }
            Behavior on opacity {
                OpacityAnimator { duration: Kirigami.Units.longDuration }
            }
        }

        // Beside the pages, the sidebar is a recessed surface under them; over the pages, it is raised and has their color
        Rectangle {
            anchors.fill: parent
            color: root.mode === Sidebar.Expanded ? Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, "black", 0.18)
                                   : Kirigami.Theme.backgroundColor
            opacity: root.expanded ? 1 : 0
            Behavior on opacity {
                OpacityAnimator { duration: Kirigami.Units.longDuration }
            }
        }

        // Right shadow in expanded mode
        Rectangle {
            anchors.right: parent.right
            width: Kirigami.Units.largeSpacing * 2
            height: parent.height
            opacity: root.mode === Sidebar.Expanded ? 0.2 : 0
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: "black" }
            }
        }

        // Follows the animated width, so the entries' backgrounds always fit the rail; the
        // labels elide while they fade out
        ColumnLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: root.padding + Units.horizontalPadding
                Layout.rightMargin: root.padding
                Layout.topMargin: Kirigami.Units.gridUnit * 2
                Layout.bottomMargin: Kirigami.Units.gridUnit * 2
                visible: root.title.length > 0 || root.iconName.length > 0
                spacing: Kirigami.Units.largeSpacing * 2

                Kirigami.Icon {
                    implicitWidth: Kirigami.Units.iconSizes.medium
                    implicitHeight: Kirigami.Units.iconSizes.medium
                    source: root.iconName
                    visible: root.iconName.length > 0
                }
                Label {
                    Layout.fillWidth: true
                    text: root.title
                    type: Label.Heading
                    font.weight: Font.Light
                    elide: Text.ElideRight
                    opacity: root.expanded ? 1 : 0
                    Behavior on opacity {
                        OpacityAnimator { duration: Kirigami.Units.shortDuration }
                    }
                }
            }

            // Scrolls when the entries don't fit, fading out at the edges like ScrollablePage
            Flickable {
                id: entryView

                readonly property bool overflowing: entryColumn.implicitHeight > height
                readonly property real fadeLength: overflowing ? Kirigami.Units.gridUnit : 0

                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: Math.max(height - topMargin - bottomMargin, entryColumn.implicitHeight)
                topMargin: fadeLength
                bottomMargin: fadeLength
                interactive: overflowing
                boundsBehavior: Flickable.StopAtBounds
                clip: overflowing
                layer.enabled: overflowing
                layer.effect: EdgeFadeEffect {
                    topFadeLength: entryView.fadeLength
                    bottomFadeLength: entryView.fadeLength
                }

                function ensureVisible(item: Item): void {
                    if (!overflowing) {
                        return;
                    }
                    const y = item.mapToItem(contentItem, 0, 0).y;
                    const top = contentY + topMargin;
                    const bottom = contentY + height - bottomMargin;
                    let target = contentY;
                    if (y < top) {
                        target = y - topMargin;
                    } else if (y + item.height > bottom) {
                        target = y + item.height + bottomMargin - height;
                    }
                    scrollAnimation.to = Math.max(-topMargin, Math.min(contentHeight + bottomMargin - height, target));
                    scrollAnimation.restart();
                }

                NumberAnimation {
                    id: scrollAnimation
                    target: entryView
                    property: "contentY"
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.OutCubic
                }

                ColumnLayout {
                    id: entryColumn
                    width: entryView.width
                    height: entryView.contentHeight
                    spacing: Kirigami.Units.smallSpacing

                    // Separators don't take focus, so the arrow keys skip them
                    KeyNavigationGroup.orientation: Qt.Vertical

                    Repeater {
                        id: entries
                        model: root.actions

                        delegate: ButtonDelegate {
                            id: entry

                            required property int index
                            required property T.Action modelData
                            readonly property bool separator: ("separator" in modelData) && modelData.separator
                            readonly property bool toggle: modelData.checkable
                            readonly property color foregroundColor: checked || activeFocus ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor

                            Layout.fillWidth: true
                            Layout.fillHeight: separator
                            Layout.leftMargin: root.padding
                            Layout.rightMargin: root.padding

                            implicitHeight: separator ? 0 : Kirigami.Units.gridUnit * 3
                            verticalPadding: 0
                            opacity: separator ? 0 : 1
                            visible: !("visible" in modelData) || modelData.visible
                            enabled: !separator && modelData.enabled
                            // Taking focus would expand the sidebar, so a tap or click only activates the entry, and focus comes from the keys
                            focusPolicy: separator ? Qt.NoFocus : Qt.TabFocus
                            leftInset: 0
                            rightInset: 0
                            topInset: 0
                            bottomInset: 0

                            text: modelData.text
                            icon.name: modelData.icon.name || modelData.icon.source
                            icon.color: foregroundColor
                            textItem.color: foregroundColor
                            textItem.opacity: root.expanded ? 1 : 0
                            Behavior on textItem.opacity {
                                NumberAnimation { duration: Kirigami.Units.shortDuration }
                            }

                            // A section entry is checked when current, and raised; a toggle shows its state with a switch
                            checked: !toggle && index === root.currentIndex
                            raisedBackground: checked

                            trailingPadding: toggle ? Kirigami.Units.gridUnit : 0
                            trailing: SwitchIndicator {
                                visible: entry.toggle
                                implicitWidth: entry.toggle ? implicitHeight * 2 : 0
                                checked: entry.modelData.checked
                                highlighted: entry.activeFocus || entry.hovered
                                enabled: entry.enabled
                                opacity: root.expanded ? 1 : 0
                                Behavior on opacity {
                                    NumberAnimation { duration: Kirigami.Units.shortDuration }
                                }
                            }

                            Accessible.role: toggle ? Accessible.CheckBox : Accessible.PageTab
                            Accessible.checkable: toggle
                            Accessible.checked: toggle && modelData.checked

                            onActiveFocusChanged: if (activeFocus) entryView.ensureVisible(entry)
                            onClicked: {
                                if (toggle) {
                                    modelData.trigger();
                                    return;
                                }
                                root.currentIndex = index;
                                modelData.trigger();
                                root.activated(index);
                            }
                            Keys.onEnterPressed: click()
                        }
                    }

                    // Without a separator, the entries stay at the top
                    Item {
                        Layout.fillHeight: !root.hasSeparator
                    }

                    Item {
                        id: footerHolder
                        Layout.fillWidth: true
                        Layout.leftMargin: root.padding
                        Layout.rightMargin: root.padding
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        implicitHeight: root.footer?.visible ? root.footer.implicitHeight : 0
                        visible: root.footer !== null
                        data: root.footer ? [root.footer] : []

                        onChildrenChanged: {
                            for (const child of children) {
                                child.anchors.left = footerHolder.left;
                                child.anchors.right = footerHolder.right;
                                child.anchors.bottom = footerHolder.bottom;
                            }
                        }
                    }

                    Item {
                        implicitHeight: Kirigami.Units.gridUnit
                    }
                }
            }
        }
    }
}
