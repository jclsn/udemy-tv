// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QByteArray>
#include <QObject>
#include <QUrl>

/*!
   \brief Answers API requests from sample data, for trying the app (--demo) without an account.

   The samples have the same shape as real responses, so the rest of the app runs unchanged.
 */
class DemoBackend : public QObject
{
    Q_OBJECT

public:
    struct Response {
        int status = 200;
        QByteArray body;
    };

    using QObject::QObject;

    Response handle(const QString &method, const QUrl &url, const QByteArray &body) const;
};
