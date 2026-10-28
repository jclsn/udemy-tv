#! /bin/sh
# SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Extracts the strings to translate into po/udemy-tv.pot. KDE's translation scripts call it with
# their own XGETTEXT and podir; on its own it uses these defaults:
#   ./Messages.sh

: "${XGETTEXT:=xgettext --from-code=UTF-8 --language=JavaScript --add-comments=i18n \
    --keyword=i18n:1 --keyword=i18nc:1c,2 --keyword=i18np:1,2 --keyword=i18ncp:1c,2,3 \
    --package-name=udemy-tv --msgid-bugs-address=https://github.com/jclsn/udemy-tv/issues}"
: "${podir:=po}"

$XGETTEXT $(find src -name '*.qml' | sort) -o "$podir/udemy-tv.pot"
