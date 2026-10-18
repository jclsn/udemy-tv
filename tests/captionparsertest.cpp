// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "captionparser.h"

#include <QFile>
#include <QTest>

class CaptionParserTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void webVtt()
    {
        const auto cues = CaptionParser::parse(
            QStringLiteral("WEBVTT\n"
                           "Kind: captions\n\n"
                           "NOTE This is a comment\n\n"
                           "intro\n"
                           "00:00:01.000 --> 00:00:03.500 align:start position:10%\n"
                           "<v Instructor>Hello &amp; welcome</v>\n"
                           "to <c.yellow>the course</c>\n\n"
                           "02:04.250 --> 02:06.000\n"
                           "Short timestamps\n"));
        QCOMPARE(cues.size(), 2);
        QCOMPARE(cues.at(0).start, 1000);
        QCOMPARE(cues.at(0).end, 3500);
        QCOMPARE(cues.at(0).text, QStringLiteral("Hello & welcome\nto the course"));
        QCOMPARE(cues.at(1).start, 124250);
    }

    void srtWithWindowsLineEndings()
    {
        const auto cues = CaptionParser::parse(
            QStringLiteral("1\r\n00:00:00,500 --> 00:00:02,000\r\nFirst\r\n\r\n"
                           "2\r\n00:00:02,000 --> 00:00:04,000\r\nSecond\r\n"));
        QCOMPARE(cues.size(), 2);
        QCOMPARE(cues.at(0).start, 500);
        QCOMPARE(cues.at(1).text, QStringLiteral("Second"));
    }

    void textAt()
    {
        const auto cues =
            CaptionParser::parse(QStringLiteral("WEBVTT\n\n"
                                                "00:00:01.000 --> 00:00:05.000\nLong\n\n"
                                                "00:00:02.000 --> 00:00:03.000\nOverlapping\n\n"
                                                "00:00:06.000 --> 00:00:07.000\nLater\n"));
        QCOMPARE(CaptionParser::textAt(cues, 500), QString());
        QCOMPARE(CaptionParser::textAt(cues, 1500), QStringLiteral("Long"));
        QCOMPARE(CaptionParser::textAt(cues, 2500), QStringLiteral("Long\nOverlapping"));
        QCOMPARE(CaptionParser::textAt(cues, 5000), QString()); // The end is exclusive
        QCOMPARE(CaptionParser::textAt(cues, 6500), QStringLiteral("Later"));
        QCOMPARE(CaptionParser::textAt({}, 1000), QString());
    }

    void entities()
    {
        const auto cues = CaptionParser::parse(QStringLiteral(
            "WEBVTT\n\n00:00.000 --> 00:01.000\nx &lt; y &#38;&#x26; &quot;z&quot;&lrm;\n"));
        QCOMPARE(cues.size(), 1);
        QCOMPARE(cues.at(0).text, QStringLiteral("x < y && \"z\""));
    }

    void demoFile()
    {
        QFile file(QStringLiteral(DEMO_DIR "/captions-en.vtt"));
        QVERIFY(file.open(QIODevice::ReadOnly));
        const auto cues = CaptionParser::parse(QString::fromUtf8(file.readAll()));
        QCOMPARE(cues.size(), 33);
        QCOMPARE(CaptionParser::textAt(cues, 1000),
                 QStringLiteral("Hi, and welcome to this lecture."));
        QCOMPARE(CaptionParser::textAt(cues, 42500), QStringLiteral("First, the building blocks."));
    }

    void garbage()
    {
        QVERIFY(CaptionParser::parse(QString()).isEmpty());
        QVERIFY(CaptionParser::parse(QStringLiteral("not captions at all")).isEmpty());
        QVERIFY(CaptionParser::parse(
                    QStringLiteral("WEBVTT\n\n00:00:05.000 --> 00:00:01.000\nBackwards\n"))
                    .isEmpty());
    }
};

QTEST_GUILESS_MAIN(CaptionParserTest)

#include "captionparsertest.moc"
