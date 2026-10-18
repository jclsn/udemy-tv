// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QAbstractListModel>
#include <QJsonArray>
#include <QQmlEngine>
#include <QSet>

/*!
   \brief The lectures, quizzes and exercises of a course, in order. Each row knows its section,
   for the view's section headers.
 */
class CurriculumModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by CourseSession")

    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(int sectionCount READ sectionCount NOTIFY countChanged)
    // Changes whenever a section's numbers do, for bindings on sectionInfo()
    Q_PROPERTY(int revision READ revision NOTIFY revisionChanged)

public:
    enum Roles {
        ItemIdRole = Qt::UserRole + 1,
        ItemClassRole, // "lecture", "quiz", "practice" or "assignment"
        TitleRole,
        NumberRole, // The number Udemy shows before the title
        SectionIndexRole,
        SectionKeyRole, // Unique per section, for ListView.section
        AssetTypeRole,
        DurationRole, // Seconds
        CompletedRole,
        PlayableRole,
    };

    struct Item {
        qint64 id = 0;
        QString itemClass;
        QString title;
        int number = 0;
        int section = -1;
        QString assetType;
        double duration = 0;
        bool completed = false;
    };

    struct Section {
        QString title;
        int number = 0;
    };

    explicit CurriculumModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const;
    int sectionCount() const;
    int revision() const;

    /*!
       \brief Fills the model from subscriber-curriculum-items results.
     */
    void setItems(const QJsonArray &results);
    void setCompletedIds(const QSet<qint64> &lectureIds, const QSet<qint64> &quizIds);
    void setCompleted(int row, bool completed);

    const Item &item(int row) const;
    int rowOf(qint64 itemId, const QString &itemClass = QStringLiteral("lecture")) const;

    Q_INVOKABLE QString sectionTitle(int section) const;
    /*!
       \brief "3 / 10 | 45min", as Udemy shows under a section's title.
     */
    Q_INVOKABLE QString sectionInfo(int section) const;

    int lectureCount() const;
    int completedLectureCount() const;

    static QString formatDuration(double seconds, bool longForm = false);

Q_SIGNALS:
    void countChanged();
    void revisionChanged();

private:
    QList<Item> m_items;
    QList<Section> m_sections;
    int m_revision = 0;
};
