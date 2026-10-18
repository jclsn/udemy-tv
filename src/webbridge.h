// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QQmlEngine>

/*!
   \brief The object the bridge page talks to over QWebChannel.

   It only passes calls on to UdemyClient, which tracks which requests are waiting.
 */
class WebBridge : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    using QObject::QObject;

    Q_INVOKABLE void attach();
    Q_INVOKABLE void deliver(int id, int status, const QString &body);
};
