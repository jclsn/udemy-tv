// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "coursesession.h"

#include "apicache.h"
#include "udemyclient.h"

#include <QDateTime>
#include <QJsonObject>
#include <QRegularExpression>
#include <QSettings>
#include <QUrlQuery>

namespace
{
// How old a prefetched curriculum may be before it is loaded again, in seconds
constexpr qint64 PrefetchMaxAgeSeconds = 10 * 60;

QString curriculumKey(qint64 courseId)
{
    return QStringLiteral("course/%1/curriculum").arg(courseId);
}

QString progressKey(qint64 courseId)
{
    return QStringLiteral("course/%1/progress").arg(courseId);
}

QUrl curriculumUrl(qint64 courseId)
{
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("page_size"), QStringLiteral("200"));
    query.addQueryItem(QStringLiteral("fields[lecture]"),
                       QStringLiteral("title,object_index,is_published,sort_order,asset"));
    query.addQueryItem(QStringLiteral("fields[quiz]"),
                       QStringLiteral("title,object_index,is_published,sort_order,type"));
    query.addQueryItem(QStringLiteral("fields[practice]"),
                       QStringLiteral("title,object_index,is_published,sort_order"));
    query.addQueryItem(QStringLiteral("fields[chapter]"),
                       QStringLiteral("title,object_index,is_published,sort_order"));
    query.addQueryItem(QStringLiteral("fields[asset]"),
                       QStringLiteral("title,asset_type,time_estimation,length,status"));
    query.addQueryItem(QStringLiteral("caching_intent"), QStringLiteral("True"));

    return UdemyClient::instance()->apiUrl(
        QStringLiteral("courses/%1/subscriber-curriculum-items/").arg(courseId),
        query);
}

QUrl progressUrl(qint64 courseId)
{
    QUrlQuery query;
    query.addQueryItem(
        QStringLiteral("fields[course]"),
        QStringLiteral(
            "completed_lecture_ids,completed_quiz_ids,last_seen_page,completed_assignment_ids"));

    return UdemyClient::instance()->apiUrl(
        QStringLiteral("users/me/subscribed-courses/%1/progress/").arg(courseId),
        query);
}

// How often the position is sent to Udemy while watching
constexpr qint64 ReportIntervalMs = 30000;

QString positionKey(qint64 lectureId)
{
    return QStringLiteral("positions/%1").arg(lectureId);
}

QString lastLectureKey(qint64 courseId)
{
    return QStringLiteral("lastLecture/%1").arg(courseId);
}
}

CourseSession::CourseSession(QObject *parent)
    : QObject(parent)
    , m_curriculum(new CurriculumModel(this))
{
}

QVariantMap CourseSession::course() const
{
    return m_course;
}

void CourseSession::setCourse(const QVariantMap &course)
{
    if (m_course == course) {
        return;
    }

    m_course = course;
    Q_EMIT courseChanged();
}

qint64 CourseSession::courseId() const
{
    return m_course.value(QStringLiteral("id")).toLongLong();
}

CurriculumModel *CourseSession::curriculum() const
{
    return m_curriculum;
}

bool CourseSession::loading() const
{
    return m_loading;
}

QString CourseSession::error() const
{
    return m_error;
}

int CourseSession::lectureCount() const
{
    return m_curriculum->lectureCount();
}

int CourseSession::completedCount() const
{
    return m_curriculum->completedLectureCount();
}

double CourseSession::progress() const
{
    const int total = lectureCount();

    return total > 0 ? double(completedCount()) / total : 0;
}

int CourseSession::resumeRow() const
{
    return m_resumeRow;
}

QString CourseSession::totalDuration() const
{
    double total = 0;

    for (int row = 0; row < m_curriculum->count(); ++row) {
        total += m_curriculum->item(row).duration;
    }

    return CurriculumModel::formatDuration(total, true);
}

