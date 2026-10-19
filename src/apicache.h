// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QJsonDocument>
#include <QString>

/*!
   \brief What Udemy answered last time, kept in an SQLite database.

   Pages show the cached answer at once and then the fresh one, so the app does not wait for
   the network (or for Cloudflare) on every start. Signed media links expire, so lectures are
   not kept.

   \code
   const QJsonDocument cached = ApiCache::instance().read(u"courses/enrolled"_s);
   ApiCache::instance().write(u"courses/enrolled"_s, fresh);
   \endcode
 */
class ApiCache
{
public:
    static ApiCache &instance();

    /*!
       \brief Turns the cache off, for the demo; reads then find nothing.
     */
    void setEnabled(bool enabled);

    /*!
       \brief Keeps the entries of each Udemy portal (www or a business subdomain) apart.
     */
    void setScope(const QString &scope);

    /*!
       \brief The cached document for \a key, or a null document. \a age receives its age in
       seconds when given.
     */
    QJsonDocument read(const QString &key, qint64 *age = nullptr) const;

    void write(const QString &key, const QJsonDocument &value);

    /*!
       \brief Forgets everything, such as when the user signs out.
     */
    void clear();

private:
    ApiCache();

    bool open() const;

    QString scopedKey(const QString &key) const;

    bool m_enabled = true;
    QString m_scope;
    mutable bool m_opened = false;
    mutable bool m_failed = false;
};
