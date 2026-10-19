// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "udemyclient.h"

#include "apicache.h"
#include "demobackend.h"

#include <QDateTime>
#include <QFile>
#include <QJsonArray>
#include <QJsonObject>
#include <QLoggingCategory>
#include <QNetworkAccessManager>
#include <QNetworkCookie>
#include <QQuickWebEngineProfile>
#include <QRegularExpression>
#include <QSettings>
#include <QWebEngineCookieStore>

Q_LOGGING_CATEGORY(UDEMY_API, "udemytv.api", QtInfoMsg)

namespace
{
UdemyClient *s_instance = nullptr;

constexpr int RequestTimeoutMs = 45000;

bool isUdemyDomain(const QString &domain)
{
    return domain == u"udemy.com" || domain.endsWith(u".udemy.com");
}

QString readResource(const QString &path)
{
    QFile file(path);

    if (!file.open(QIODevice::ReadOnly)) {
        qCWarning(UDEMY_API) << "Missing resource" << path;

        return {};
    }

    return QString::fromUtf8(file.readAll());
}

// Pulls a readable message out of an error response, such as {"detail": "..."}
QString errorMessage(int status, const QJsonDocument &json, const QString &body)
{
    QString detail;
    const QJsonObject object = json.object();

    if (object.contains(u"detail")) {
        detail = object.value(u"detail").toString();
    } else if (object.value(u"error").isObject()) {
        detail = object.value(u"error").toObject().value(u"message").toString();
    } else if (!body.contains(u'<')) {
        detail = body.left(200);
    }

    if (status == 0) {
        return detail.isEmpty() ? QStringLiteral("Network error") : detail;
    }

    return detail.isEmpty() ? QStringLiteral("HTTP %1").arg(status)
                            : QStringLiteral("HTTP %1: %2").arg(status).arg(detail);
}
}

UdemyClient::UdemyClient(bool demoMode, QObject *parent)
    : QObject(parent)
    , m_demoMode(demoMode)
    , m_network(new QNetworkAccessManager(this))
{
    Q_ASSERT(!s_instance);
    s_instance = this;

    m_portal = QSettings().value(QStringLiteral("portal"), QStringLiteral("www")).toString();
    ApiCache::instance().setEnabled(!m_demoMode);
    ApiCache::instance().setScope(m_portal);

    if (m_demoMode) {
        // Nothing is stored for the demo
        m_profile = new QQuickWebEngineProfile(this);
        m_demo = new DemoBackend(this);
    } else {
        m_profile = new QQuickWebEngineProfile(QStringLiteral("udemy-tv"), this);
        m_profile->setPersistentCookiesPolicy(QQuickWebEngineProfile::ForcePersistentCookies);
        m_profile->setHttpCacheType(QQuickWebEngineProfile::DiskHttpCache);
    }

    // Look like the Chrome the engine is built on; some sign-in pages turn away unknown browsers
    QString userAgent = m_profile->httpUserAgent();
    userAgent.remove(QRegularExpression(QStringLiteral(" QtWebEngine/\\S+")));
    m_profile->setHttpUserAgent(userAgent);

    if (!m_demoMode) {
        auto cookies = m_profile->cookieStore();
        connect(cookies, &QWebEngineCookieStore::cookieAdded, this, &UdemyClient::onCookieAdded);
        connect(cookies,
                &QWebEngineCookieStore::cookieRemoved,
                this,
                &UdemyClient::onCookieRemoved);
        cookies->loadAllCookies();
        // The store announces each stored cookie, but not when it is done
        QTimer::singleShot(1500, this, &UdemyClient::finishLoadingCookies);
    }

    m_timeoutTimer.setInterval(5000);
    connect(&m_timeoutTimer, &QTimer::timeout, this, &UdemyClient::checkTimeouts);
    m_timeoutTimer.start();

    // A login sets several cookies in a row; check the account once they settle
    m_accountCheckTimer.setSingleShot(true);
    m_accountCheckTimer.setInterval(800);
    connect(&m_accountCheckTimer, &QTimer::timeout, this, &UdemyClient::checkAccount);

    if (m_demoMode) {
        checkAccount();
    } else {
        startWithCachedAccount();
    }
}

UdemyClient::~UdemyClient()
{
    s_instance = nullptr;
}

UdemyClient *UdemyClient::instance()
{
    return s_instance;
}

UdemyClient *UdemyClient::create(QQmlEngine *, QJSEngine *)
{
    QJSEngine::setObjectOwnership(s_instance, QJSEngine::CppOwnership);

    return s_instance;
}

