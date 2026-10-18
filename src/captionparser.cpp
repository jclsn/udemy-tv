// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "captionparser.h"

#include <QHash>
#include <QRegularExpression>
#include <QStringList>

#include <algorithm>

namespace
{
// "01:02:03.456", "02:03.456" or the SRT form "01:02:03,456"
qint64 parseTimestamp(const QString &text, bool *ok)
{
    static const QRegularExpression pattern(
        QStringLiteral("^(?:(\\d+):)?(\\d{1,2}):(\\d{1,2})[.,](\\d{1,3})$"));
    const auto match = pattern.match(text.trimmed());
    *ok = match.hasMatch();

    if (!*ok) {
        return 0;
    }

    const qint64 hours = match.captured(1).toLongLong();
    const qint64 minutes = match.captured(2).toLongLong();
    const qint64 seconds = match.captured(3).toLongLong();
    const qint64 millis = match.captured(4).leftJustified(3, u'0').toLongLong();

    return ((hours * 60 + minutes) * 60 + seconds) * 1000 + millis;
}

QString decodeEntities(const QString &text)
{
    static const QRegularExpression entity(QStringLiteral("&(#x[0-9a-fA-F]+|#\\d+|[a-zA-Z]+);"));
    static const QHash<QString, QString> named{
        {QStringLiteral("amp"), QStringLiteral("&")},
        {QStringLiteral("lt"), QStringLiteral("<")},
        {QStringLiteral("gt"), QStringLiteral(">")},
        {QStringLiteral("quot"), QStringLiteral("\"")},
        {QStringLiteral("apos"), QStringLiteral("'")},
        {QStringLiteral("nbsp"), QString(QChar(0xa0))},
        {QStringLiteral("lrm"), QString()},
        {QStringLiteral("rlm"), QString()},
    };

    QString result;
    qsizetype last = 0;
    auto it = entity.globalMatch(text);

    while (it.hasNext()) {
        const auto match = it.next();
        result += QStringView(text).mid(last, match.capturedStart() - last);
        const QString name = match.captured(1);

        if (name.startsWith(u"#x")) {
            result += QChar(char16_t(name.mid(2).toUInt(nullptr, 16)));
        } else if (name.startsWith(u'#')) {
            result += QChar(char16_t(name.mid(1).toUInt()));
        } else {
            result += named.value(name, match.captured(0));
        }

        last = match.capturedEnd();
    }

    result += QStringView(text).mid(last);

    return result;
}

QString cleanText(const QString &text)
{
    // Drop cue tags such as <c.yellow> and <v Speaker>
    static const QRegularExpression tags(QStringLiteral("<[^>]*>"));
    QString plain = text;
    plain.remove(tags);

    return decodeEntities(plain).trimmed();
}
}

QList<CaptionParser::Cue> CaptionParser::parse(const QString &text)
{
    QString normalized = text;
    normalized.replace(QStringLiteral("\r\n"), QStringLiteral("\n"));
    normalized.replace(u'\r', u'\n');

    QList<Cue> cues;
    const QStringList blocks =
        normalized.split(QRegularExpression(QStringLiteral("\\n{2,}")), Qt::SkipEmptyParts);

    for (const QString &block : blocks) {
        QStringList lines = block.split(u'\n');
        // Skip the cue identifier (or SRT counter) before the timing line
        int timingLine = -1;

        for (int i = 0; i < lines.size() && i < 2; ++i) {
            if (lines.at(i).contains(QStringLiteral("-->"))) {
                timingLine = i;
                break;
            }
        }

        if (timingLine < 0) {
            continue; // Header, NOTE or STYLE block
        }

        const QString timing = lines.at(timingLine);
        const int arrow = timing.indexOf(QStringLiteral("-->"));
        // Cue settings such as "align:start" follow the end time
        const QString endPart = timing.mid(arrow + 3).trimmed().section(u' ', 0, 0);
        bool startOk = false;
        bool endOk = false;
        Cue cue;
        cue.start = parseTimestamp(timing.left(arrow), &startOk);
        cue.end = parseTimestamp(endPart, &endOk);

        if (!startOk || !endOk || cue.end < cue.start) {
            continue;
        }

        cue.text = cleanText(lines.mid(timingLine + 1).join(u'\n'));

        if (!cue.text.isEmpty()) {
            cues.append(cue);
        }
    }

    std::stable_sort(cues.begin(), cues.end(), [](const Cue &a, const Cue &b) {
        return a.start < b.start;
    });

    return cues;
}

QString CaptionParser::textAt(const QList<Cue> &cues, qint64 position)
{
    // The first cue starting after the position; everything before it may still be showing
    const auto after =
        std::upper_bound(cues.cbegin(), cues.cend(), position, [](qint64 value, const Cue &cue) {
            return value < cue.start;
        });

    QStringList lines;
    // Cues rarely overlap by more than a few, so look back only a little
    int lookBack = 0;

    for (auto it = after; it != cues.cbegin() && lookBack < 8; ++lookBack) {
        --it;

        if (position < it->end) {
            lines.prepend(it->text);
        }
    }

    return lines.join(u'\n');
}
