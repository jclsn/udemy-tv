// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "lectureparser.h"

#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QTest>

class LectureParserTest : public QObject
{
    Q_OBJECT

private:
    static QJsonObject fixture(const QString &name)
    {
        QFile file(QStringLiteral(TEST_DATA_DIR "/") + name + QStringLiteral(".json"));

        if (!file.open(QIODevice::ReadOnly)) {
            qFatal("Missing test data %s", qPrintable(name));
        }

        QJsonParseError error;
        const QJsonDocument document = QJsonDocument::fromJson(file.readAll(), &error);

        if (error.error != QJsonParseError::NoError) {
            qFatal("Bad test data %s: %s", qPrintable(name), qPrintable(error.errorString()));
        }

        return document.object();
    }

    static QJsonObject demo(const QString &name)
    {
        QFile file(QStringLiteral(DEMO_DIR "/") + name);

        if (!file.open(QIODevice::ReadOnly)) {
            qFatal("Missing %s", qPrintable(name));
        }

        return QJsonDocument::fromJson(file.readAll()).object();
    }

    static QVariantMap slide(const QVariantMap &lecture, int index)
    {
        return lecture.value(QStringLiteral("slides")).toList().value(index).toMap();
    }

private Q_SLOTS:
    void videoPrefersHls()
    {
        const QVariantMap lecture =
            LectureParser::parse(fixture(QStringLiteral("video-prefers-hls")));
        QCOMPARE(lecture.value(QStringLiteral("kind")).toString(), QStringLiteral("video"));
        QCOMPARE(lecture.value(QStringLiteral("source")).toString(),
                 QStringLiteral("https://cdn/index.m3u8"));
        QCOMPARE(lecture.value(QStringLiteral("duration")).toDouble(), 300.0);
        QCOMPARE(lecture.value(QStringLiteral("resumePosition")).toDouble(), 42.0);

        const QVariantList sources = lecture.value(QStringLiteral("sources")).toList();
        QCOMPARE(sources.size(), 3);
        QCOMPARE(sources.at(0).toMap().value(QStringLiteral("label")).toString(),
                 QStringLiteral("Auto"));
        QCOMPARE(sources.at(1).toMap().value(QStringLiteral("label")).toString(),
                 QStringLiteral("1080p"));
        QCOMPARE(sources.at(2).toMap().value(QStringLiteral("label")).toString(),
                 QStringLiteral("720p"));
    }

    void olderStreamUrls()
    {
        const QVariantMap lecture =
            LectureParser::parse(fixture(QStringLiteral("older-stream-urls")));
        QCOMPARE(lecture.value(QStringLiteral("kind")).toString(), QStringLiteral("video"));
        QCOMPARE(lecture.value(QStringLiteral("source")).toString(),
                 QStringLiteral("https://cdn/720.mp4"));
        QCOMPARE(lecture.value(QStringLiteral("duration")).toDouble(), 61.0);
    }

    void drmOnlyDash()
    {
        // Protected DASH plays through Widevine too
        const QVariantMap lecture = LectureParser::parse(fixture(QStringLiteral("drm-only-dash")));
        QCOMPARE(lecture.value(QStringLiteral("kind")).toString(), QStringLiteral("video"));
        QVERIFY(lecture.value(QStringLiteral("drm")).toBool());
        QVERIFY(lecture.value(QStringLiteral("source")).toString().isEmpty());
        QCOMPARE(lecture.value(QStringLiteral("protectedType")).toString(), QStringLiteral("dash"));
        QCOMPARE(lecture.value(QStringLiteral("licenseToken")).toString(), QStringLiteral("abc"));
    }

    void drmCourseWithHlsStillPlays()
    {
        // Some lectures of a protected course come without protection
        const QVariantMap lecture =
            LectureParser::parse(fixture(QStringLiteral("drm-course-with-hls")));
        QCOMPARE(lecture.value(QStringLiteral("kind")).toString(), QStringLiteral("video"));
    }

    void encryptedHlsPlaysThroughWidevine()
    {
        // Played natively, these fail on the Widevine key of every segment
        for (const QString &name :
             {QStringLiteral("encrypted-hls"), QStringLiteral("licensed-hls")}) {
            const QVariantMap lecture = LectureParser::parse(fixture(name));
            QCOMPARE(lecture.value(QStringLiteral("kind")).toString(), QStringLiteral("video"));
            QVERIFY(lecture.value(QStringLiteral("drm")).toBool());
            QVERIFY(lecture.value(QStringLiteral("protected")).toBool());
            QVERIFY(lecture.value(QStringLiteral("source")).toString().isEmpty());
            QCOMPARE(lecture.value(QStringLiteral("protectedType")).toString(),
                     QStringLiteral("hls"));
            QVERIFY(lecture.value(QStringLiteral("protectedSource")).toString().endsWith(u".m3u8"));
        }
    }