QObject *UdemyClient::profile() const
{
    return m_profile;
}

QQuickWebEngineProfile *UdemyClient::webProfile() const
{
    return m_profile;
}

bool UdemyClient::demoMode() const
{
    return m_demoMode;
}

UdemyClient::AuthState UdemyClient::authState() const
{
    return m_authState;
}

bool UdemyClient::bridgeReady() const
{
    return m_bridgeReady;
}

QString UdemyClient::portal() const
{
    return m_portal;
}

void UdemyClient::setPortal(const QString &portal)
{
    QString cleaned = portal.trimmed().toLower();
    cleaned.remove(QRegularExpression(QStringLiteral("^https?://")));
    cleaned.remove(QRegularExpression(QStringLiteral("\\.udemy\\.com.*$")));

    if (cleaned.isEmpty()
        || !QRegularExpression(QStringLiteral("^[a-z0-9-]+$")).match(cleaned).hasMatch()) {
        cleaned = QStringLiteral("www");
    }

    if (cleaned == m_portal) {
        return;
    }

    m_portal = cleaned;
    QSettings().setValue(QStringLiteral("portal"), m_portal);
    ApiCache::instance().setScope(m_portal);
    Q_EMIT portalChanged();

    m_user.clear();
    Q_EMIT userChanged();
    setAuthState(Connecting);
    Q_EMIT bridgeReloadRequested();
}

QUrl UdemyClient::baseUrl() const
{
    return QUrl(QStringLiteral("https://%1.udemy.com").arg(m_portal));
}

QUrl UdemyClient::bridgeUrl() const
{
    // A small plain text page on the Udemy origin, with no scripts of its own. It has to load
    // for everyone: API responses such as a 403 while signed out become an error page instead,
    // on another origin, where the bridge cannot work.
    QUrl url = baseUrl();
    url.setPath(QStringLiteral("/robots.txt"));

    return url;
}

QUrl UdemyClient::loginUrl() const
{
    if (m_portal != u"www") {
        // Business accounts usually sign in through their organization
        return baseUrl();
    }

    QUrl url = baseUrl();
    url.setPath(QStringLiteral("/join/login-popup/"));
    url.setQuery(QStringLiteral("next=%2Fhome%2Fmy-courses%2Flearning%2F"));

    return url;
}

QVariantMap UdemyClient::user() const
{
    return m_user;
}

QString UdemyClient::bridgeScript() const
{
    return readResource(QStringLiteral(":/qtwebchannel/qwebchannel.js")) + u'\n'
        + readResource(QStringLiteral(":/bridge.js"));
}

QString UdemyClient::webPlayerScript() const
{
    return readResource(QStringLiteral(":/webplayer.js"));
}

QString UdemyClient::protectedPlayerScript() const
{
    return readResource(QStringLiteral(":/shaka-player.compiled.js")) + u'\n'
        + readResource(QStringLiteral(":/protectedplayer.js"));
}

QString UdemyClient::lastError() const
{
    return m_lastError;
}

bool UdemyClient::drmAvailable() const
{
    return m_drmAvailable;
}

void UdemyClient::setDrmAvailable(bool available)
{
    m_drmAvailable = available;
}

QNetworkAccessManager *UdemyClient::network() const
{
    return m_network;
}

QUrl UdemyClient::apiUrl(const QString &path, const QUrlQuery &query) const
{
    QUrl url = baseUrl();
    url.setPath(QStringLiteral("/api-2.0/") + path);

    if (!query.isEmpty()) {
        url.setQuery(query);
    }

    return url;
}

QUrl UdemyClient::absoluteUrl(const QString &url) const
{
    if (url.isEmpty()) {
        return {};
    }

    if (url.startsWith(u"//")) {
        return QUrl(QStringLiteral("https:") + url);
    }

    return baseUrl().resolved(QUrl(url));
}

void UdemyClient::get(const QUrl &url, QObject *context, Callback callback)
{
    request(QStringLiteral("GET"), url, {}, context, std::move(callback));
}

void UdemyClient::post(const QUrl &url,
                       const QJsonDocument &body,
                       QObject *context,
                       Callback callback,
                       Session session)
{
    request(QStringLiteral("POST"),
            url,
            body.toJson(QJsonDocument::Compact),
            context,
            std::move(callback),
            session);
}

