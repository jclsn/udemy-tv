// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "curriculummodel.h"

#include <QJsonObject>

#include <cmath>

CurriculumModel::CurriculumModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int CurriculumModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_items.size();
}

QVariant CurriculumModel::data(const QModelIndex &index, int role) const
{
    if (!checkIndex(index, CheckIndexOption::IndexIsValid)) {
        return {};
    }

    const Item &item = m_items.at(index.row());

    switch (role) {
    case ItemIdRole:
        return item.id;
    case ItemClassRole:
        return item.itemClass;
    case Qt::DisplayRole:
    case TitleRole:
        return item.title;
    case NumberRole:
        return item.number;
    case SectionIndexRole:
        return item.section;
    case SectionKeyRole:
        return QString::number(item.section);
    case AssetTypeRole:
        return item.assetType;
    case DurationRole:
        return item.duration;
    case CompletedRole:
        return item.completed;
    case PlayableRole:
        return item.itemClass == u"lecture";
    }

    return {};
}

QHash<int, QByteArray> CurriculumModel::roleNames() const
{
    return {
        {ItemIdRole, "itemId"},
        {ItemClassRole, "itemClass"},
        {TitleRole, "title"},
        {NumberRole, "number"},
        {SectionIndexRole, "sectionIndex"},
        {SectionKeyRole, "sectionKey"},
        {AssetTypeRole, "assetType"},
        {DurationRole, "duration"},
        {CompletedRole, "completed"},
        {PlayableRole, "playable"},
    };
}

int CurriculumModel::count() const
{
    return m_items.size();
}

int CurriculumModel::sectionCount() const
{
    return m_sections.size();
}

int CurriculumModel::revision() const
{
    return m_revision;
}

void CurriculumModel::setItems(const QJsonArray &results)
{
    beginResetModel();
    m_items.clear();
    m_sections.clear();

    for (const QJsonValue &value : results) {
        const QJsonObject object = value.toObject();
        const QString itemClass = object.value(u"_class").toString();

        if (itemClass == u"chapter") {
            Section section;
            section.title = object.value(u"title").toString();
            section.number = object.value(u"object_index").toInt(m_sections.size() + 1);
            m_sections.append(section);
            continue;
        }

        if (object.contains(u"is_published") && !object.value(u"is_published").toBool()) {
            continue;
        }

        if (m_sections.isEmpty()) {
            // Items before the first chapter still need a header
            m_sections.append(Section{QString(), 0});
        }

        Item item;
        item.id = object.value(u"id").toInteger();
        item.itemClass = itemClass.isEmpty() ? QStringLiteral("lecture") : itemClass;
        item.title = object.value(u"title").toString();
        item.number = object.value(u"object_index").toInt();
        item.section = m_sections.size() - 1;

        const QJsonObject asset = object.value(u"asset").toObject();
        item.assetType = asset.value(u"asset_type").toString();
        item.duration = asset.value(u"time_estimation").toDouble();

        if (item.duration <= 0) {
            item.duration = asset.value(u"length").toDouble();
        }

        m_items.append(item);
    }

    endResetModel();
    Q_EMIT countChanged();
    ++m_revision;
    Q_EMIT revisionChanged();
}

void CurriculumModel::setCompletedIds(const QSet<qint64> &lectureIds, const QSet<qint64> &quizIds)
{
    for (Item &item : m_items) {
        item.completed =
            item.itemClass == u"lecture" ? lectureIds.contains(item.id) : quizIds.contains(item.id);
    }

    if (!m_items.isEmpty()) {
        Q_EMIT dataChanged(index(0), index(m_items.size() - 1), {CompletedRole});
    }

    ++m_revision;
    Q_EMIT revisionChanged();
}

void CurriculumModel::setCompleted(int row, bool completed)
{
    if (row < 0 || row >= m_items.size() || m_items.at(row).completed == completed) {
        return;
    }

    m_items[row].completed = completed;
    Q_EMIT dataChanged(index(row), index(row), {CompletedRole});
    ++m_revision;
    Q_EMIT revisionChanged();
}

const CurriculumModel::Item &CurriculumModel::item(int row) const
{
    static const Item empty;

    return row >= 0 && row < m_items.size() ? m_items.at(row) : empty;
}

int CurriculumModel::rowOf(qint64 itemId, const QString &itemClass) const
{
    for (int row = 0; row < m_items.size(); ++row) {
        if (m_items.at(row).id == itemId && m_items.at(row).itemClass == itemClass) {
            return row;
        }
    }

    return -1;
}

QString CurriculumModel::sectionTitle(int section) const
{
    if (section < 0 || section >= m_sections.size()) {
        return {};
    }

    const Section &s = m_sections.at(section);

    if (s.number <= 0) {
        return s.title;
    }

    return QStringLiteral("Section %1: %2").arg(s.number).arg(s.title);
}

QString CurriculumModel::sectionInfo(int section) const
{
    int total = 0;
    int completed = 0;
    double duration = 0;

    for (const Item &item : m_items) {
        if (item.section != section) {
            continue;
        }

        ++total;
        completed += item.completed ? 1 : 0;
        duration += item.duration;
    }

    QString info = QStringLiteral("%1 / %2").arg(completed).arg(total);

    if (duration > 0) {
        info += QStringLiteral(" | ") + formatDuration(duration);
    }

    return info;
}

int CurriculumModel::lectureCount() const
{
    return std::count_if(m_items.cbegin(), m_items.cend(), [](const Item &item) {
        return item.itemClass == u"lecture";
    });
}

int CurriculumModel::completedLectureCount() const
{
    return std::count_if(m_items.cbegin(), m_items.cend(), [](const Item &item) {
        return item.itemClass == u"lecture" && item.completed;
    });
}

QString CurriculumModel::formatDuration(double seconds, bool longForm)
{
    if (seconds <= 0) {
        return {};
    }

    const int totalMinutes = std::max(1, int(std::round(seconds / 60.0)));
    const int hours = totalMinutes / 60;
    const int minutes = totalMinutes % 60;

    if (longForm) {
        if (hours > 0) {
            return minutes > 0 ? QStringLiteral("%1h %2m").arg(hours).arg(minutes)
                               : QStringLiteral("%1h").arg(hours);
        }

        return QStringLiteral("%1m").arg(minutes);
    }

    // As Udemy writes it: "1hr 4min", "45min"
    if (hours > 0) {
        return minutes > 0 ? QStringLiteral("%1hr %2min").arg(hours).arg(minutes)
                           : QStringLiteral("%1hr").arg(hours);
    }

    return QStringLiteral("%1min").arg(minutes);
}
