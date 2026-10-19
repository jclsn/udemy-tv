// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "apicache.h"

#include <QDateTime>
#include <QDir>
#include <QLoggingCategory>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>

Q_LOGGING_CATEGORY(API_CACHE, "udemytv.cache", QtInfoMsg)

namespace
{
const QString ConnectionName = QStringLiteral("udemytv-cache");
}

ApiCache::ApiCache() = default;

ApiCache &ApiCache::instance()
{
    static ApiCache cache;

    return cache;
}

void ApiCache::setEnabled(bool enabled)
{
    m_enabled = enabled;
}

void ApiCache::setScope(const QString &scope)
{
    m_scope = scope;
}

QString ApiCache::scopedKey(const QString &key) const
{
    return m_scope + u'/' + key;
}

bool ApiCache::open() const
{
    if (m_opened || m_failed) {
        return m_opened;
    }

    const QString dir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    QDir().mkpath(dir);

    QSqlDatabase database = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), ConnectionName);
    database.setDatabaseName(dir + QStringLiteral("/api-cache.sqlite"));

    if (!database.open()) {
        qCWarning(API_CACHE) << "Cannot open the cache:" << database.lastError().text();
        m_failed = true;

        return false;
    }

    // Write-ahead logging keeps writes from blocking the interface
    QSqlQuery query(database);
    query.exec(QStringLiteral("PRAGMA journal_mode=WAL"));
    query.exec(QStringLiteral("PRAGMA synchronous=NORMAL"));
    query.exec(
        QStringLiteral("CREATE TABLE IF NOT EXISTS responses ("
                       "key TEXT PRIMARY KEY, value BLOB NOT NULL, updated INTEGER NOT NULL)"));
    m_opened = true;

    return true;
}

QJsonDocument ApiCache::read(const QString &key, qint64 *age) const
{
    if (!m_enabled || !open()) {
        return {};
    }

    QSqlQuery query(QSqlDatabase::database(ConnectionName));
    query.prepare(QStringLiteral("SELECT value, updated FROM responses WHERE key = ?"));
    query.addBindValue(scopedKey(key));

    if (!query.exec() || !query.next()) {
        return {};
    }

    if (age) {
        *age = QDateTime::currentSecsSinceEpoch() - query.value(1).toLongLong();
    }

    return QJsonDocument::fromJson(query.value(0).toByteArray());
}

void ApiCache::write(const QString &key, const QJsonDocument &value)
{
    if (!m_enabled || !open()) {
        return;
    }

    QSqlQuery query(QSqlDatabase::database(ConnectionName));
    query.prepare(
        QStringLiteral("INSERT OR REPLACE INTO responses (key, value, updated) "
                       "VALUES (?, ?, ?)"));
    query.addBindValue(scopedKey(key));
    query.addBindValue(value.toJson(QJsonDocument::Compact));
    query.addBindValue(QDateTime::currentSecsSinceEpoch());

    if (!query.exec()) {
        qCWarning(API_CACHE) << "Cannot write" << key << query.lastError().text();
    }
}

void ApiCache::clear()
{
    if (!open()) {
        return;
    }

    QSqlQuery query(QSqlDatabase::database(ConnectionName));
    query.exec(QStringLiteral("DELETE FROM responses"));
}
