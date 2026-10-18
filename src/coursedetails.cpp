// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "coursedetails.h"

#include "curriculummodel.h"
#include "udemyclient.h"

#include <QDate>
#include <QJsonArray>
#include <QJsonObject>
#include <QLocale>
#include <QUrlQuery>

namespace
{
QStringList toStringList(const QJsonValue &value)
{
    QStringList list;

    for (const QJsonValue &item : value.toArray()) {
        const QString text = item.toString().trimmed();

        if (!text.isEmpty()) {
            list.append(text);
        }
    }

    return list;
}
}

qint64 CourseDetails::courseId() const
{
    return m_courseId;
}

void CourseDetails::setCourseId(qint64 id)
{
    if (m_courseId == id) {
        return;
    }

    m_courseId = id;
    Q_EMIT courseIdChanged();
    load();
}

bool CourseDetails::loading() const
{
    return m_pending > 0;
}

QString CourseDetails::error() const
{
    return m_error;
}

QString CourseDetails::description() const
{
    return m_description;
}

QStringList CourseDetails::objectives() const
{
    return m_objectives;
}

QStringList CourseDetails::prerequisites() const
{
    return m_prerequisites;
}

QStringList CourseDetails::targetAudiences() const
{
    return m_targetAudiences;
}

QString CourseDetails::language() const
{
    return m_language;
}

QStringList CourseDetails::captionLanguages() const
{
    return m_captionLanguages;
}

QString CourseDetails::lastUpdated() const
{
    return m_lastUpdated;
}

int CourseDetails::students() const
{
    return m_students;
}

QVariantList CourseDetails::instructors() const
{
    return m_instructors;
}

QVariantList CourseDetails::sections() const
{
    return m_sections;
}

int CourseDetails::lectureCount() const
{
    return m_lectureCount;
}

QString CourseDetails::totalLength() const
{
    return m_totalLength;
}

void CourseDetails::setPending(int pending)
{
    const bool wasLoading = loading();
    m_pending = pending;

    if (wasLoading != loading()) {
        Q_EMIT loadingChanged();
    }
}

void CourseDetails::load()
{
    const int generation = ++m_generation;

    if (m_courseId <= 0) {
        setPending(0);

        return;
    }

    setPending(2);
    auto client = UdemyClient::instance();

    // The texts of the course page
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("fields[course]"),
                       QStringLiteral("description,objectives,prerequisites,target_audiences,"
                                      "locale,caption_languages,last_update_date,"
                                      "num_subscribers,visible_instructors"));
    query.addQueryItem(QStringLiteral("fields[user]"),
                       QStringLiteral("display_name,job_title,image_100x100"));
    const QUrl courseUrl = client->apiUrl(QStringLiteral("courses/%1/").arg(m_courseId), query);

    client->get(courseUrl, this, [this, generation](const UdemyClient::Reply &reply) {
        if (generation != m_generation) {
            return;
        }

        setPending(m_pending - 1);
        const QJsonObject course = reply.json.object();
        m_error = reply.error;
        m_description = course.value(u"description").toString();
        m_objectives = toStringList(course.value(u"objectives"));
        m_prerequisites = toStringList(course.value(u"prerequisites"));
        m_targetAudiences = toStringList(course.value(u"target_audiences"));
        m_captionLanguages = toStringList(course.value(u"caption_languages"));
        m_students = course.value(u"num_subscribers").toInt();

        const QJsonObject locale = course.value(u"locale").toObject();
        m_language =
            locale.value(u"simple_english_title").toString(locale.value(u"title").toString());

        const QDate updated =
            QDate::fromString(course.value(u"last_update_date").toString(), Qt::ISODate);
        m_lastUpdated =
            updated.isValid() ? QLocale().toString(updated, QStringLiteral("MM/yyyy")) : QString();

        m_instructors.clear();

        for (const QJsonValue &value : course.value(u"visible_instructors").toArray()) {
            const QJsonObject instructor = value.toObject();
            m_instructors.append(QVariantMap{
                {QStringLiteral("name"), instructor.value(u"display_name").toString()},
                {QStringLiteral("jobTitle"), instructor.value(u"job_title").toString()},
                {QStringLiteral("image"), instructor.value(u"image_100x100").toString()},
            });
        }

        Q_EMIT detailsChanged();
    });

    // The outline of the curriculum, as the course page shows it before buying
    QUrlQuery curriculumQuery;
    curriculumQuery.addQueryItem(QStringLiteral("components"),
                                 QStringLiteral("curriculum_context"));
    const QUrl curriculumUrl =
        client->apiUrl(QStringLiteral("course-landing-components/%1/me/").arg(m_courseId),
                       curriculumQuery);

    client->get(curriculumUrl, this, [this, generation](const UdemyClient::Reply &reply) {
        if (generation != m_generation) {
            return;
        }

        setPending(m_pending - 1);
        const QJsonObject data =
            reply.json.object().value(u"curriculum_context").toObject().value(u"data").toObject();
        m_sections.clear();
        m_lectureCount = data.value(u"num_of_published_lectures").toInt();

        for (const QJsonValue &value : data.value(u"sections").toArray()) {
            const QJsonObject section = value.toObject();
            const int lectures = section.value(u"lecture_count")
                                     .toInt(int(section.value(u"items").toArray().size()));
            m_sections.append(QVariantMap{
                {QStringLiteral("title"), section.value(u"title").toString()},
                {QStringLiteral("lectures"), lectures},
                {QStringLiteral("length"),
                 CurriculumModel::formatDuration(section.value(u"content_length").toDouble())},
            });
        }

        m_totalLength = CurriculumModel::formatDuration(
            data.value(u"estimated_content_length_in_seconds").toDouble(),
            true);
        Q_EMIT curriculumChanged();
    });
}
