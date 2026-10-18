// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "demobackend.h"

#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QUrlQuery>

namespace
{
QByteArray fixture(const QString &name)
{
    QFile file(QStringLiteral(":/demo/") + name);

    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "Missing demo fixture" << name;

        return QByteArrayLiteral("{}");
    }

    return file.readAll();
}

QByteArray json(const QJsonObject &object)
{
    return QJsonDocument(object).toJson(QJsonDocument::Compact);
}

// Which sample each demo lecture uses; the rest are plain videos
QString lectureFixture(qint64 lectureId)
{
    switch (lectureId) {
    case 1003:
    case 1011:
        return QStringLiteral("lecture-mashup.json");
    case 1006:
        return QStringLiteral("lecture-article.json");
    case 1009:
        return QStringLiteral("lecture-drm.json");
    default:
        return QStringLiteral("lecture-video.json");
    }
}

QString curriculumTitle(qint64 lectureId)
{
    const QJsonArray items = QJsonDocument::fromJson(fixture(QStringLiteral("curriculum.json")))
                                 .object()
                                 .value(u"results")
                                 .toArray();

    for (const QJsonValue &value : items) {
        if (value.toObject().value(u"id").toInteger() == lectureId) {
            return value.toObject().value(u"title").toString();
        }
    }

    return {};
}

// The catalog search, as the GraphQL API answers it, made from the sample courses
QByteArray searchResults(const QByteArray &requestBody)
{
    const QString search = QJsonDocument::fromJson(requestBody)
                               .object()
                               .value(u"variables")
                               .toObject()
                               .value(u"query")
                               .toString()
                               .toLower();
    const QJsonArray courses = QJsonDocument::fromJson(fixture(QStringLiteral("search.json")))
                                   .object()
                                   .value(u"results")
                                   .toArray();

    QJsonArray all;
    QJsonArray matches;

    for (const QJsonValue &value : courses) {
        const QJsonObject course = value.toObject();
        QJsonArray instructors;

        for (const QJsonValue &instructor : course.value(u"visible_instructors").toArray()) {
            instructors.append(QJsonObject{
                {QStringLiteral("name"), instructor.toObject().value(u"display_name")}});
        }

        const QJsonObject result{
            {QStringLiteral("course"),
             QJsonObject{
                 {QStringLiteral("id"), QString::number(course.value(u"id").toInteger())},
                 {QStringLiteral("title"), course.value(u"title")},
                 {QStringLiteral("headline"), course.value(u"headline")},
                 {QStringLiteral("durationInSeconds"), 6 * 3600},
                 {QStringLiteral("images"),
                  QJsonObject{{QStringLiteral("px480x270"), course.value(u"image_480x270")}}},
                 {QStringLiteral("instructors"), instructors},
                 {QStringLiteral("isFree"), false},
                 {QStringLiteral("level"), QStringLiteral("ALL_LEVELS")},
                 {QStringLiteral("rating"),
                  QJsonObject{{QStringLiteral("average"), course.value(u"avg_rating")},
                              {QStringLiteral("count"), course.value(u"num_reviews")}}},
                 {QStringLiteral("urlCourseLanding"),
                  QString(QStringLiteral("https://www.udemy.com")
                          + course.value(u"url").toString())},
             }},
        };
        all.append(result);
        const QString text =
            (course.value(u"title").toString() + u' ' + course.value(u"headline").toString())
                .toLower();

        if (text.contains(search)) {
            matches.append(result);
        }
    }

    // Every course when nothing matches, so the demo always has something to show
    const QJsonArray results = matches.isEmpty() ? all : matches;

    return json(QJsonObject{
        {QStringLiteral("data"),
         QJsonObject{{QStringLiteral("courseSearch"),
                      QJsonObject{{QStringLiteral("count"), results.size()},
                                  {QStringLiteral("results"), results}}}}},
    });
}

