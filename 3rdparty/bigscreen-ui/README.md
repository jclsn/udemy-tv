<!--
SPDX-FileCopyrightText: None
SPDX-License-Identifier: LGPL-2.0-or-later
-->

# Bigscreen UI

Bigscreen UI provides reusable Qt Quick components designed for applications targeting TV/console style platforms (i.e. Plasma Bigscreen).

## Links

* Project page: https://invent.kde.org/libraries/bigscreen-ui
* File issues: https://invent.kde.org/libraries/bigscreen-ui/-/work-items
* Development channel: https://matrix.to/#/#plasma-bigscreen:kde.org

## Using the QML module

Import the module as `org.kde.bigscreen.ui`:

```qml
import org.kde.bigscreen.ui as BigscreenUI

BigscreenUI.Button {
    text: "Button"
}
```

## Handling the back action

`BackHandler` is an attached QML type that handles Escape, the platform back key, and mouse back buttons. Attach it to the item that owns the current view:

```qml
import QtQuick
import org.kde.bigscreen.ui as BigscreenUI

FocusScope {
    id: page

    signal backRequested()

    focus: true

    BigscreenUI.BackHandler.enabled: visible
    BigscreenUI.BackHandler.onActivated: backRequested()
}
```

By default, the handler accepts the input event. Set `BigscreenUI.BackHandler.accepted: false` if the event should continue to another handler after `activated` is emitted.

## Building

```bash
cmake -B build
cmake --build build
cmake --install build
```
