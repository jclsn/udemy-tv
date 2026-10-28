<!--
SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
SPDX-License-Identifier: CC0-1.0
-->

# Udemy TV (unofficial) for Plasma Bigscreen

An unofficial Udemy app for TVs, built with Qt 6, Kirigami and the
[Bigscreen UI](https://invent.kde.org/devinlin/bigscreen-ui) components (vendored in
`3rdparty/`). Not affiliated with Udemy, Inc.

## Building

Needs Qt 6.11 (Base, Declarative, Multimedia, WebEngine, WebChannel), KDE Frameworks 6.14
(Kirigami, KI18n, KCoreAddons, KColorScheme) and Extra CMake Modules.

    cmake -B build -G Ninja -DBUILD_TESTING=ON
    cmake --build build
    ctest --test-dir build
    sudo cmake --install build    # adds it to the Bigscreen app list

## Running

    udemy-tv                       # sign in with your account
    udemy-tv --demo                # sample courses, no account
    udemy-tv --token <access_token> [--portal <business-subdomain>] [--windowed]

## Signing in

- **Access token:** sign in to udemy.com in a browser, open the developer tools and copy the
  value of the `access_token` cookie (under Application or Storage › Cookies), as for Udeler.
  Pass it with `--token`, set `UDEMY_TOKEN`, or paste it on the login screen, for example
  from a phone's clipboard with KDE Connect.
- **Udemy's login page** inside the app. This does not work for every account: Google sign-in
  refuses embedded browsers.
- **Udemy Business:** enter your organization's subdomain, then sign in on its page.

## How it works

- **API:** Udemy is behind Cloudflare, so requests go through `fetch()` in a hidden web page
  on the Udemy origin (`src/bridge.js`, `ApiBridge.qml`).
- **Playback:** HLS and MP4 lectures play natively with captions, speed, quality, resume,
  mark as completed and "Up next". DRM-protected lectures play in Udemy's web player, driven
  by the same controls (`src/webplayer.js`). That needs a Widevine module, which is found in
  Chromium's or Chrome's profile.
- **Slides and speaker:** "video and slide mashup" lectures show both side by side, or one
  large with the other as picture-in-picture. Switch with ▲ while the controls are hidden, S,
  or the "Switch view" button.
- **Buying:** Browse, open a course, "Buy now" opens Udemy's checkout page.
- **Colors:** light as on udemy.com, or dark. The moon or sun beside the settings button
  switches them; Settings can also follow the TV.

`UDEMY_TV_DUMP_LECTURES=1` saves the raw lecture data to
`~/.cache/udemy-tv/udemy-tv/lectures/`. The format of mashup slides is undocumented and the parser
accepts several shapes (see `tests/`); a dump of a lecture that shows no slides helps fix it.

## Packages

- Debian and Ubuntu: `cpack -G DEB` in the build directory
- Arch Linux: `packaging/arch/PKGBUILD`
- Flatpak: `packaging/flatpak/io.github.udemytv.yml`

GitHub Actions builds all three, runs the tests and checks the code style on every push.

## Contributing

C++ follows the KDE Frameworks clang-format style with lines of at most 100 characters
(`.clang-format`); QML, JavaScript and CMake keep to the same length. Commit messages follow
[Conventional Commits](https://www.conventionalcommits.org). Enable the hook that checks the
formatting before each commit with:

    git config core.hooksPath .githooks

After changing texts in the interface, update the translation template `po/udemy-tv.pot` with
`./Messages.sh`. Translations go to `po/<language>/udemy-tv.po`.

The demo images come from the Bigscreen UI gallery and are CC-BY-SA-4.0 (see
`src/demo/images/*.license`).
