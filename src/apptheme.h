// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QQmlEngine>

/*!
   \brief Udemy's colors for this app, light as on udemy.com or dark.

   The colors are KDE color schemes (UdemyTV.colors and UdemyTV-Dark.colors), which Kirigami
   and Bigscreen UI follow while the app runs.
 */
class AppTheme : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool dark READ dark WRITE setDark NOTIFY darkChanged)

public:
    explicit AppTheme(QObject *parent = nullptr);

    static AppTheme *create(QQmlEngine *, QJSEngine *);

    bool dark() const;
    void setDark(bool dark);

    /*!
       \brief Whether the dark colors were chosen in the settings, or the TV uses dark colors
       and the choice is to follow it.
     */
    static bool darkFromSettings();

    /*!
       \brief Applies the app's colors, again if something else changed them in between.
     */
    void apply();

Q_SIGNALS:
    void darkChanged();

private:
    bool m_dark = false;
};
