// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "courselistmodel.h"

#include "apicache.h"
#include "coursesession.h"
#include "udemyclient.h"

#include <QCollator>
#include <QDateTime>
#include <QJsonObject>
#include <QUrlQuery>

#include <algorithm>

namespace
{
// What the cards and pages of your own courses show. Prices and ratings take Udemy twice as long
// to look up, so they are only asked for where the store needs them.
const QString CourseFields = QStringLiteral(
    "id,title,headline,url,published_title,image_240x135,image_480x270,image_750x422,"
    "visible_instructors,completion_ratio,num_published_lectures,last_accessed_time,"
    "enrollment_time,archive_time,content_info");
const QString StoreCourseFields = CourseFields
    + QStringLiteral(",favorite_time,avg_rating,avg_rating_recent,rating,num_reviews,price,"
                     "price_detail,is_paid,instructional_level,num_subscribers,"
                     "is_practice_test_course");

// Udemy's own search page uses this GraphQL query; the old REST catalog is gone
const QString SearchQuery = QStringLiteral(
    "query TvCourseSearch($query: String!, $page: NonNegativeInt!,"
    " $pageSize: MaxResultsPerPage!, $context: CourseSearchContext!) {"
    " courseSearch(query: $query, page: $page, pageSize: $pageSize, sortOrder: RELEVANCE,"
    " context: $context) { count results { course { id title headline durationInSeconds"
    " images { px480x270 } instructors { name } isFree level rating { average count }"
    " urlCourseLanding curriculum { contentCounts { lecturesCount } } } } } }");

QUrlQuery courseQuery(const QString &fields = CourseFields)
{
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("page_size"), QStringLiteral("100"));
    query.addQueryItem(QStringLiteral("fields[course]"), fields);
    query.addQueryItem(QStringLiteral("fields[user]"), QStringLiteral("display_name,job_title"));

    return query;
}
}

CourseListModel::CourseListModel(QObject *parent)
    : QAbstractListModel(parent)
{
    // Coalesce property changes made while QML creates the model into one load
    m_reloadTimer.setSingleShot(true);
    m_reloadTimer.setInterval(0);
    connect(&m_reloadTimer, &QTimer::timeout, this, &CourseListModel::reload);
    m_reloadTimer.start();

    connect(UdemyClient::instance(), &UdemyClient::authStateChanged, this, [this] {
        if (UdemyClient::instance()->authState() == UdemyClient::LoggedIn) {
            m_reloadTimer.start();
        }
    });
}

QSet<qint64> &CourseListModel::enrolledIds()
{
    static QSet<qint64> ids;

    return ids;
}

int CourseListModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_courses.size();
}

QVariant CourseListModel::data(const QModelIndex &index, int role) const
{
    if (!checkIndex(index, CheckIndexOption::IndexIsValid)) {
        return {};
    }

    const QVariantMap &course = m_courses.at(index.row());

    switch (role) {
    case CourseIdRole:
        return course.value(QStringLiteral("id"));
    case Qt::DisplayRole:
    case TitleRole:
        return course.value(QStringLiteral("title"));
    case HeadlineRole:
        return course.value(QStringLiteral("headline"));
    case ImageRole:
        return course.value(QStringLiteral("image"));
    case LargeImageRole:
        return course.value(QStringLiteral("imageLarge"));
    case InstructorsRole:
        return course.value(QStringLiteral("instructors"));
    case ProgressRole:
        return course.value(QStringLiteral("progress"));
    case UrlRole:
        return course.value(QStringLiteral("url"));
    case NumLecturesRole:
        return course.value(QStringLiteral("numLectures"));
    case RatingRole:
        return course.value(QStringLiteral("rating"));
    case NumReviewsRole:
        return course.value(QStringLiteral("numReviews"));
    case PriceRole:
        return course.value(QStringLiteral("price"));
    case ContentInfoRole:
        return course.value(QStringLiteral("contentInfo"));
    case EnrolledRole:
        return enrolledIds().contains(course.value(QStringLiteral("id")).toLongLong());
    case CourseRole:
        return course;
    }

    return {};
}

