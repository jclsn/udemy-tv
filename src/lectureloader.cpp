// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "lectureloader.h"

#include "lectureparser.h"
#include "udemyclient.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QJsonObject>
#include <QPointer>
#include <QStandardPaths>
#include <QTimer>
#include <QUrlQuery>

#include <memory>

namespace
{
// Media links in a lecture are signed for a while; well within that, a prefetched one is used
constexpr qint64 PrefetchLifetimeMs = 10 * 60 * 1000;

struct Prefetch {
    qint64 started = 0;
    bool done = false;
    UdemyClient::Reply reply;
    QList<std::function<void(const UdemyClient::Reply &)>> waiting;
};

QHash<QPair<qint64, qint64>, std::shared_ptr<Prefetch>> &prefetches()
{
    static QHash<QPair<qint64, qint64>, std::shared_ptr<Prefetch>> prefetches;

    return prefetches;
}

QUrl lectureUrl(qint64 courseId, qint64 lectureId)
{
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("fields[lecture]"),
                       QStringLiteral("title,description,asset,last_watched_second,is_free"));
    query.addQueryItem(QStringLiteral("fields[asset]"),
                       QStringLiteral("asset_type,title,length,time_estimation,status,"
                                      "media_license_token,course_is_drmed,media_sources,"
                                      "captions,thumbnail_url,slides,slide_urls,download_urls,"
                                      "external_url,stream_urls,body,data"));

    return UdemyClient::instance()->apiUrl(
        QStringLiteral("users/me/subscribed-courses/%1/lectures/%2/").arg(courseId).arg(lectureId),
        query);
}

// A prefetch of the lecture that is recent enough to use, taken out of the list
std::shared_ptr<Prefetch> takePrefetch(qint64 courseId, qint64 lectureId)
{
    const auto prefetch = prefetches().take({courseId, lectureId});

    if (!prefetch || QDateTime::currentMSecsSinceEpoch() - prefetch->started > PrefetchLifetimeMs) {
        return nullptr;
    }

    return prefetch;
}
}

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

    // Loaded ahead, or still on its way
    if (const auto prefetch = takePrefetch(m_courseId, m_lectureId)) {
        if (prefetch->done) {
            apply(generation, prefetch->reply);
        } else {
            QPointer<LectureLoader> guard(this);
            prefetch->waiting.append([guard, generation](const UdemyClient::Reply &reply) {
                if (guard) {
                    guard->apply(generation, reply);
                }
            });
        }

        return;
    }

    UdemyClient::instance()->get(lectureUrl(m_courseId, m_lectureId),
                                 this,
                                 [this, generation](const UdemyClient::Reply &reply) {
                                     apply(generation, reply);
                                 });
}

void LectureLoader::apply(int generation, const UdemyClient::Reply &reply)
{
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
}

void LectureLoader::prefetchLecture(qint64 lectureId)
{
    prefetch(m_courseId, lectureId);
}

void LectureLoader::prefetch(qint64 courseId, qint64 lectureId)
{
    auto client = UdemyClient::instance();

    if (courseId <= 0 || lectureId <= 0 || client->demoMode()) {
        return;
    }

    const QPair<qint64, qint64> key{courseId, lectureId};
    const auto existing = prefetches().value(key);
    const qint64 now = QDateTime::currentMSecsSinceEpoch();

    // Fetched not long ago; half the lifetime is left for the lecture to be opened
    if (existing && now - existing->started < PrefetchLifetimeMs / 2) {
        return;
    }

    auto prefetch = std::make_shared<Prefetch>();
    prefetch->started = now;
    prefetches().insert(key, prefetch);

    client->get(lectureUrl(courseId, lectureId),
                client,
                [prefetch, key](const UdemyClient::Reply &reply) {
                    prefetch->done = true;
                    prefetch->reply = reply;

                    // A failure is not kept; opening the lecture asks again
                    if (!reply.ok() && prefetches().value(key) == prefetch) {
                        prefetches().remove(key);
                    }

                    const auto waiting = std::exchange(prefetch->waiting, {});

                    for (const auto &callback : waiting) {
                        callback(reply);
                    }
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
