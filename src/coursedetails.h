// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QJsonObject>
#include <QObject>
#include <QQmlEngine>
#include <QStringList>
#include <QVariantList>

/*!
   \brief What a course's page on udemy.com tells about it, for courses not bought yet.

   \code
   CourseDetails {
       courseId: course.id
   }
   \endcode
 */
class CourseDetails : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(qint64 courseId READ courseId WRITE setCourseId NOTIFY courseIdChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString error READ error NOTIFY detailsChanged)

    // HTML, as written by the instructor
    Q_PROPERTY(QString description READ description NOTIFY detailsChanged)
    Q_PROPERTY(QStringList objectives READ objectives NOTIFY detailsChanged)
    Q_PROPERTY(QStringList prerequisites READ prerequisites NOTIFY detailsChanged)
    Q_PROPERTY(QStringList targetAudiences READ targetAudiences NOTIFY detailsChanged)
    Q_PROPERTY(QString language READ language NOTIFY detailsChanged)
    Q_PROPERTY(QStringList captionLanguages READ captionLanguages NOTIFY detailsChanged)
    Q_PROPERTY(QString lastUpdated READ lastUpdated NOTIFY detailsChanged)
    Q_PROPERTY(int students READ students NOTIFY detailsChanged)

    // [{name, jobTitle, image}]
    Q_PROPERTY(QVariantList instructors READ instructors NOTIFY detailsChanged)

    // [{title, lectures, length}], length as "1hr 20min"
    Q_PROPERTY(QVariantList sections READ sections NOTIFY curriculumChanged)
    Q_PROPERTY(int lectureCount READ lectureCount NOTIFY curriculumChanged)
    Q_PROPERTY(QString totalLength READ totalLength NOTIFY curriculumChanged)

public:
    using QObject::QObject;

    qint64 courseId() const;
    void setCourseId(qint64 id);
    bool loading() const;
    QString error() const;
    QString description() const;
    QStringList objectives() const;
    QStringList prerequisites() const;
    QStringList targetAudiences() const;
    QString language() const;
    QStringList captionLanguages() const;
    QString lastUpdated() const;
    int students() const;
    QVariantList instructors() const;
    QVariantList sections() const;
    int lectureCount() const;
    QString totalLength() const;

    /*!
       \brief Loads a course's page into the cache, for it to open at once later.
     */
    static void prefetch(qint64 courseId);

Q_SIGNALS:
    void courseIdChanged();
    void loadingChanged();
    void detailsChanged();
    void curriculumChanged();

private:
    void load();
    void setLoading(bool loading);
    void applyDetails(const QJsonObject &course);
    void applyOutline(const QJsonObject &data);

    qint64 m_courseId = 0;
    bool m_loading = false; // The texts are on their way, and none were cached
    int m_generation = 0;
    QString m_error;
    QString m_description;
    QStringList m_objectives;
    QStringList m_prerequisites;
    QStringList m_targetAudiences;
    QString m_language;
    QStringList m_captionLanguages;
    QString m_lastUpdated;
    int m_students = 0;
    QVariantList m_instructors;
    QVariantList m_sections;
    int m_lectureCount = 0;
    QString m_totalLength;
};