QHash<int, QByteArray> CourseListModel::roleNames() const
{
    return {
        {CourseIdRole, "courseId"},
        {TitleRole, "title"},
        {HeadlineRole, "headline"},
        {ImageRole, "image"},
        {LargeImageRole, "largeImage"},
        {InstructorsRole, "instructors"},
        {ProgressRole, "progress"},
        {UrlRole, "url"},
        {NumLecturesRole, "numLectures"},
        {RatingRole, "rating"},
        {NumReviewsRole, "numReviews"},
        {PriceRole, "price"},
        {ContentInfoRole, "contentInfo"},
        {EnrolledRole, "enrolled"},
        {CourseRole, "course"},
    };
}

CourseListModel::Source CourseListModel::source() const
{
    return m_source;
}

void CourseListModel::setSource(Source source)
{
    if (m_source == source) {
        return;
    }

    m_source = source;
    Q_EMIT sourceChanged();
    m_reloadTimer.start();
}

QString CourseListModel::query() const
{
    return m_query;
}

void CourseListModel::setQuery(const QString &query)
{
    if (m_query == query) {
        return;
    }

    m_query = query;
    Q_EMIT queryChanged();

    if (m_source == Search) {
        m_reloadTimer.start();
    }
}

CourseListModel::ProgressFilter CourseListModel::progressFilter() const
{
    return m_progressFilter;
}

void CourseListModel::setProgressFilter(ProgressFilter filter)
{
    if (m_progressFilter == filter) {
        return;
    }

    m_progressFilter = filter;
    Q_EMIT progressFilterChanged();
    applyFilter();
}

CourseListModel::Ordering CourseListModel::ordering() const
{
    return m_ordering;
}

void CourseListModel::setOrdering(Ordering ordering)
{
    if (m_ordering == ordering) {
        return;
    }

    m_ordering = ordering;
    Q_EMIT orderingChanged();
    applyFilter();
}

QStringList CourseListModel::collections() const
{
    return m_collectionTitles;
}

int CourseListModel::collectionIndex() const
{
    return m_collectionIndex;
}

void CourseListModel::setCollectionIndex(int index)
{
    if (m_collectionIndex == index) {
        return;
    }

    m_collectionIndex = index;
    Q_EMIT collectionIndexChanged();

    if (m_source == Collections) {
        setAll(m_collectionCourses.value(index));
    }
}

bool CourseListModel::loading() const
{
    return m_loading;
}

QString CourseListModel::error() const
{
    return m_error;
}

int CourseListModel::count() const
{
    return m_courses.size();
}

int CourseListModel::totalCount() const
{
    return m_all.size();
}

QVariantMap CourseListModel::get(int row) const
{
    return m_courses.value(row);
}

