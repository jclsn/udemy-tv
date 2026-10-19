// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#include <QApplication>
#include <QCommandLineParser>
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QStandardPaths>
#include <QVersionNumber>
#include <QtWebEngineQuick/QtWebEngineQuick>

#include <KLocalizedQmlContext>
#include <KLocalizedString>

#include "apptheme.h"
#include "udemyclient.h"

namespace
{
// Udemy protects many courses with Widevine. QtWebEngine can play those in Udemy's own player
// when it finds the CDM, which Chromium or Chrome download on their own.
QString findWidevine()
{
    const QString overridePath = qEnvironmentVariable("UDEMY_TV_WIDEVINE_PATH");

    if (!overridePath.isEmpty()) {
        return overridePath;
    }

    const QString home = QDir::homePath();
    const QStringList roots{
        home + QStringLiteral("/.config/chromium/WidevineCdm"),
        home + QStringLiteral("/.config/google-chrome/WidevineCdm"),
        home + QStringLiteral("/.local/lib/WidevineCdm"),
        QStringLiteral("/usr/lib/chromium/WidevineCdm"),
        QStringLiteral("/opt/google/chrome/WidevineCdm"),
        QStringLiteral("/usr/lib/qt6/plugins/ppapi"),
    };

    // The newest version that has a library for this machine
    QString best;
    QVersionNumber bestVersion;

    for (const QString &root : roots) {
        QDirIterator it(root,
                        {QStringLiteral("libwidevinecdm.so")},
                        QDir::Files,
                        QDirIterator::Subdirectories | QDirIterator::FollowSymlinks);

        while (it.hasNext()) {
            const QString path = it.next();
#if defined(Q_PROCESSOR_ARM_64)

            if (path.contains(u"linux_x64")) {
                continue;
            }
#elif defined(Q_PROCESSOR_X86_64)

            if (path.contains(u"linux_arm")) {
                continue;
            }
#endif
            QVersionNumber version;

            for (const QString &part : path.split(u'/')) {
                const QVersionNumber candidate = QVersionNumber::fromString(part);

                if (candidate.segmentCount() >= 3) {
                    version = candidate;
                }
            }

            if (best.isEmpty() || version > bestVersion) {
                best = path;
                bestVersion = version;
            }
        }
    }

    return best;
}

// Returns whether a Widevine CDM was found
bool setChromiumFlags()
{
    QStringList flags =
        qEnvironmentVariable("QTWEBENGINE_CHROMIUM_FLAGS").split(u' ', Qt::SkipEmptyParts);
    // Arrow keys move between links and fields, so web pages can be used with a remote
    flags << QStringLiteral("--enable-spatial-navigation");
    flags << QStringLiteral("--autoplay-policy=no-user-gesture-required");

    const QString widevine = findWidevine();

    if (!widevine.isEmpty()) {
        qInfo() << "Using Widevine CDM" << widevine;
        flags << QStringLiteral("--widevine-path=") + widevine;
    } else {
        qInfo() << "No Widevine CDM found; DRM-protected lectures will not play";
    }

    qputenv("QTWEBENGINE_CHROMIUM_FLAGS", flags.join(u' ').toUtf8());

    return !widevine.isEmpty();
}

// The app was called udemy-bigscreen before; keep the user's login, settings and cache
void migrateFromOldName()
{
    const QString oldName = QStringLiteral("udemy-bigscreen");
    const QString newName = QCoreApplication::applicationName();

    for (const auto location : {QStandardPaths::GenericDataLocation,
                                QStandardPaths::GenericConfigLocation,
                                QStandardPaths::GenericCacheLocation}) {
        const QString base = QStandardPaths::writableLocation(location) + u'/';

        if (!QFileInfo::exists(base + oldName) || QFileInfo::exists(base + newName)) {
            continue;
        }

        if (!QDir().rename(base + oldName, base + newName)) {
            qWarning() << "Could not move" << base + oldName << "to" << base + newName;
            continue;
        }

        // Inside are the application's own directory, or its settings file
        QDir dir(base + newName);
        dir.rename(oldName, newName);
        dir.rename(oldName + QStringLiteral(".conf"), newName + QStringLiteral(".conf"));
    }
}
}

int main(int argc, char *argv[])
{
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
    }

    const bool drmAvailable = setChromiumFlags();
    QtWebEngineQuick::initialize();

    QApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("udemy-tv"));
    app.setApplicationDisplayName(QStringLiteral("Udemy TV"));
    app.setApplicationVersion(QStringLiteral(UDEMYTV_VERSION));
    app.setOrganizationName(QStringLiteral("udemy-tv"));
    app.setDesktopFileName(QStringLiteral("io.github.udemytv"));
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("io.github.udemytv"),
                                       QIcon::fromTheme(QStringLiteral("applications-education"))));
    KLocalizedString::setApplicationDomain("udemy-tv");

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("An unofficial Udemy app for TVs"));
    parser.addHelpOption();
    parser.addVersionOption();
    const QCommandLineOption demoOption(
        QStringLiteral("demo"),
        QStringLiteral("Show sample courses instead of an account."));
    const QCommandLineOption windowedOption(
        QStringLiteral("windowed"),
        QStringLiteral("Open in a window instead of full screen."));
    const QCommandLineOption tokenOption(
        QStringLiteral("token"),
        QStringLiteral(
            "Sign in with an access token copied from a browser (the access_token cookie)."),
        QStringLiteral("token"));
    const QCommandLineOption portalOption(
        QStringLiteral("portal"),
        QStringLiteral("The Udemy Business subdomain, as in <portal>.udemy.com."),
        QStringLiteral("name"));
    parser.addOptions({demoOption, windowedOption, tokenOption, portalOption});
    parser.process(app);

    migrateFromOldName();
    // Udemy's colors, light or dark as chosen in the settings
    AppTheme theme;

    UdemyClient client(parser.isSet(demoOption));
    client.setDrmAvailable(drmAvailable);

    if (parser.isSet(portalOption)) {
        client.setPortal(parser.value(portalOption));
    }

    QString token = parser.value(tokenOption);

    if (token.isEmpty()) {
        token = qEnvironmentVariable("UDEMY_TOKEN");
    }

    if (!token.isEmpty()) {
        client.useAccessToken(token);
    }

    QQmlApplicationEngine engine;
#ifdef UDEMYTV_PRIVATE_QMLDIR
    engine.addImportPath(QStringLiteral(UDEMYTV_PRIVATE_QMLDIR));
#endif
    KLocalization::setupLocalizedContext(&engine);
    engine.setInitialProperties(
        {{QStringLiteral("startFullScreen"), !parser.isSet(windowedOption)}});
    engine.loadFromModule("io.github.udemytv", "Main");

    if (engine.rootObjects().isEmpty()) {
        return 1;
    }

    return app.exec();
}
