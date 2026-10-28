// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include "udemyclient.h"

#include <QObject>
#include <QQmlEngine>
#include <QVariantMap>

/*!
   \brief Loads one lecture: its streams, captions, slides or article text.

   See LectureParser for the contents of \l lecture.
 */
class LectureLoader : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(qint64 courseId READ courseId WRITE setCourseId NOTIFY courseIdChanged)
    Q_PROPERTY(qint64 lectureId READ lectureId WRITE setLectureId NOTIFY lectureIdChanged)
    Q_PROPERTY(QVariantMap lecture READ lecture NOTIFY lectureChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)

public:
    using QObject::QObject;

    qint64 courseId() const;
    void setCourseId(qint64 id);
    qint64 lectureId() const;
    void setLectureId(qint64 id);
    QVariantMap lecture() const;
    bool loading() const;
    QString error() const;

    Q_INVOKABLE void reload();

    /*!
       \brief Loads a lecture of this course ahead, such as the next one, so it starts sooner.
     */
    Q_INVOKABLE void prefetchLecture(qint64 lectureId);

    /*!
       \brief Loads a lecture ahead, for a LectureLoader to take over within a few minutes. Its
       links expire, so it is kept in memory only and used once.
     */
    static void prefetch(qint64 courseId, qint64 lectureId);

    /*!
       \brief Where the raw lecture JSON is saved when UDEMY_TV_DUMP_LECTURES is set.
     */
    static QString dumpDirectory();

Q_SIGNALS:
    void courseIdChanged();
    void lectureIdChanged();
    void lectureChanged();
    void loadingChanged();
    void errorChanged();

private:
    void scheduleLoad();
    void apply(int generation, const UdemyClient::Reply &reply);
    void setLoading(bool loading);
    void setError(const QString &error);

    qint64 m_courseId = 0;
    qint64 m_lectureId = 0;
    QVariantMap m_lecture;
    bool m_loading = false;
    bool m_loadScheduled = false;
    QString m_error;
    int m_generation = 0;
};
