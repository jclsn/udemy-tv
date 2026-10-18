// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "captiontrack.h"

#include "udemyclient.h"

#include <QFile>
#include <QNetworkAccessManager>
#include <QNetworkReply>

CaptionTrack::~CaptionTrack()
{
    if (m_reply) {
        m_reply->abort();
    }
}

QUrl CaptionTrack::source() const
{
    return m_source;
}

void CaptionTrack::setSource(const QUrl &source)
{
    if (m_source == source) {
        return;
    }

    m_source = source;
    Q_EMIT sourceChanged();
    load();
}

qint64 CaptionTrack::position() const
{
    return m_position;
}

void CaptionTrack::setPosition(qint64 position)
{
    if (m_position == position) {
        return;
    }

    m_position = position;
    Q_EMIT positionChanged();
    updateText();
}

QString CaptionTrack::text() const
{
    return m_text;
}

bool CaptionTrack::loading() const
{
    return m_reply;
}

void CaptionTrack::load()
{
    if (m_reply) {
        m_reply->abort();
        m_reply = nullptr;
    }

    setCues({});

    if (m_source.isEmpty()) {
        Q_EMIT loadingChanged();

        return;
    }

    if (m_source.scheme() == u"qrc" || m_source.isLocalFile()) {
        QFile file(m_source.scheme() == u"qrc" ? u':' + m_source.path() : m_source.toLocalFile());

        if (file.open(QIODevice::ReadOnly)) {
            setCues(CaptionParser::parse(QString::fromUtf8(file.readAll())));
        }

        return;
    }

    QNetworkRequest request(m_source);
    m_reply = UdemyClient::instance()->network()->get(request);
    Q_EMIT loadingChanged();
    QNetworkReply *reply = m_reply;
    connect(reply, &QNetworkReply::finished, this, [this, reply] {
        reply->deleteLater();

        if (reply != m_reply) {
            return;
        }

        m_reply = nullptr;
        Q_EMIT loadingChanged();

        if (reply->error() == QNetworkReply::NoError) {
            setCues(CaptionParser::parse(QString::fromUtf8(reply->readAll())));
        } else {
            qWarning() << "Could not load captions" << m_source << reply->errorString();
        }
    });
}

void CaptionTrack::setCues(const QList<CaptionParser::Cue> &cues)
{
    m_cues = cues;
    updateText();
}

void CaptionTrack::updateText()
{
    const QString text = CaptionParser::textAt(m_cues, m_position);

    if (text == m_text) {
        return;
    }

    m_text = text;
    Q_EMIT textChanged();
}
