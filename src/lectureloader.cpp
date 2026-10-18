// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "lectureloader.h"

#include "lectureparser.h"
#include "udemyclient.h"

#include <QDir>
#include <QFile>
#include <QJsonObject>
#include <QStandardPaths>
#include <QTimer>
#include <QUrlQuery>

qint64 LectureLoader::courseId() const
{
    return m_courseId;
}

void LectureLoader::setCourseId(qint64 id)
{
    if (m_courseId == id) {
        return;
    }

    m_courseId = id;
    Q_EMIT courseIdChanged();
    scheduleLoad();
}

qint64 LectureLoader::lectureId() const
{
    return m_lectureId;
}

void LectureLoader::setLectureId(qint64 id)
{
    if (m_lectureId == id) {
        return;
    }

    m_lectureId = id;
    Q_EMIT lectureIdChanged();
    scheduleLoad();
}

QVariantMap LectureLoader::lecture() const
{
    return m_lecture;
}

bool LectureLoader::loading() const
{
    return m_loading;
}

QString LectureLoader::error() const
{
    return m_error;
}

QString LectureLoader::dumpDirectory()
{
    return QStandardPaths::writableLocation(QStandardPaths::CacheLocation)
        + QStringLiteral("/lectures");
}

void LectureLoader::scheduleLoad()
{
    // Course and lecture usually change together
    if (m_loadScheduled) {
        return;
    }

    m_loadScheduled = true;
    QTimer::singleShot(0, this, &LectureLoader::reload);
}

void LectureLoader::reload()
{
    m_loadScheduled = false;
    const int generation = ++m_generation;

    m_lecture.clear();
    Q_EMIT lectureChanged();
    setError({});

    if (m_courseId <= 0 || m_lectureId <= 0) {
        setLoading(false);

        return;
    }

    setLoading(true);

    auto client = UdemyClient::instance();
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("fields[lecture]"),
                       QStringLiteral("title,description,asset,last_watched_second,is_free"));
    query.addQueryItem(QStringLiteral("fields[asset]"),
                       QStringLiteral("asset_type,title,length,time_estimation,status,"
                                      "media_license_token,course_is_drmed,media_sources,"
                                      "captions,thumbnail_url,slides,slide_urls,download_urls,"
                                      "external_url,stream_urls,body,data"));
    const QUrl url = client->apiUrl(QStringLiteral("users/me/subscribed-courses/%1/lectures/%2/")
                                        .arg(m_courseId)
                                        .arg(m_lectureId),
                                    query);

    client->get(url, this, [this, generation](const UdemyClient::Reply &reply) {
        if (generation != m_generation) {
            return;
        }

        setLoading(false);

        if (!reply.ok()) {
            setError(reply.error);

            return;
        }

        // The API is undocumented; keeping the raw data helps when a lecture type is not understood
        if (qEnvironmentVariableIsSet("UDEMY_TV_DUMP_LECTURES")) {
            QDir().mkpath(dumpDirectory());
            QFile file(dumpDirectory() + QStringLiteral("/%1.json").arg(m_lectureId));

            if (file.open(QIODevice::WriteOnly)) {
                file.write(reply.json.toJson(QJsonDocument::Indented));
                qInfo() << "Saved lecture data to" << file.fileName();
            }
        }

        m_lecture = LectureParser::parse(reply.json.object());
        Q_EMIT lectureChanged();
    });
}

void LectureLoader::setLoading(bool loading)
{
    if (m_loading == loading) {
        return;
    }

    m_loading = loading;
    Q_EMIT loadingChanged();
}

void LectureLoader::setError(const QString &error)
{
    if (m_error == error) {
        return;
    }

    m_error = error;
    Q_EMIT errorChanged();
}