void CourseSession::load()
{
    if (courseId() <= 0) {
        return;
    }

    setError({});

    // What Udemy answered last time, shown at once; the answers of now follow
    const QJsonArray cachedCurriculum =
        ApiCache::instance().read(curriculumKey(courseId())).array();
    const QJsonObject cachedProgress = ApiCache::instance().read(progressKey(courseId())).object();

    if (!cachedCurriculum.isEmpty()) {
        m_curriculum->setItems(cachedCurriculum);
        applyProgress(cachedProgress);
    }

    m_loading = cachedCurriculum.isEmpty();
    Q_EMIT loadingChanged();

    auto client = UdemyClient::instance();
    auto missing = std::make_shared<int>(2);

    auto done = [this, missing] {
        if (--*missing == 0 && m_loading) {
            m_loading = false;
            Q_EMIT loadingChanged();
        }
    };

    client->getAllPages(
        curriculumUrl(courseId()),
        this,
        [this, done, cachedCurriculum](const QJsonArray &results, const QString &error) {
            if (!error.isEmpty() && results.isEmpty()) {
                setError(cachedCurriculum.isEmpty() ? error : QString());
            } else if (results != cachedCurriculum) {
                ApiCache::instance().write(curriculumKey(courseId()), QJsonDocument(results));
                m_curriculum->setItems(results);
                applyProgress(m_progress);
            }

            done();
        });

    client->get(progressUrl(courseId()), this, [this, done](const UdemyClient::Reply &reply) {
        if (reply.ok()) {
            const QJsonObject progress = reply.json.object();
            ApiCache::instance().write(progressKey(courseId()), QJsonDocument(progress));
            applyProgress(progress);
        }

        done();
    });
}

void CourseSession::prefetch(qint64 courseId)
{
    // Courses change rarely; a curriculum from the last minutes is good enough
    qint64 age = 0;
    const bool cached = !ApiCache::instance().read(curriculumKey(courseId), &age).isNull();

    if (courseId <= 0 || (cached && age < PrefetchMaxAgeSeconds)) {
        return;
    }

    auto client = UdemyClient::instance();
    client->getAllPages(curriculumUrl(courseId),
                        client,
                        [courseId](const QJsonArray &results, const QString &error) {
                            if (error.isEmpty() || !results.isEmpty()) {
                                ApiCache::instance().write(curriculumKey(courseId),
                                                           QJsonDocument(results));
                            }
                        });
    client->get(progressUrl(courseId), client, [courseId](const UdemyClient::Reply &reply) {
        if (reply.ok()) {
            ApiCache::instance().write(progressKey(courseId), reply.json);
        }
    });
}

void CourseSession::applyProgress(const QJsonObject &progress)
{
    if (progress.isEmpty()) {
        return;
    }

    m_progress = progress;
    QSet<qint64> lectures;
    QSet<qint64> quizzes;

    for (const QJsonValue &value : progress.value(u"completed_lecture_ids").toArray()) {
        lectures.insert(value.toInteger());
    }

    for (const QJsonValue &value : progress.value(u"completed_quiz_ids").toArray()) {
        quizzes.insert(value.toInteger());
    }

    m_curriculum->setCompletedIds(lectures, quizzes);

    // Usually the path of the lecture, such as "/course/x/learn/lecture/123"
    static const QRegularExpression lecturePattern(QStringLiteral("lecture/(\\d+)"));
    const QJsonValue lastSeen = progress.value(u"last_seen_page");
    const auto match = lecturePattern.match(
        lastSeen.isString() ? lastSeen.toString()
                            : QString::number(lastSeen.toObject().value(u"id").toInteger()));
    m_lastSeenLecture = match.hasMatch() ? match.captured(1).toLongLong() : 0;

    updateResumeRow();
    Q_EMIT progressChanged();
}

void CourseSession::updateResumeRow()
{
    int row = -1;
    const qint64 localLast = QSettings().value(lastLectureKey(courseId())).toLongLong();

    if (localLast > 0) {
        row = m_curriculum->rowOf(localLast);
    }

    if (row < 0 && m_lastSeenLecture > 0) {
        row = m_curriculum->rowOf(m_lastSeenLecture);
    }

    if (row < 0) {
        // The first lecture not completed yet
        for (int i = 0; i < m_curriculum->count(); ++i) {
            const auto &item = m_curriculum->item(i);

            if (item.itemClass == u"lecture" && !item.completed) {
                row = i;
                break;
            }
        }
    }

    if (row < 0) {
        row = nextLecture(-1);
    }

    if (m_resumeRow != row) {
        m_resumeRow = row;
        Q_EMIT resumeRowChanged();
    }
}

QVariantMap CourseSession::item(int row) const
{
    if (row < 0 || row >= m_curriculum->count()) {
        return {};
    }

    const auto &item = m_curriculum->item(row);

    return {
        {QStringLiteral("row"), row},
        {QStringLiteral("id"), item.id},
        {QStringLiteral("itemClass"), item.itemClass},
        {QStringLiteral("title"), item.title},
        {QStringLiteral("number"), item.number},
        {QStringLiteral("section"), item.section},
        {QStringLiteral("sectionTitle"), m_curriculum->sectionTitle(item.section)},
        {QStringLiteral("assetType"), item.assetType},
        {QStringLiteral("duration"), item.duration},
        {QStringLiteral("completed"), item.completed},
    };
}

