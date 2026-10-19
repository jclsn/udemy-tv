// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "apptheme.h"

#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QSettings>
#include <QStandardPaths>
#include <QStyleHints>

#include <KColorScheme>
#include <KSharedConfig>

namespace
{
AppTheme *s_instance = nullptr;

// KColorScheme reads files only, so the scheme is copied out of the resources
QString installScheme(const QString &name)
{
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dir);
    const QString path = dir + u'/' + name;
    QFile::remove(path);

    if (!QFile::copy(u":/" + name, path)) {
        qWarning() << "Could not install the color scheme to" << path;

        return {};
    }

    QFile::setPermissions(path, QFile::ReadOwner | QFile::WriteOwner);

    return path;
}
}

AppTheme::AppTheme(QObject *parent)
    : QObject(parent)
    , m_dark(darkFromSettings())
{
    Q_ASSERT(!s_instance);
    s_instance = this;
    apply();
}

AppTheme *AppTheme::create(QQmlEngine *, QJSEngine *)
{
    QJSEngine::setObjectOwnership(s_instance, QJSEngine::CppOwnership);

    return s_instance;
}

bool AppTheme::darkFromSettings()
{
    // Written by Preferences.qml
    const QString theme =
        QSettings().value(QStringLiteral("Preferences/theme"), QStringLiteral("light")).toString();

    if (theme == u"system") {
        return QGuiApplication::styleHints()->colorScheme() == Qt::ColorScheme::Dark;
    }

    return theme == u"dark";
}

bool AppTheme::dark() const
{
    return m_dark;
}

void AppTheme::setDark(bool dark)
{
    if (m_dark == dark) {
        return;
    }

    m_dark = dark;
    apply();
    Q_EMIT darkChanged();
}

void AppTheme::apply()
{
    const QString path = installScheme(m_dark ? QStringLiteral("UdemyTV-Dark.colors")
                                              : QStringLiteral("UdemyTV.colors"));

    if (path.isEmpty()) {
        return;
    }

    // KColorScheme, and through it Kirigami, reads this for the app's colors
    qApp->setProperty("KDE_COLOR_SCHEME_PATH", path);
    QGuiApplication::setPalette(
        KColorScheme::createApplicationPalette(KSharedConfig::openConfig(path)));
}