// Prices for the sample courses, as /pricing/ answers
QByteArray prices(const QUrlQuery &query)
{
    const QJsonArray courses = QJsonDocument::fromJson(fixture(QStringLiteral("search.json")))
                                   .object()
                                   .value(u"results")
                                   .toArray();
    const QStringList ids = query.queryItemValue(QStringLiteral("course_ids")).split(u',');
    QJsonObject result;

    for (const QJsonValue &value : courses) {
        const QJsonObject course = value.toObject();
        const QString id = QString::number(course.value(u"id").toInteger());

        if (ids.contains(id)) {
            result.insert(id,
                          QJsonObject{{QStringLiteral("price"), course.value(u"price_detail")}});
        }
    }

    return json(QJsonObject{{QStringLiteral("courses"), result}});
}

// What a course page tells about a sample course
QByteArray courseDetails(qint64 courseId)
{
    QJsonObject course;
    const QJsonArray courses = QJsonDocument::fromJson(fixture(QStringLiteral("search.json")))
                                   .object()
                                   .value(u"results")
                                   .toArray();

    for (const QJsonValue &value : courses) {
        if (value.toObject().value(u"id").toInteger() == courseId) {
            course = value.toObject();
        }
    }

    const QString headline = course.value(u"headline").toString(QStringLiteral("A sample course"));

    return json(QJsonObject{
        {QStringLiteral("id"), courseId},
        {QStringLiteral("description"),
         QStringLiteral("<p><strong>%1.</strong></p>"
                        "<p>This sample course shows what a course page looks like on the big "
                        "screen. Real courses show the description their instructor wrote, "
                        "often several pages long.</p>"
                        "<ul><li>Short videos you can watch from the sofa</li>"
                        "<li>Slides next to the speaker</li>"
                        "<li>Captions in several languages</li></ul>"
                        "<p>Enroll to keep your place on every device.</p>")
             .arg(headline)},
        {QStringLiteral("objectives"),
         QJsonArray{QStringLiteral("Understand the ideas behind every tool you use"),
                    QStringLiteral("Build three projects from start to finish"),
                    QStringLiteral("Find and fix problems on your own"),
                    QStringLiteral("Know where to go next")}},
        {QStringLiteral("prerequisites"),
         QJsonArray{QStringLiteral("No experience needed"),
                    QStringLiteral("A computer for the exercises")}},
        {QStringLiteral("target_audiences"),
         QJsonArray{QStringLiteral("Beginners who want a guided start"),
                    QStringLiteral("Anyone who learns best by doing")}},
        {QStringLiteral("locale"),
         QJsonObject{{QStringLiteral("simple_english_title"), QStringLiteral("English")}}},
        {QStringLiteral("caption_languages"),
         QJsonArray{QStringLiteral("English"), QStringLiteral("Deutsch [Auto]")}},
        {QStringLiteral("last_update_date"), QStringLiteral("2026-09-01")},
        {QStringLiteral("visible_instructors"), course.value(u"visible_instructors").toArray()},
    });
}

// The outline of the sample curriculum, as course pages show it before buying
QByteArray landingCurriculum()
{
    const QJsonArray items = QJsonDocument::fromJson(fixture(QStringLiteral("curriculum.json")))
                                 .object()
                                 .value(u"results")
                                 .toArray();
    QJsonArray sections;
    QJsonObject section;
    int lectures = 0;
    double length = 0;

    for (const QJsonValue &value : items) {
        const QJsonObject item = value.toObject();

        if (item.value(u"_class").toString() == u"chapter") {
            if (!section.isEmpty()) {
                sections.append(section);
            }

            section = QJsonObject{{QStringLiteral("title"), item.value(u"title")},
                                  {QStringLiteral("lecture_count"), 0},
                                  {QStringLiteral("content_length"), 0}};
            continue;
        }

        const double duration =
            item.value(u"asset").toObject().value(u"time_estimation").toDouble();
        section.insert(QStringLiteral("lecture_count"),
                       section.value(u"lecture_count").toInt() + 1);
        section.insert(QStringLiteral("content_length"),
                       section.value(u"content_length").toDouble() + duration);
        ++lectures;
        length += duration;
    }

    if (!section.isEmpty()) {
        sections.append(section);
    }

    return json(QJsonObject{
        {QStringLiteral("curriculum_context"),
         QJsonObject{
             {QStringLiteral("data"),
              QJsonObject{{QStringLiteral("sections"), sections},
                          {QStringLiteral("num_of_published_lectures"), lectures},
                          {QStringLiteral("estimated_content_length_in_seconds"), length}}}}},
    });
}

}