QVariantMap CourseListModel::normalizeCourse(const QJsonObject &course)
{
    QStringList instructors;

    for (const QJsonValue &value : course.value(u"visible_instructors").toArray()) {
        const QString name = value.toObject()
                                 .value(u"display_name")
                                 .toString(value.toObject().value(u"title").toString());

        if (!name.isEmpty()) {
            instructors.append(name);
        }
    }

    double rating = course.value(u"avg_rating_recent").toDouble();

    if (rating <= 0) {
        rating = course.value(u"avg_rating").toDouble(course.value(u"rating").toDouble());
    }

    QString price = course.value(u"price_detail").toObject().value(u"price_string").toString();

    if (price.isEmpty()) {
        price = course.value(u"price").toString();
    }

    if (course.contains(u"is_paid") && !course.value(u"is_paid").toBool()) {
        price = QStringLiteral("Free");
    }

    QString image = course.value(u"image_480x270").toString();

    if (image.isEmpty()) {
        image = course.value(u"image_240x135").toString();
    }

    QString imageLarge = course.value(u"image_750x422").toString();

    if (imageLarge.isEmpty()) {
        imageLarge = image;
    }

    const qint64 id = course.value(u"id").toInteger();
    QString url = course.value(u"url").toString();

    if (url.isEmpty() && !course.value(u"published_title").toString().isEmpty()) {
        url = QStringLiteral("/course/%1/").arg(course.value(u"published_title").toString());
    }

    QString lastAccessed = course.value(u"last_accessed_time").toString();

    if (lastAccessed.isEmpty()) {
        lastAccessed = course.value(u"enrollment_time").toString();
    }

    return {
        {QStringLiteral("id"), id},
        {QStringLiteral("title"), course.value(u"title").toString()},
        {QStringLiteral("headline"), course.value(u"headline").toString()},
        {QStringLiteral("image"), image},
        {QStringLiteral("imageLarge"), imageLarge},
        {QStringLiteral("instructors"), instructors.join(QStringLiteral(", "))},
        {QStringLiteral("progress"),
         std::clamp(course.value(u"completion_ratio").toDouble() / 100.0, 0.0, 1.0)},
        {QStringLiteral("url"), url},
        {QStringLiteral("numLectures"), course.value(u"num_published_lectures").toInt()},
        {QStringLiteral("rating"), rating},
        {QStringLiteral("numReviews"), course.value(u"num_reviews").toInt()},
        {QStringLiteral("price"), price},
        {QStringLiteral("contentInfo"), course.value(u"content_info").toString()},
        {QStringLiteral("level"), course.value(u"instructional_level").toString()},
        {QStringLiteral("students"), course.value(u"num_subscribers").toInt()},
        {QStringLiteral("lastAccessed"),
         QDateTime::fromString(lastAccessed, Qt::ISODate).toMSecsSinceEpoch()},
        {QStringLiteral("archived"), !course.value(u"archive_time").toString().isEmpty()},
    };
}

QString CourseListModel::cacheKey() const
{
    switch (m_source) {
    case Enrolled:
        return QStringLiteral("courses/enrolled");
    case Archived:
        return QStringLiteral("courses/archived");
    case Wishlist:
        return QStringLiteral("courses/wishlist");
    case Collections:
        return QStringLiteral("courses/collections");
    case Search:
        break;
    }

    // Search results depend on the words, and are not worth keeping
    return {};
}

QList<QVariantMap> CourseListModel::toCourses(const QJsonArray &results)
{
    QList<QVariantMap> courses;

    for (const QJsonValue &value : results) {
        const QJsonObject object = value.toObject();

        // Some lists wrap the course, as {"course": {...}}
        courses.append(normalizeCourse(
            object.contains(u"course") ? object.value(u"course").toObject() : object));
    }

    return courses;
}

void CourseListModel::showResults(const QJsonArray &results)
{
    if (m_source != Collections) {
        const QList<QVariantMap> courses = toCourses(results);

        if (m_source == Enrolled) {
            for (const QVariantMap &course : courses) {
                enrolledIds().insert(course.value(QStringLiteral("id")).toLongLong());
            }
        }

        setAll(courses);

        return;
    }

    m_collectionTitles.clear();
    m_collectionCourses.clear();

    for (const QJsonValue &value : results) {
        const QJsonObject collection = value.toObject();
        m_collectionTitles.append(collection.value(u"title").toString());
        m_collectionCourses.append(toCourses(collection.value(u"courses").toArray()));
    }

    Q_EMIT collectionsChanged();

    if (m_collectionIndex >= m_collectionTitles.size()) {
        m_collectionIndex = 0;
        Q_EMIT collectionIndexChanged();
    }

    setAll(m_collectionCourses.value(m_collectionIndex));
}