void UdemyClient::deleteResource(const QUrl &url, QObject *context, Callback callback)
{
    request(QStringLiteral("DELETE"), url, {}, context, std::move(callback));
}

void UdemyClient::getAllPages(const QUrl &url,
                              QObject *context,
                              PageCallback callback,
                              int maxPages)
{
    struct State {
        QJsonArray results;
        int pages = 0;
    };
    auto state = std::make_shared<State>();
    auto step = std::make_shared<std::function<void(const QUrl &)>>();
    QPointer<QObject> guard(context);
    *step = [this, state, step, callback, maxPages, guard](const QUrl &pageUrl) {
        get(pageUrl, guard, [this, state, step, callback, maxPages](const Reply &reply) {
            if (!reply.ok()) {
                callback(state->results, reply.error);
                *step = nullptr; // Break the reference cycle

                return;
            }

            const QJsonObject object = reply.json.object();

            for (const QJsonValue &value : object.value(u"results").toArray()) {
                state->results.append(value);
            }

            const QString next = object.value(u"next").toString();

            if (!next.isEmpty() && ++state->pages < maxPages) {
                (*step)(absoluteUrl(next));
            } else {
                callback(state->results, {});
                *step = nullptr;
            }
        });
    };
    (*step)(url);
}

void UdemyClient::request(const QString &method,
                          const QUrl &url,
                          const QByteArray &body,
                          QObject *context,
                          Callback callback,
                          Session session)
{
    const int id = m_nextId++;
    Pending pending;
    pending.context = context;
    pending.hasContext = context != nullptr;
    pending.callback = std::move(callback);
    pending.method = method;
    pending.url = url;
    pending.body = body;
    pending.anonymous = session == Session::Omitted;
    pending.created = QDateTime::currentMSecsSinceEpoch();
    m_pending.insert(id, pending);

    qCDebug(UDEMY_API) << method << url.toString(QUrl::FullyEncoded);

    if (m_demoMode) {
        QTimer::singleShot(150, this, [this, id] {
            const auto it = m_pending.constFind(id);

            if (it == m_pending.constEnd()) {
                return;
            }

            const DemoBackend::Response response = m_demo->handle(it->method, it->url, it->body);
            Reply reply;
            reply.status = response.status;
            reply.json = QJsonDocument::fromJson(response.body);

            if (response.status >= 400) {
                reply.error =
                    errorMessage(response.status, reply.json, QString::fromUtf8(response.body));
            }

            finish(id, reply);
        });

        return;
    }

    if (m_bridgeReady) {
        send(id);
    }
}

QVariantMap UdemyClient::requestHeaders(const QString &method, const QUrl &url) const
{
    // The GraphQL gateway fails (HTTP 500) on the REST API's extra headers; send it what
    // udemy.com does, which is the session cookies alone
    if (!url.path().startsWith(u"/api-2.0/")) {
        return {{QStringLiteral("Content-Type"), QStringLiteral("application/json")}};
    }

    QVariantMap headers{
        {QStringLiteral("Accept"), QStringLiteral("application/json, text/plain, */*")},
        {QStringLiteral("X-Requested-With"), QStringLiteral("XMLHttpRequest")},
    };

    if (method != u"GET") {
        headers.insert(QStringLiteral("Content-Type"), QStringLiteral("application/json"));

        if (!m_csrfToken.isEmpty()) {
            headers.insert(QStringLiteral("X-CSRFToken"), m_csrfToken);
        }
    }

    return headers;
}

void UdemyClient::send(int id)
{
    auto it = m_pending.find(id);

    if (it == m_pending.end()) {
        return;
    }

    it->sent = true;
    it->deadline = QDateTime::currentMSecsSinceEpoch() + RequestTimeoutMs;
    Q_EMIT fetchRequested(id,
                          it->method,
                          it->url.toString(QUrl::FullyEncoded),
                          QString::fromUtf8(it->body),
                          requestHeaders(it->method, it->url),
                          it->anonymous);
}

