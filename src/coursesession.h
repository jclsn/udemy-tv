// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include "curriculummodel.h"

#include <QElapsedTimer>
#include <QJsonObject>
#include <QObject>
#include <QQmlEngine>
#include <QVariantMap>

/*!
   \brief An enrolled course being taken: its curriculum, what is completed, and where to continue.
 */
class CourseSession : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QVariantMap course READ course WRITE setCourse NOTIFY courseChanged)
    Q_PROPERTY(qint64 courseId READ courseId NOTIFY courseChanged)
    Q_PROPERTY(CurriculumModel *curriculum READ curriculum CONSTANT)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(int lectureCount READ lectureCount NOTIFY progressChanged)
    Q_PROPERTY(int completedCount READ completedCount NOTIFY progressChanged)
    Q_PROPERTY(double progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(int resumeRow READ resumeRow NOTIFY resumeRowChanged)
    Q_PROPERTY(QString totalDuration READ totalDuration NOTIFY loadingChanged)

public:
    explicit CourseSession(QObject *parent = nullptr);

    QVariantMap course() const;
    void setCourse(const QVariantMap &course);
    qint64 courseId() const;
    CurriculumModel *curriculum() const;
    bool loading() const;
    QString error() const;
    int lectureCount() const;
    int completedCount() const;
    double progress() const;
    int resumeRow() const;
    QString totalDuration() const;

    Q_INVOKABLE void load();

    /*!
       \brief The row's item, as {id, itemClass, title, number, section, sectionTitle, duration,
       completed}.
     */
    Q_INVOKABLE QVariantMap item(int row) const;

    /*!
       \brief The next or previous lecture from \a row, skipping quizzes and exercises. -1 if none.
     */
    Q_INVOKABLE int nextLecture(int row) const;
    Q_INVOKABLE int previousLecture(int row) const;

    Q_INVOKABLE void setCompleted(int row, bool completed);

    /*!
       \brief Remembers the position in a lecture, here and on Udemy, for resuming later.
     */
    Q_INVOKABLE void reportPosition(int row, double position, double duration);
    Q_INVOKABLE double savedPosition(int row) const;

    /*!
       \brief Marks the row as the one to continue with next time.
     */
    Q_INVOKABLE void setCurrentRow(int row);

    /*!
       \brief The address of an item in Udemy's web player.
     */
    Q_INVOKABLE QUrl webUrl(int row) const;

    /*!
       \brief Loads a course's curriculum and progress into the cache, for its page to open at
       once later.
     */
    static void prefetch(qint64 courseId);

Q_SIGNALS:
    void courseChanged();
    void loadingChanged();
    void errorChanged();
    void progressChanged();
    void resumeRowChanged();

private:
    void applyProgress(const QJsonObject &progress);
    void updateResumeRow();
    void setError(const QString &error);

    QVariantMap m_course;
    CurriculumModel *m_curriculum;
    bool m_loading = false;
    QString m_error;
    int m_resumeRow = -1;
    qint64 m_lastSeenLecture = 0;
    QJsonObject m_progress;
    QElapsedTimer m_lastReport;
};