void CourseListModel::reload()
{
    m_reloadTimer.stop();
    const int generation = ++m_generation;
    auto client = UdemyClient::instance();
    setError({});

    // Reloads again once signed in
    if (client->authState() != UdemyClient::LoggedIn) {
        setAll({});
        setLoading(client->authState() == UdemyClient::Connecting);

        return;
    }

    if (m_source == Search) {
        search(generation);

        return;
    }

    // Show what Udemy answered last time at once, then what it answers now
    const QString key = cacheKey();
    const QJsonArray cached = ApiCache::instance().read(key).array();

    if (!cached.isEmpty()) {
        showResults(cached);
    } else {
        setAll({});
    }

    setLoading(true);

    auto finish = [=, this](const QJsonArray &results, const QString &error) {
        if (generation != m_generation) {
            return;
        }

        setLoading(false);

        // An outdated list is better than none
        if (!error.isEmpty() && results.isEmpty()) {
            setError(m_all.isEmpty() ? error : QString());

            return;
        }

        if (results != cached) {
            ApiCache::instance().write(key, QJsonDocument(results));
            showResults(results);
        }
    };

    switch (m_source) {
    case Enrolled:
        loadEnrolled(finish);
        break;
    case Archived: {
        QUrlQuery query = courseQuery();
        query.addQueryItem(QStringLiteral("is_archived"), QStringLiteral("true"));
        client->getAllPages(client->apiUrl(QStringLiteral("users/me/subscribed-courses/"), query),
                            this,
                            finish);
        break;
    }
    case Wishlist:
        client->getAllPages(client->apiUrl(QStringLiteral("users/me/wishlisted-courses/"),
                                           courseQuery(StoreCourseFields)),
                            this,
                            finish);
        break;
    case Collections: {
        QUrlQuery query;
        query.addQueryItem(QStringLiteral("collection_has_courses"), QStringLiteral("True"));
        query.addQueryItem(QStringLiteral("course_limit"), QStringLiteral("100"));
        query.addQueryItem(QStringLiteral("page_size"), QStringLiteral("100"));
        query.addQueryItem(QStringLiteral("fields[course]"), CourseFields);
        query.addQueryItem(QStringLiteral("fields[user]"), QStringLiteral("display_name"));
        query.addQueryItem(QStringLiteral("fields[user_has_subscribed_courses_collection]"),
                           QStringLiteral("@all"));
        client->getAllPages(
            client->apiUrl(QStringLiteral("users/me/subscribed-courses-collections/"), query),
            this,
            finish);
        break;
    }
    case Search:
        break;
    }
}

void CourseListModel::loadEnrolled(const UdemyClient::PageCallback &finish)
{
    // Bought courses, and those of a Personal Plan subscription, asked for at the same time
    struct Parts {
        QJsonArray bought;
        QJsonArray subscribed;
        QString error;
        int missing = 2;
    };
    auto parts = std::make_shared<Parts>();

    auto join = [parts, finish] {
        if (--parts->missing > 0) {
            return;
        }

        QJsonArray results = parts->bought;
        QSet<qint64> seen;

        for (const QJsonValue &value : std::as_const(results)) {
            seen.insert(value.toObject().value(u"id").toInteger());
        }

        for (const QJsonValue &value : std::as_const(parts->subscribed)) {
            const QJsonObject object = value.toObject();
            const QJsonObject course =
                object.contains(u"course") ? object.value(u"course").toObject() : object;

            if (!seen.contains(course.value(u"id").toInteger())) {
                results.append(value);
            }
        }

        finish(results, parts->error);
    };

    auto client = UdemyClient::instance();
    QUrlQuery query = courseQuery();
    query.addQueryItem(QStringLiteral("ordering"), QStringLiteral("-last_accessed,-access_time"));
    client->getAllPages(client->apiUrl(QStringLiteral("users/me/subscribed-courses/"), query),
                        this,
                        [parts, join](const QJsonArray &results, const QString &error) {
                            parts->bought = results;
                            parts->error = error;
                            join();
                        });

    QUrlQuery subscriptionQuery = courseQuery();
    subscriptionQuery.addQueryItem(QStringLiteral("ordering"),
                                   QStringLiteral("-last_accessed,-enrolled"));
    client->getAllPages(
        client->apiUrl(QStringLiteral("users/me/subscription-course-enrollments/"),
                       subscriptionQuery),
        this,
        [parts, join](const QJsonArray &results, const QString &) {
            // Most accounts have no subscription, and get an error here
            parts->subscribed = results;
            join();
        },
        5);
}

