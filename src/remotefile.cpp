// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "remotefile.h"

#include "udemyclient.h"

#include <QCryptographicHash>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QSaveFile>
#include <QStandardPaths>

namespace
{
QString cachePathFor(const QUrl &url)
{
    // Signed CDN links change their query on every request, so name the file by its path
    const QByteArray key =
        QCryptographicHash::hash(
            url.adjusted(QUrl::RemoveQuery | QUrl::RemoveFragment).toString().toUtf8(),
            QCryptographicHash::Sha1)
            .toHex();
    const QString dir =
        QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + QStringLiteral("/files");
    QDir().mkpath(dir);
    const QString suffix = QFileInfo(url.path()).suffix();

    return dir + u'/' + QString::fromLatin1(key) + (suffix.isEmpty() ? QString() : u'.' + suffix);
}
}

RemoteFile::~RemoteFile()
{
    if (m_reply) {
        m_reply->abort();
    }
}

QUrl RemoteFile::source() const
{
    return m_source;
}

void RemoteFile::setSource(const QUrl &source)
{
    if (m_source == source) {
        return;
    }

    m_source = source;
    Q_EMIT sourceChanged();
    load();
}

QUrl RemoteFile::localUrl() const
{
    return m_localUrl;
}

bool RemoteFile::loading() const
{
    return m_reply;
}

QString RemoteFile::error() const
{
    return m_error;
}

void RemoteFile::load()
{
    if (m_reply) {
        m_reply->abort();
        m_reply = nullptr;
        Q_EMIT loadingChanged();
    }

    setError({});

    if (m_source.isEmpty() || m_source.isLocalFile() || m_source.scheme() == u"qrc") {
        setLocalUrl(m_source);

        return;
    }

    const QString path = cachePathFor(m_source);

    if (QFileInfo::exists(path)) {
        setLocalUrl(QUrl::fromLocalFile(path));

        return;
    }

    setLocalUrl({});

    m_reply = UdemyClient::instance()->network()->get(QNetworkRequest(m_source));
    Q_EMIT loadingChanged();
    QNetworkReply *reply = m_reply;
    connect(reply, &QNetworkReply::finished, this, [this, reply, path] {
        reply->deleteLater();

        if (reply != m_reply) {
            return;
        }

        m_reply = nullptr;
        Q_EMIT loadingChanged();

        if (reply->error() != QNetworkReply::NoError) {
            setError(reply->errorString());

            return;
        }

        QSaveFile file(path);

        if (!file.open(QIODevice::WriteOnly) || file.write(reply->readAll()) < 0
            || !file.commit()) {
            setError(file.errorString());

            return;
        }

        setLocalUrl(QUrl::fromLocalFile(path));
    });
}

void RemoteFile::setLocalUrl(const QUrl &url)
{
    if (m_localUrl == url) {
        return;
    }

    m_localUrl = url;
    Q_EMIT localUrlChanged();
}

void RemoteFile::setError(const QString &error)
{
    if (m_error == error) {
        return;
    }

    m_error = error;
    Q_EMIT errorChanged();
}