int CourseSession::nextLecture(int row) const
{
    for (int i = row + 1; i < m_curriculum->count(); ++i) {
        if (m_curriculum->item(i).itemClass == u"lecture") {
            return i;
        }
    }

    return -1;
}

int CourseSession::previousLecture(int row) const
{
    for (int i = row - 1; i >= 0; --i) {
        if (m_curriculum->item(i).itemClass == u"lecture") {
            return i;
        }
    }

    return -1;
}

void CourseSession::setCompleted(int row, bool completed)
{
    const auto item = m_curriculum->item(row);

    if (item.id == 0 || item.itemClass != u"lecture" || item.completed == completed) {
        return;
    }

    m_curriculum->setCompleted(row, completed);
    Q_EMIT progressChanged();

    auto client = UdemyClient::instance();
    auto onReply = [this, row, completed](const UdemyClient::Reply &reply) {
        if (!reply.ok() && reply.status != 400 && reply.status != 409) {
            // 400 and 409 mean it was already so; anything else did not happen
            m_curriculum->setCompleted(row, !completed);
            Q_EMIT progressChanged();
            setError(reply.error);
        }
    };

    if (completed) {
        const QJsonObject body{{QStringLiteral("lecture_id"), item.id},
                               {QStringLiteral("downloaded"), false}};
        client->post(
            client->apiUrl(QStringLiteral("users/me/subscribed-courses/%1/completed-lectures/")
                               .arg(courseId())),
            QJsonDocument(body),
            this,
            onReply);
    } else {
        client->deleteResource(
            client->apiUrl(QStringLiteral("users/me/subscribed-courses/%1/completed-lectures/%2/")
                               .arg(courseId())
                               .arg(item.id)),
            this,
            onReply);
    }
}

void CourseSession::reportPosition(int row, double position, double duration)
{
    const auto item = m_curriculum->item(row);

    if (item.id == 0 || position < 0) {
        return;
    }

    QSettings settings;

    // Near the end, the next visit should start over
    if (duration > 0 && position > duration - 15) {
        settings.remove(positionKey(item.id));
    } else {
        settings.setValue(positionKey(item.id), position);
    }

    if (m_lastReport.isValid() && m_lastReport.elapsed() < ReportIntervalMs) {
        return;
    }

    m_lastReport.start();

    // Udemy's web player sends logs like this one; it is undocumented, so failures are ignored
    auto client = UdemyClient::instance();
    const QJsonObject log{
        {QStringLiteral("isFullscreen"), true},
        {QStringLiteral("openPanel"), QStringLiteral("default")},
        {QStringLiteral("position"), position},
        {QStringLiteral("total"), duration},
        {QStringLiteral("context"),
         QJsonObject{{QStringLiteral("type"), QStringLiteral("Lecture")}}},
        {QStringLiteral("time"), QDateTime::currentDateTimeUtc().toString(Qt::ISODateWithMs)},
    };
    client->post(
        client->apiUrl(QStringLiteral("users/me/subscribed-courses/%1/lectures/%2/progress-logs/")
                           .arg(courseId())
                           .arg(item.id)),
        QJsonDocument(QJsonArray{log}),
        this,
        nullptr);
}

double CourseSession::savedPosition(int row) const
{
    const auto item = m_curriculum->item(row);

    return item.id == 0 ? 0 : QSettings().value(positionKey(item.id), 0.0).toDouble();
}

void CourseSession::setCurrentRow(int row)
{
    const auto item = m_curriculum->item(row);

    if (item.id == 0 || item.itemClass != u"lecture") {
        return;
    }

    QSettings().setValue(lastLectureKey(courseId()), item.id);

    if (m_resumeRow != row) {
        m_resumeRow = row;
        Q_EMIT resumeRowChanged();
    }
}

QUrl CourseSession::webUrl(int row) const
{
    const auto item = m_curriculum->item(row);
    QString path = m_course.value(QStringLiteral("url")).toString();

    if (path.isEmpty()) {
        return {};
    }

    if (!path.endsWith(u'/')) {
        path += u'/';
    }

    if (item.id > 0) {
        path += QStringLiteral("learn/%1/%2")
                    .arg(item.itemClass == u"lecture" ? QStringLiteral("lecture") : item.itemClass)
                    .arg(item.id);
    } else {
        path += QStringLiteral("learn/");
    }

    return UdemyClient::instance()->absoluteUrl(path);
}

void CourseSession::setError(const QString &error)
{
    if (m_error == error) {
        return;
    }

    m_error = error;
    Q_EMIT errorChanged();
}