void CourseListModel::search(int generation)
{
    auto client = UdemyClient::instance();

    if (m_query.trimmed().isEmpty()) {
        setAll({});
        setLoading(false);

        return;
    }

    setLoading(true);
    const QJsonObject body{
        {QStringLiteral("query"), SearchQuery},
        {QStringLiteral("variables"),
         QJsonObject{
             {QStringLiteral("query"), m_query.trimmed()},
             {QStringLiteral("page"), 0},
             {QStringLiteral("pageSize"), 48},
             {QStringLiteral("context"),
              QJsonObject{{QStringLiteral("triggerType"), QStringLiteral("USER_QUERY")}}},
         }},
    };
    QUrl url = client->baseUrl();
    url.setPath(QStringLiteral("/api/2024-01/graphql/"));

    // The GraphQL search fails (HTTP 500) for signed-in users; results are the same for all
    client->post(
        url,
        QJsonDocument(body),
        this,
        [=, this](const UdemyClient::Reply &reply) {
            if (generation != m_generation) {
                return;
            }

            const QJsonArray results = reply.json.object()
                                           .value(u"data")
                                           .toObject()
                                           .value(u"courseSearch")
                                           .toObject()
                                           .value(u"results")
                                           .toArray();
            QList<QVariantMap> courses;

            for (const QJsonValue &result : results) {
                courses.append(
                    normalizeSearchResult(result.toObject().value(u"course").toObject()));
            }

            setError(reply.ok() || !courses.isEmpty() ? QString() : reply.error);
            setAll(courses);
            setLoading(false);
            loadPrices(generation);
        },
        UdemyClient::Session::Omitted);
}

void CourseListModel::prefetchCourse(qint64 courseId)
{
    CourseSession::prefetch(courseId);
}

QVariantMap CourseListModel::normalizeSearchResult(const QJsonObject &course)
{
    QStringList instructors;

    for (const QJsonValue &instructor : course.value(u"instructors").toArray()) {
        instructors.append(instructor.toObject().value(u"name").toString());
    }

    // "ALL_LEVELS" reads "All Levels"
    QStringList levelWords = course.value(u"level").toString().toLower().split(u'_');

    for (QString &word : levelWords) {
        if (!word.isEmpty()) {
            word[0] = word[0].toUpper();
        }
    }

    const double hours = course.value(u"durationInSeconds").toDouble() / 3600.0;
    const QJsonObject rating = course.value(u"rating").toObject();
    QString url = QUrl(course.value(u"urlCourseLanding").toString()).path();

    if (!url.isEmpty() && !url.endsWith(u'/')) {
        url += u'/';
    }

    return {
        {QStringLiteral("id"), course.value(u"id").toVariant().toLongLong()},
        {QStringLiteral("title"), course.value(u"title").toString()},
        {QStringLiteral("headline"), course.value(u"headline").toString()},
        {QStringLiteral("image"),
         course.value(u"images").toObject().value(u"px480x270").toString()},
        {QStringLiteral("imageLarge"),
         course.value(u"images").toObject().value(u"px480x270").toString()},
        {QStringLiteral("instructors"), instructors.join(QStringLiteral(", "))},
        {QStringLiteral("progress"), 0.0},
        {QStringLiteral("url"), url},
        {QStringLiteral("numLectures"),
         course.value(u"curriculum")
             .toObject()
             .value(u"contentCounts")
             .toObject()
             .value(u"lecturesCount")
             .toInt()},
        {QStringLiteral("rating"), rating.value(u"average").toDouble()},
        {QStringLiteral("numReviews"), rating.value(u"count").toInt()},
        {QStringLiteral("price"),
         course.value(u"isFree").toBool() ? QStringLiteral("Free") : QString()},
        {QStringLiteral("contentInfo"),
         hours > 0 ? QStringLiteral("%1 total hours").arg(hours, 0, 'f', hours < 10 ? 1 : 0)
                   : QString()},
        {QStringLiteral("level"), levelWords.join(u' ')},
    };
}

