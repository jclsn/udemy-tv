#! /bin/sh
# SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
# SPDX-License-Identifier: LGPL-2.0-or-later
$XGETTEXT `find . -name \*.cpp -o -name \*.h -o -name \*.qml` -o $podir/bigscreen-ui.pot
