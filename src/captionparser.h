// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QList>
#include <QString>

namespace CaptionParser
{
struct Cue {
    qint64 start = 0; // milliseconds
    qint64 end = 0;
    QString text; // Plain text, lines separated by \n
};

/*!
   \brief Parses WebVTT, or SRT, into cues sorted by start time.
 */
QList<Cue> parse(const QString &text);

/*!
   \brief The text shown at \a position (milliseconds), joining overlapping cues.
 */
QString textAt(const QList<Cue> &cues, qint64 position);
}
