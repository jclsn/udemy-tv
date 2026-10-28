// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QHash>
#include <QJsonArray>
#include <QJsonDocument>
#include <QNetworkCookie>
#include <QObject>
#include <QPointer>
#include <QQmlEngine>
#include <QTimer>
#include <QUrl>
#include <QUrlQuery>
#include <QVariantMap>

#include <functional>

class QNetworkAccessManager;
class QQuickWebEngineProfile;
class DemoBackend;

/*!
   \brief The connection to the user's Udemy account.

   Udemy is behind Cloudflare, which turns away clients that are not a real browser. So every
   API request is made with fetch() from a hidden web page on the Udemy origin (see ApiBridge.qml
   and bridge.js), which shares its cookies with the login page. Requests are queued until that
   page is ready.
 */
class UdemyClient : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QObject *profile READ profile CONSTANT)
    Q_PROPERTY(bool demoMode READ demoMode CONSTANT)
    Q_PROPERTY(AuthState authState READ authState NOTIFY authStateChanged)
    Q_PROPERTY(bool bridgeReady READ bridgeReady NOTIFY bridgeReadyChanged)
    Q_PROPERTY(QString portal READ portal WRITE setPortal NOTIFY portalChanged)
    Q_PROPERTY(QUrl baseUrl READ baseUrl NOTIFY portalChanged)
    Q_PROPERTY(QUrl bridgeUrl READ bridgeUrl NOTIFY portalChanged)
    Q_PROPERTY(QUrl loginUrl READ loginUrl NOTIFY portalChanged)
    Q_PROPERTY(QVariantMap user READ user NOTIFY userChanged)
    Q_PROPERTY(QString bridgeScript READ bridgeScript CONSTANT)
    Q_PROPERTY(QString webPlayerScript READ webPlayerScript CONSTANT)
    Q_PROPERTY(QString protectedPlayerScript READ protectedPlayerScript CONSTANT)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(bool drmAvailable READ drmAvailable CONSTANT)

public:
    enum AuthState {
        Connecting, // Waiting for the bridge page, or for the account check
        LoggedOut,
        LoggedIn,
    };
    Q_ENUM(AuthState)

    struct Reply {
        int status = 0; // HTTP status, 0 for network errors
        QJsonDocument json;
        QString error; // Empty on success

        bool ok() const
        {
            return error.isEmpty();
        }
    };
    using Callback = std::function<void(const Reply &)>;
    using PageCallback = std::function<void(const QJsonArray &results, const QString &error)>;

    // Whether a request carries the user's session
    enum class Session {
        Included,
        // Sent without cookies, for requests that fail for signed-in users
        Omitted,
    };

    explicit UdemyClient(bool demoMode, QObject *parent = nullptr);
    ~UdemyClient() override;

    static UdemyClient *instance();
    static UdemyClient *create(QQmlEngine *, QJSEngine *);

    QObject *profile();
    QQuickWebEngineProfile *webProfile();
    bool demoMode() const;
    AuthState authState() const;
    bool bridgeReady() const;
    QString portal() const;
    void setPortal(const QString &portal);
    QUrl baseUrl() const;
    QUrl bridgeUrl() const;
    QUrl loginUrl() const;
    QVariantMap user() const;
    QString bridgeScript() const;
    QString webPlayerScript() const;
    QString protectedPlayerScript() const;
    QString lastError() const;
    bool drmAvailable() const;
    void setDrmAvailable(bool available);

    QNetworkAccessManager *network() const;

    /*!
       \brief The URL of an API path such as "users/me/subscribed-courses/".
     */
    QUrl apiUrl(const QString &path, const QUrlQuery &query = {}) const;

    /*!
       \brief Makes a request. The callback is dropped if \a context is destroyed first.
     */
    void get(const QUrl &url, QObject *context, Callback callback);
    void post(const QUrl &url,
              const QJsonDocument &body,
              QObject *context,
              Callback callback,
              Session session = Session::Included);
    void deleteResource(const QUrl &url, QObject *context, Callback callback);

    /*!
       \brief Fetches every page of a paginated list ("results" and "next").
     */
    void getAllPages(const QUrl &url, QObject *context, PageCallback callback, int maxPages = 40);

    /*!
       \brief Makes an absolute URL from one in an API response, which can be relative.
     */
    Q_INVOKABLE QUrl absoluteUrl(const QString &url) const;

    // Called by ApiBridge.qml
    Q_INVOKABLE void bridgeAttached();
    Q_INVOKABLE void bridgeDetached();
    Q_INVOKABLE void deliver(int id, int status, const QString &body);

    /*!
       \brief Signs in with an access token copied from a browser, like Udeler does.
     */
    Q_INVOKABLE void useAccessToken(const QString &token);

    /*!
       \brief Checks the account again, such as after the login page set new cookies.
     */
    Q_INVOKABLE void checkAccount();

    Q_INVOKABLE void logout();

Q_SIGNALS:
    void authStateChanged();
    void bridgeReadyChanged();
    void portalChanged();
    void userChanged();
    void lastErrorChanged();

    /*!
       \brief Asks ApiBridge.qml to run a request in the bridge page.
     */
    void fetchRequested(int id,
                        const QString &method,
                        const QString &url,
                        const QString &body,
                        const QVariantMap &headers,
                        bool anonymous);

    /*!
       \brief Asks the bridge page to reload, for example after the portal changed.
     */
    void bridgeReloadRequested();

    /*!
       \brief The access token cookie appeared, so a login in the web view may have finished.
     */
    void accessTokenChanged();

private:
    struct Pending {
        QPointer<QObject> context;
        bool hasContext = false;
        Callback callback;
        QString method;
        QUrl url;
        QByteArray body;
        bool anonymous = false;
        bool sent = false;
        qint64 deadline = 0;
        qint64 created = 0; // For timing requests in the debug output
    };

    void request(const QString &method,
                 const QUrl &url,
                 const QByteArray &body,
                 QObject *context,
                 Callback callback,
                 Session session = Session::Included);
    void send(int id);
    void finish(int id, const Reply &reply);
    void checkTimeouts();
    void setAuthState(AuthState state);
    void setLastError(const QString &error);
    void rejectLogin();
    void startWithCachedAccount();
    void createProfile();
    void onCookieAdded(const QNetworkCookie &cookie);
    void onCookieRemoved(const QNetworkCookie &cookie);
    void finishLoadingCookies();
    void keepOnlyTokenCookie(const QNetworkCookie &keep);
    QVariantMap requestHeaders(const QString &method, const QUrl &url) const;

    bool m_demoMode = false;
    QQuickWebEngineProfile *m_profile = nullptr;
    QNetworkAccessManager *m_network = nullptr;
    DemoBackend *m_demo = nullptr;
    AuthState m_authState = Connecting;
    bool m_bridgeReady = false;
    bool m_drmAvailable = false;
    bool m_tokenPending = false; // A token was given and is not checked yet

    // Started with the account of the last start, before Udemy confirmed it
    bool m_accountUnverified = false;
    QString m_portal;
    QString m_accessToken;
    QString m_csrfToken;
    QVariantMap m_user;
    QString m_lastError;
    QHash<int, Pending> m_pending;
    int m_nextId = 1;
    QTimer m_timeoutTimer;
    QTimer m_accountCheckTimer;
    // Every access_token cookie; more than one confuses Udemy, so only the newest is kept
    QList<QNetworkCookie> m_tokenCookies;
    bool m_cookiesLoading = true;
};
