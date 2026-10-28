// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include "udemyclient.h"

#include <QAbstractListModel>
#include <QJsonArray>
#include <QQmlEngine>
#include <QSet>
#include <QTimer>

/*!
   \brief A list of courses: the user's courses, a wishlist, a list or search results.
 */
class CourseListModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(Source source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(QString query READ query WRITE setQuery NOTIFY queryChanged)
    Q_PROPERTY(ProgressFilter progressFilter READ progressFilter WRITE setProgressFilter NOTIFY
                   progressFilterChanged)
    Q_PROPERTY(Ordering ordering READ ordering WRITE setOrdering NOTIFY orderingChanged)
    Q_PROPERTY(QStringList collections READ collections NOTIFY collectionsChanged)
    Q_PROPERTY(int collectionIndex READ collectionIndex WRITE setCollectionIndex NOTIFY
                   collectionIndexChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(int totalCount READ totalCount NOTIFY countChanged)

public:
    enum Source {
        Enrolled,
        Archived,
        Wishlist,
        Collections,
        Search,
    };
    Q_ENUM(Source)

    enum ProgressFilter {
        AnyProgress,
        InProgress,
        NotStarted,
        Completed,
    };
    Q_ENUM(ProgressFilter)

    enum Ordering {
        RecentlyAccessed,
        TitleAscending,
        TitleDescending,
    };
    Q_ENUM(Ordering)

    enum Roles {
        CourseIdRole = Qt::UserRole + 1,
        TitleRole,
        HeadlineRole,
        ImageRole,
        LargeImageRole,
        InstructorsRole,
        ProgressRole, // 0 to 1
        UrlRole,
        NumLecturesRole,
        RatingRole,
        NumReviewsRole,
        PriceRole,
        ContentInfoRole,
        EnrolledRole,
        CourseRole, // The whole course, as a map
    };

    explicit CourseListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Source source() const;
    void setSource(Source source);
    QString query() const;
    void setQuery(const QString &query);
    ProgressFilter progressFilter() const;
    void setProgressFilter(ProgressFilter filter);
    Ordering ordering() const;
    void setOrdering(Ordering ordering);
    QStringList collections() const;
    int collectionIndex() const;
    void setCollectionIndex(int index);
    bool loading() const;
    QString error() const;
    int count() const;
    int totalCount() const;

    Q_INVOKABLE void reload();

    /*!
       \brief Loads a course's page ahead, such as while its card has the focus, so it opens at
       once: the curriculum of your own courses, the store page of others.
     */
    Q_INVOKABLE void prefetchCourse(qint64 courseId);
    Q_INVOKABLE QVariantMap get(int row) const;

    /*!
       \brief Turns a course from the API into the map the pages use.
     */
    static QVariantMap normalizeCourse(const QJsonObject &course);

    /*!
       \brief Turns a course from the GraphQL catalog search into the same map.
     */
    static QVariantMap normalizeSearchResult(const QJsonObject &course);

    /*!
       \brief The courses the user is enrolled in, for marking them in search results.
     */
    static QSet<qint64> &enrolledIds();

Q_SIGNALS:
    void sourceChanged();
    void queryChanged();
    void progressFilterChanged();
    void orderingChanged();
    void collectionsChanged();
    void collectionIndexChanged();
    void loadingChanged();
    void errorChanged();
    void countChanged();

private:
    void setLoading(bool loading);
    void setError(const QString &error);
    void setAll(const QList<QVariantMap> &courses);
    QString cacheKey() const;
    void showResults(const QJsonArray &results);
    void loadEnrolled(const UdemyClient::PageCallback &finish);
    void search(int generation);
    static QList<QVariantMap> toCourses(const QJsonArray &results);
    void applyFilter();
    void loadPrices(int generation);

    Source m_source = Enrolled;
    QString m_query;
    ProgressFilter m_progressFilter = AnyProgress;
    Ordering m_ordering = RecentlyAccessed;
    QList<QVariantMap> m_all; // Before filtering
    QList<QVariantMap> m_courses;
    QStringList m_collectionTitles;
    QList<QList<QVariantMap>> m_collectionCourses;
    int m_collectionIndex = 0;
    bool m_loading = false;
    QString m_error;
    int m_generation = 0; // Drops replies to requests made before a reload
    QTimer m_reloadTimer;
};
