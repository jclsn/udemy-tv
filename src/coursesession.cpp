// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "coursesession.h"

#include "udemyclient.h"

#include <QDateTime>
#include <QJsonObject>
#include <QRegularExpression>
#include <QSettings>
#include <QUrlQuery>

namespace
{
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

    m_loading = true;
    Q_EMIT loadingChanged();
    setError({});

    auto client = UdemyClient::instance();
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

    const QUrl url =
        client->apiUrl(QStringLiteral("courses/%1/subscriber-curriculum-items/").arg(courseId()),
                       query);
    client->getAllPages(url, this, [this](const QJsonArray &results, const QString &error) {
        m_curriculum->setItems(results);

        if (!error.isEmpty() && results.isEmpty()) {
            setError(error);
        }

        loadProgress();
    });
}

void CourseSession::loadProgress()
{
    auto client = UdemyClient::instance();
    QUrlQuery query;
    query.addQueryItem(
        QStringLiteral("fields[course]"),
        QStringLiteral(
            "completed_lecture_ids,completed_quiz_ids,last_seen_page,completed_assignment_ids"));
    const QUrl url =
        client->apiUrl(QStringLiteral("users/me/subscribed-courses/%1/progress/").arg(courseId()),
                       query);
    client->get(url, this, [this](const UdemyClient::Reply &reply) {
        const QJsonObject object = reply.json.object();
        QSet<qint64> lectures;
        QSet<qint64> quizzes;

        for (const QJsonValue &value : object.value(u"completed_lecture_ids").toArray()) {
            lectures.insert(value.toInteger());
        }

        for (const QJsonValue &value : object.value(u"completed_quiz_ids").toArray()) {
            quizzes.insert(value.toInteger());
        }

        m_curriculum->setCompletedIds(lectures, quizzes);

        // Usually the path of the lecture, such as "/course/x/learn/lecture/123"
        static const QRegularExpression lecturePattern(QStringLiteral("lecture/(\\d+)"));
        const QJsonValue lastSeen = object.value(u"last_seen_page");
        const auto match = lecturePattern.match(
            lastSeen.isString() ? lastSeen.toString()
                                : QString::number(lastSeen.toObject().value(u"id").toInteger()));
        m_lastSeenLecture = match.hasMatch() ? match.captured(1).toLongLong() : 0;

        updateResumeRow();
        Q_EMIT progressChanged();
        m_loading = false;
        Q_EMIT loadingChanged();
    });
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