void UdemyClient::deliver(int id, int status, const QString &body)
{
    if (!m_pending.contains(id)) {
        return;
    }

    Reply reply;
    reply.status = status;

    QJsonParseError parseError;
    reply.json = QJsonDocument::fromJson(body.toUtf8(), &parseError);

    if (status == 0) {
        reply.error = errorMessage(status, {}, body);
    } else if (status >= 400) {
        reply.error = errorMessage(status, reply.json, body);
    } else if (parseError.error != QJsonParseError::NoError && !body.trimmed().isEmpty()) {
        reply.error = QStringLiteral("Unexpected response from Udemy");
    }

    // Cloudflare asked for a new check; the bridge page has to pass it again
    if (body.contains(u"<title>Just a moment...</title>")) {
        qCInfo(UDEMY_API) << "Cloudflare challenge on API request, reloading bridge";
        Q_EMIT bridgeReloadRequested();
    }

    if (!reply.ok()) {
        qCInfo(UDEMY_API) << m_pending.value(id).method << m_pending.value(id).url.path()
                          << "failed:" << reply.error;
    }

    finish(id, reply);
}

void UdemyClient::finish(int id, const Reply &reply)
{
    const Pending pending = m_pending.take(id);
    qCDebug(UDEMY_API) << pending.method << pending.url.path() << "took"
                       << QDateTime::currentMSecsSinceEpoch() - pending.created << "ms";

    if (pending.hasContext && !pending.context) {
        return;
    }

    if (pending.callback) {
        pending.callback(reply);
    }
}

void UdemyClient::checkTimeouts()
{
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    QList<int> expired;

    for (auto it = m_pending.cbegin(); it != m_pending.cend(); ++it) {
        if (it->sent && it->deadline < now) {
            expired.append(it.key());
        }
    }

    for (int id : std::as_const(expired)) {
        Reply reply;
        reply.error = QStringLiteral("Udemy did not answer in time");
        finish(id, reply);
    }
}

void UdemyClient::startWithCachedAccount()
{
    // The account of the last start: show its courses at once, and check it once Udemy answers
    const QJsonObject user = ApiCache::instance().read(QStringLiteral("user")).object();

    if (user.value(u"id").toInteger() <= 0) {
        return;
    }

    m_user = user.toVariantMap();
    m_accountUnverified = true;
    m_authState = LoggedIn;
    qCInfo(UDEMY_API) << "Starting with the cached account";
}

void UdemyClient::bridgeAttached()
{
    if (m_demoMode) {
        return;
    }

    qCInfo(UDEMY_API) << "Bridge ready";
    m_bridgeReady = true;
    Q_EMIT bridgeReadyChanged();

    // Requests sent before a reload were lost with the old page; send those again too
    const QList<int> ids = m_pending.keys();

    for (int id : ids) {
        send(id);
    }

    if (m_authState == Connecting || m_accountUnverified) {
        checkAccount();
    }
}

void UdemyClient::bridgeDetached()
{
    if (!m_bridgeReady) {
        return;
    }

    m_bridgeReady = false;
    Q_EMIT bridgeReadyChanged();
}

void UdemyClient::checkAccount()
{
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("fields[user]"),
                       QStringLiteral("id,title,name,display_name,initials,image_100x100,email"));
    get(apiUrl(QStringLiteral("users/me/"), query), this, [this](const Reply &reply) {
        if (reply.ok()) {
            const QJsonObject object = reply.json.object();
            const bool known = object.value(u"id").toInteger() > 0
                || !object.value(u"display_name").toString().isEmpty();

            if (known) {
                m_tokenPending = false;
                m_accountUnverified = false;

                // Another account's courses must not show up
                if (object.value(u"id").toInteger()
                    != m_user.value(QStringLiteral("id")).toLongLong()) {
                    ApiCache::instance().clear();
                }

                ApiCache::instance().write(QStringLiteral("user"), QJsonDocument(object));
                m_user = object.toVariantMap();
                Q_EMIT userChanged();
                setLastError({});
                setAuthState(LoggedIn);

                return;
            }

            rejectLogin();
        } else if (reply.status == 401 || reply.status == 403) {
            rejectLogin();
        } else {
            // Offline or Udemy is down; keep trying while showing the error
            setLastError(reply.error);
            QTimer::singleShot(5000, this, [this] {
                if (m_authState == Connecting) {
                    checkAccount();
                }
            });
        }
    });
}

void UdemyClient::rejectLogin()
{
    m_accountUnverified = false;
    ApiCache::instance().clear();

    if (m_tokenPending) {
        m_tokenPending = false;
        setLastError(QStringLiteral(
            "Udemy did not accept this access token. It may have expired: copy it again after "
            "signing in to udemy.com."));
    }

    setAuthState(LoggedOut);
}

