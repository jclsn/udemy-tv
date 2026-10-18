// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QJsonObject>
#include <QVariantMap>

/*!
   \brief Turns the lecture JSON from the Udemy API into what the player needs.

   The result is a map with:
   \list
   \li \c kind: "video", "mashup", "presentation", "article", "drm" (protected without a
       stream), "external", "file", "processing" or "unsupported"
   \li \c title, \c description (HTML), \c assetType
   \li \c duration: seconds, or 0 when unknown
   \li \c sources: playable streams, best first, as {url, label, type, height}
   \li \c source: the stream to play (an adaptive HLS stream when there is one)
   \li \c protected: whether the video is encrypted and plays through Widevine instead
   \li \c protectedSource, \c protectedType ("dash" or "hls"), \c licenseToken: for that
   \li \c captions: {label, locale, url, automatic}
   \li \c slides: for mashups and presentations, {time (seconds, -1 if untimed), image, page}
   \li \c slidesPdf: the PDF the slides come from, when they are not images
   \li \c timedSlides: whether the slides follow the video
   \li \c body: the HTML of an article
   \li \c externalUrl
   \li \c resumePosition: seconds watched last time
   \li \c thumbnail
   \li \c audioOnly
   \endlist

   Udemy does not document this API, and the shape of slides in particular has varied, so
   the parser accepts the field names seen in the wild and ignores what it doesn't know.
 */
namespace LectureParser
{
QVariantMap parse(const QJsonObject &lecture);

/*!
   \brief Parses a time given as seconds, milliseconds or "HH:MM:SS(.mmm)". Returns -1 when invalid.
 */
double parseTime(const QJsonValue &value);
}