void CourseListModel::loadPrices(int generation)
{
    QStringList ids;

    for (const QVariantMap &course : std::as_const(m_all)) {
        if (course.value(QStringLiteral("price")).toString().isEmpty()) {
            ids.append(course.value(QStringLiteral("id")).toString());
        }
    }

    if (ids.isEmpty()) {
        return;
    }

    auto client = UdemyClient::instance();
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("course_ids"), ids.join(u','));
    query.addQueryItem(QStringLiteral("fields[pricing_result]"),
                       QStringLiteral("price,discount_price,list_price"));
    client->get(
        client->apiUrl(QStringLiteral("pricing/"), query),
        this,
        [=, this](const UdemyClient::Reply &reply) {
            if (generation != m_generation || !reply.ok()) {
                return;
            }

            const QJsonObject prices = reply.json.object().value(u"courses").toObject();

            for (QVariantMap &course : m_all) {
                const QJsonObject price =
                    prices.value(course.value(QStringLiteral("id")).toString()).toObject();
                // A sale price, when there is one, is what the checkout asks for
                QString text =
                    price.value(u"discount_price").toObject().value(u"price_string").toString();

                if (text.isEmpty()) {
                    text = price.value(u"price").toObject().value(u"price_string").toString();
                }

                if (!text.isEmpty()) {
                    course.insert(QStringLiteral("price"), text);
                }
            }

            applyFilter();
        });
}

void CourseListModel::setAll(const QList<QVariantMap> &courses)
{
    m_all = courses;
    applyFilter();
}

void CourseListModel::applyFilter()
{
    QList<QVariantMap> courses;

    for (const QVariantMap &course : std::as_const(m_all)) {
        const double progress = course.value(QStringLiteral("progress")).toDouble();
        bool keep = true;

        switch (m_progressFilter) {
        case AnyProgress:
            break;
        case InProgress:
            keep = progress > 0 && progress < 1;
            break;
        case NotStarted:
            keep = progress <= 0;
            break;
        case Completed:
            keep = progress >= 1;
            break;
        }

        if (keep) {
            courses.append(course);
        }
    }

    if (m_ordering != RecentlyAccessed) {
        QCollator collator;
        collator.setNumericMode(true);
        collator.setCaseSensitivity(Qt::CaseInsensitive);
        const bool ascending = m_ordering == TitleAscending;
        std::stable_sort(courses.begin(),
                         courses.end(),
                         [&](const QVariantMap &a, const QVariantMap &b) {
                             const int result =
                                 collator.compare(a.value(QStringLiteral("title")).toString(),
                                                  b.value(QStringLiteral("title")).toString());

                             return ascending ? result < 0 : result > 0;
                         });
    }

    // The same courses as before, such as after a refresh: update them where they are, so the
    // view keeps its focus and position
    const auto sameCourse = [](const QVariantMap &a, const QVariantMap &b) {
        return a.value(QStringLiteral("id")) == b.value(QStringLiteral("id"));
    };

    if (courses.size() == m_courses.size() && !courses.isEmpty()
        && std::equal(courses.cbegin(), courses.cend(), m_courses.cbegin(), sameCourse)) {
        m_courses = courses;
        Q_EMIT dataChanged(index(0), index(int(m_courses.size()) - 1));

        return;
    }

    beginResetModel();
    m_courses = courses;
    endResetModel();
    Q_EMIT countChanged();
}

void CourseListModel::setLoading(bool loading)
{
    if (m_loading == loading) {
        return;
    }

    m_loading = loading;
    Q_EMIT loadingChanged();
}

void CourseListModel::setError(const QString &error)
{
    if (m_error == error) {
        return;
    }

    m_error = error;
    Q_EMIT errorChanged();
}