void UdemyClient::useAccessToken(const QString &token)
{
    const QString trimmed = token.trimmed();

    if (trimmed.isEmpty() || m_demoMode) {
        return;
    }

    // Without a domain the cookie is for the portal's host alone, as Udemy sets it
    QNetworkCookie cookie("access_token", trimmed.toUtf8());
    cookie.setPath(QStringLiteral("/"));
    cookie.setSecure(true);
    cookie.setExpirationDate(QDateTime::currentDateTimeUtc().addYears(1));
    m_profile->cookieStore()->setCookie(cookie, baseUrl());

    m_accessToken = trimmed;
    m_tokenPending = true;
    setLastError({});
    setAuthState(Connecting);
    checkAccount();
}

void UdemyClient::logout()
{
    if (m_demoMode) {
        return;
    }

    m_profile->cookieStore()->deleteAllCookies();
    m_tokenCookies.clear();
    ApiCache::instance().clear();
    m_profile->clearHttpCache();
    m_accessToken.clear();
    m_csrfToken.clear();
    m_user.clear();
    Q_EMIT userChanged();
    setAuthState(LoggedOut);
    Q_EMIT bridgeReloadRequested();
}

void UdemyClient::setAuthState(AuthState state)
{
    if (m_authState == state) {
        return;
    }

    qCInfo(UDEMY_API) << "Auth state" << state;
    m_authState = state;
    Q_EMIT authStateChanged();
}

void UdemyClient::setLastError(const QString &error)
{
    if (m_lastError == error) {
        return;
    }

    m_lastError = error;
    Q_EMIT lastErrorChanged();
}

void UdemyClient::onCookieAdded(const QNetworkCookie &cookie)
{
    if (!isUdemyDomain(cookie.domain().remove(0, cookie.domain().startsWith(u'.') ? 1 : 0))) {
        return;
    }

    const QByteArray name = cookie.name();

    if (name == "access_token") {
        m_tokenCookies.removeIf([&cookie](const QNetworkCookie &other) {
            return other.hasSameIdentifier(cookie);
        });
        m_tokenCookies.append(cookie);

        // A new login replaces the old one; two tokens break the GraphQL API (HTTP 500)
        if (!m_cookiesLoading) {
            keepOnlyTokenCookie(cookie);
        }

        const QString token = QString::fromUtf8(cookie.value());

        if (token == m_accessToken) {
            return;
        }

        m_accessToken = token;
        Q_EMIT accessTokenChanged();

        if (m_authState != LoggedIn && m_bridgeReady) {
            m_accountCheckTimer.start();
        }
    } else if (name == "csrftoken") {
        m_csrfToken = QString::fromUtf8(cookie.value());
    }
}

void UdemyClient::onCookieRemoved(const QNetworkCookie &cookie)
{
    if (cookie.name() != "access_token") {
        return;
    }

    m_tokenCookies.removeIf([&cookie](const QNetworkCookie &other) {
        return other.hasSameIdentifier(cookie);
    });

    if (QString::fromUtf8(cookie.value()) == m_accessToken) {
        m_accessToken =
            m_tokenCookies.isEmpty() ? QString() : QString::fromUtf8(m_tokenCookies.last().value());
    }
}

void UdemyClient::finishLoadingCookies()
{
    m_cookiesLoading = false;

    if (m_tokenCookies.size() < 2) {
        return;
    }

    // Which one is newest is unknown here; the one Udemy set itself (for its host only) is
    // more likely right than one for the whole domain, which older versions of this app set
    const auto own = std::find_if(m_tokenCookies.cbegin(),
                                  m_tokenCookies.cend(),
                                  [](const QNetworkCookie &cookie) {
                                      return !cookie.domain().startsWith(u'.');
                                  });
    const QNetworkCookie keep = own != m_tokenCookies.cend() ? *own : m_tokenCookies.last();
    keepOnlyTokenCookie(keep);
    const QString token = QString::fromUtf8(keep.value());

    if (token != m_accessToken) {
        m_accessToken = token;
        Q_EMIT accessTokenChanged();
    }
}

void UdemyClient::keepOnlyTokenCookie(const QNetworkCookie &keep)
{
    const QList<QNetworkCookie> cookies = m_tokenCookies;

    for (const QNetworkCookie &cookie : cookies) {
        if (cookie.hasSameIdentifier(keep)) {
            continue;
        }

        qCInfo(UDEMY_API) << "Removing an older access token for" << cookie.domain();
        QString host = cookie.domain();
        host.remove(0, host.startsWith(u'.') ? 1 : 0);
        m_profile->cookieStore()->deleteCookie(cookie, QUrl(QStringLiteral("https://") + host));
    }
}
