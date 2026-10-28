<!--
SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
SPDX-License-Identifier: CC0-1.0
-->

# Udemy TV

An unofficial Udemy app for Plasma Bigscreen, made to be used with a TV remote.

It is built with Qt 6, Kirigami and the
[Bigscreen UI](https://invent.kde.org/devinlin/bigscreen-ui) components.

> Udemy TV is not affiliated with Udemy, Inc.


## Features

- **My learning** and **Browse**, laid out like udemy.com
- **Your courses** with their progress, lists, wishlist and archive
- **Lectures** with captions, playback speed, quality, resume and "Up next"
- **Copy-protected lectures** in the app's own player
- **Slides and speaker** side by side, or one large with the other in a corner
- **Course pages** from the catalog, with buying through Udemy's checkout
- **Light and dark colors**, switched with the sun or moon in the top bar


## Building

You need:

- Qt 6.11: Base, Declarative, Multimedia, WebEngine and WebChannel
- KDE Frameworks 6.14: Kirigami, KI18n, KCoreAddons and KColorScheme
- Extra CMake Modules

Then build, test and install:

```sh
cmake -B build -G Ninja -DBUILD_TESTING=ON
cmake --build build
ctest --test-dir build
sudo cmake --install build
```

Installing adds Udemy TV to the Bigscreen app list.

### Bigscreen UI

Bigscreen UI is not in most distributions yet, so a copy comes with the app in `3rdparty/`.
If it is installed on your system, use that one instead:

```sh
cmake -B build -G Ninja -DUSE_SYSTEM_BIGSCREEN_UI=ON
```


## Running

```sh
udemy-tv                # sign in with your account
udemy-tv --demo         # sample courses, no account needed
udemy-tv --windowed     # in a window instead of full screen
```


## Signing in

There are three ways to sign in.

**Udemy's login page**, inside the app.
This does not work for every account: Google sign-in refuses embedded browsers.

**An access token**, as for Udeler:

1. Sign in to udemy.com in a browser.
2. Open the developer tools and find the cookies (under Application or Storage).
3. Copy the value of the `access_token` cookie.
4. Paste it on the login screen, for example from a phone with KDE Connect.

You can also pass it with `--token <access_token>` or the `UDEMY_TOKEN` variable.

**Udemy Business**: enter your organization's subdomain, then sign in on its page.
On the command line, use `--portal <subdomain>`.


## Using the remote

| Key | What it does |
|---|---|
| Arrows | Move around |
| OK | Open, play or pause |
| Back | Go back |
| ▲ or S while playing, controls hidden | Switch between slides and speaker |
| Menu on a lecture in the course list | Mark it as completed or not |


## How it works

**Requests to Udemy.**
Udemy is behind Cloudflare, which turns away apps that are not a browser.
So all requests run in a hidden web page on udemy.com (`src/bridge.js`, `ApiBridge.qml`).

**Playback.**
Most lectures are protected with Widevine.
They play with Shaka Player and the browser engine's Widevine module, in the app's own player.
The module is taken from Chromium or Chrome, which download it on their own.

**Cache.**
Your courses, curricula and course pages are kept in a small database.
The app shows them at once on the next start, and updates them in the background.


## Debugging

Set `UDEMY_TV_DUMP_LECTURES=1` to save the raw data of each lecture to
`~/.cache/udemy-tv/udemy-tv/lectures/`.

This helps when a lecture does not show its slides: their format is undocumented,
and the parser only knows the shapes in `tests/`.


## Packages

| System | How |
|---|---|
| Debian, Ubuntu | `cpack -G DEB` in the build directory |
| Arch Linux | `packaging/arch/PKGBUILD` |
| Flatpak | `packaging/flatpak/io.github.udemytv.yml` |

GitHub Actions builds all three on every push, runs the tests and checks the code style.


## Contributing

**Code style.**
C++ follows the KDE Frameworks clang-format style (`.clang-format`).
Lines are at most 100 characters long, in QML, JavaScript and CMake too.

**Commits.**
Commit messages follow [Conventional Commits](https://www.conventionalcommits.org).
This hook checks the formatting before each commit:

```sh
git config core.hooksPath .githooks
```

**Translations.**
After changing texts in the interface, update the template `po/udemy-tv.pot`:

```sh
./Messages.sh
```

Translations go to `po/<language>/udemy-tv.po`.


## Credits

The demo images come from the Bigscreen UI gallery and are CC-BY-SA-4.0
(see `src/demo/images/*.license`).
