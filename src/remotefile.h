// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QPointer>
#include <QQmlEngine>
#include <QUrl>

class QNetworkReply;

/*!
   \brief Downloads a file to the cache, for types that only read local files, such as PdfDocument.

   Local and resource URLs are passed through as they are.
 */
class RemoteFile : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(QUrl localUrl READ localUrl NOTIFY localUrlChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)

public:
    using QObject::QObject;
    ~RemoteFile() override;

    QUrl source() const;
    void setSource(const QUrl &source);
    QUrl localUrl() const;
    bool loading() const;
    QString error() const;

Q_SIGNALS:
    void sourceChanged();
    void localUrlChanged();
    void loadingChanged();
    void errorChanged();

private:
    void load();
    void setLocalUrl(const QUrl &url);
    void setError(const QString &error);

    QUrl m_source;
    QUrl m_localUrl;
    QString m_error;
    QPointer<QNetworkReply> m_reply;
};