DemoBackend::Response
DemoBackend::handle(const QString &method, const QUrl &url, const QByteArray &body) const
{
    const QString path = url.path().remove(QRegularExpression(QStringLiteral("^/api-2\\.0")));
    const QUrlQuery query(url);

    static const QRegularExpression lecturePath(
        QStringLiteral("^/users/me/subscribed-courses/(\\d+)/lectures/(\\d+)/$"));
    static const QRegularExpression progressPath(
        QStringLiteral("^/users/me/subscribed-courses/(\\d+)/progress/$"));
    static const QRegularExpression curriculumPath(
        QStringLiteral("^/courses/(\\d+)/subscriber-curriculum-items/$"));
    static const QRegularExpression coursePath(QStringLiteral("^/courses/(\\d+)/$"));
    static const QRegularExpression landingPath(
        QStringLiteral("^/course-landing-components/(\\d+)/me/$"));

    if (method == u"POST" && url.path() == u"/api/2024-01/graphql/") {
        return {200, searchResults(body)};
    }

    if (method != u"GET") {
        // Completing lectures and progress logs; nothing to remember in the demo
        return {201, QByteArrayLiteral("{}")};
    }

    if (path == u"/users/me/") {
        return {200, fixture(QStringLiteral("me.json"))};
    }

    if (path == u"/visits/current/") {
        return {200, QByteArrayLiteral("{}")};
    }

    if (path == u"/users/me/subscribed-courses/") {
        return {200,
                fixture(query.queryItemValue(QStringLiteral("is_archived")) == u"true"
                            ? QStringLiteral("archived.json")
                            : QStringLiteral("courses.json"))};
    }

    if (path == u"/users/me/subscription-course-enrollments/") {
        return {200,
                json({{QStringLiteral("count"), 0},
                      {QStringLiteral("next"), QJsonValue::Null},
                      {QStringLiteral("results"), QJsonArray()}})};
    }

    if (path == u"/pricing/") {
        return {200, prices(query)};
    }

    if (path == u"/users/me/wishlisted-courses/") {
        return {200, fixture(QStringLiteral("wishlist.json"))};
    }

    if (path == u"/users/me/subscribed-courses-collections/") {
        return {200, fixture(QStringLiteral("collections.json"))};
    }

    if (const auto match = coursePath.match(path); match.hasMatch()) {
        return {200, courseDetails(match.captured(1).toLongLong())};
    }

    if (landingPath.match(path).hasMatch()) {
        return {200, landingCurriculum()};
    }

    if (curriculumPath.match(path).hasMatch()) {
        return {200, fixture(QStringLiteral("curriculum.json"))};
    }

    if (progressPath.match(path).hasMatch()) {
        return {200, fixture(QStringLiteral("progress.json"))};
    }

    if (const auto match = lecturePath.match(path); match.hasMatch()) {
        const qint64 lectureId = match.captured(2).toLongLong();
        QJsonObject lecture = QJsonDocument::fromJson(fixture(lectureFixture(lectureId))).object();
        lecture.insert(QStringLiteral("id"), lectureId);
        const QString title = curriculumTitle(lectureId);

        if (!title.isEmpty()) {
            lecture.insert(QStringLiteral("title"), title);
        }

        return {200, json(lecture)};
    }

    return {404, QByteArrayLiteral(R"({"detail": "Not found."})")};
}