    void mashupWithTimedImages()
    {
        const QVariantMap lecture =
            LectureParser::parse(demo(QStringLiteral("lecture-mashup.json")));
        QCOMPARE(lecture.value(QStringLiteral("kind")).toString(), QStringLiteral("mashup"));
        QVERIFY(lecture.value(QStringLiteral("timedSlides")).toBool());
        QCOMPARE(lecture.value(QStringLiteral("slides")).toList().size(), 5);
        QCOMPARE(slide(lecture, 1).value(QStringLiteral("time")).toDouble(), 20.0);
        QCOMPARE(slide(lecture, 1).value(QStringLiteral("image")).toString(),
                 QStringLiteral("qrc:/demo/slides/slide2.svg"));
        QVERIFY(lecture.value(QStringLiteral("slidesPdf")).toString().isEmpty());
    }

    void mashupWithPdfAndPageNumbers()
    {
        // Times as clock strings, unsorted, pages numbered from 1, the slides in a PDF
        const QVariantMap lecture =
            LectureParser::parse(fixture(QStringLiteral("mashup-pdf-pages")));
        QCOMPARE(lecture.value(QStringLiteral("kind")).toString(), QStringLiteral("mashup"));
        QCOMPARE(lecture.value(QStringLiteral("slidesPdf")).toString(),
                 QStringLiteral("https://cdn/deck.pdf"));
        QVERIFY(lecture.value(QStringLiteral("timedSlides")).toBool());
        QCOMPARE(slide(lecture, 0).value(QStringLiteral("page")).toInt(), 0);
        QCOMPARE(slide(lecture, 1).value(QStringLiteral("time")).toDouble(), 90.0);
        QCOMPARE(slide(lecture, 1).value(QStringLiteral("page")).toInt(), 1);
        QCOMPARE(slide(lecture, 2).value(QStringLiteral("time")).toDouble(), 125.5);
    }

    void mashupTimesInMilliseconds()
    {
        const QVariantMap lecture =
            LectureParser::parse(fixture(QStringLiteral("mashup-milliseconds")));
        QCOMPARE(lecture.value(QStringLiteral("slides")).toList().size(), 2);
        QCOMPARE(slide(lecture, 1).value(QStringLiteral("time")).toDouble(), 45.0);
    }

    void presentationWithoutVideo()
    {
        const QVariantMap lecture = LectureParser::parse(fixture(QStringLiteral("presentation")));
        QCOMPARE(lecture.value(QStringLiteral("kind")).toString(), QStringLiteral("presentation"));
        QVERIFY(!lecture.value(QStringLiteral("timedSlides")).toBool());
        QCOMPARE(slide(lecture, 1).value(QStringLiteral("image")).toString(),
                 QStringLiteral("https://cdn/2.png"));
        QCOMPARE(slide(lecture, 1).value(QStringLiteral("time")).toDouble(), -1.0);
    }

    void article()
    {
        const QVariantMap lecture =
            LectureParser::parse(demo(QStringLiteral("lecture-article.json")));
        QCOMPARE(lecture.value(QStringLiteral("kind")).toString(), QStringLiteral("article"));
        QVERIFY(lecture.value(QStringLiteral("body"))
                    .toString()
                    .contains(QStringLiteral("Cheat sheet")));
    }

    void captionsInstructorFirst()
    {
        const QVariantMap lecture = LectureParser::parse(fixture(QStringLiteral("captions")));
        const QVariantList captions = lecture.value(QStringLiteral("captions")).toList();
        QCOMPARE(captions.size(), 2);
        QCOMPARE(captions.at(0).toMap().value(QStringLiteral("label")).toString(),
                 QStringLiteral("Deutsch"));
        QVERIFY(captions.at(1).toMap().value(QStringLiteral("automatic")).toBool());
    }

    void processingAndUnknown()
    {
        QCOMPARE(LectureParser::parse(fixture(QStringLiteral("processing")))
                     .value(QStringLiteral("kind"))
                     .toString(),
                 QStringLiteral("processing"));
        QCOMPARE(LectureParser::parse(fixture(QStringLiteral("external-link")))
                     .value(QStringLiteral("kind"))
                     .toString(),
                 QStringLiteral("external"));
        QCOMPARE(LectureParser::parse(fixture(QStringLiteral("empty")))
                     .value(QStringLiteral("kind"))
                     .toString(),
                 QStringLiteral("unsupported"));
    }

    void parseTime_data()
    {
        QTest::addColumn<QJsonValue>("value");
        QTest::addColumn<double>("expected");
        QTest::newRow("number") << QJsonValue(12.5) << 12.5;
        QTest::newRow("numeric string") << QJsonValue(QStringLiteral("30")) << 30.0;
        QTest::newRow("mm:ss") << QJsonValue(QStringLiteral("01:05")) << 65.0;
        QTest::newRow("hh:mm:ss.mmm") << QJsonValue(QStringLiteral("01:00:01.250")) << 3601.25;
        QTest::newRow("comma decimals") << QJsonValue(QStringLiteral("00:00:02,5")) << 2.5;
        QTest::newRow("negative") << QJsonValue(-3) << -1.0;
        QTest::newRow("garbage") << QJsonValue(QStringLiteral("soon")) << -1.0;
        QTest::newRow("missing") << QJsonValue() << -1.0;
    }

    void parseTime()
    {
        QFETCH(QJsonValue, value);
        QFETCH(double, expected);
        QCOMPARE(LectureParser::parseTime(value), expected);
    }
};

QTEST_GUILESS_MAIN(LectureParserTest)

#include "lectureparsertest.moc"
