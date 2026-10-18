// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include "captionparser.h"

#include <QObject>
#include <QPointer>
#include <QQmlEngine>
#include <QUrl>

class QNetworkReply;

/*!
   \brief A WebVTT caption track, and the text to show at the playback position.

   \code
   CaptionTrack {
       source: lecture.captions[0].url
       position: player.position
   }
   \endcode
 */
class CaptionTrack : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(qint64 position READ position WRITE setPosition NOTIFY positionChanged)
    Q_PROPERTY(QString text READ text NOTIFY textChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)

public:
    using QObject::QObject;
    ~CaptionTrack() override;

    QUrl source() const;
    void setSource(const QUrl &source);
    qint64 position() const;
    void setPosition(qint64 position);
    QString text() const;
    bool loading() const;

Q_SIGNALS:
    void sourceChanged();
    void positionChanged();
    void textChanged();
    void loadingChanged();

private:
    void load();
    void setCues(const QList<CaptionParser::Cue> &cues);
    void updateText();

    QUrl m_source;
    qint64 m_position = 0;
    QString m_text;
    QList<CaptionParser::Cue> m_cues;
    QPointer<QNetworkReply> m_reply;
};
