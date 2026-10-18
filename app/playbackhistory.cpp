// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "playbackhistory.h"

#include <KConfigGroup>

#include <QFileInfo>

#include <algorithm>
#include <utility>

using namespace Qt::StringLiterals;

// Within this much of the end the media counts as "finished"
static constexpr qreal FINISHED_THRESHOLD = 0.95;

static constexpr int MAXIMUM_ENTRIES = 50;

bool HistoryEntry::isFinished() const
{
    return duration > 0 && position >= duration * FINISHED_THRESHOLD;
}

qreal HistoryEntry::progress() const
{
    if (duration <= 0 || position <= 0 || isFinished()) {
        return -1;
    }
    return qreal(position) / duration;
}

qint64 HistoryEntry::resumePosition() const
{
    return isFinished() ? 0 : position;
}

PlaybackHistory::PlaybackHistory(QObject *parent)
    : PlaybackHistory(KSharedConfig::openStateConfig(), KSharedConfig::openConfig(), parent)
{
}

PlaybackHistory::PlaybackHistory(KSharedConfig::Ptr stateConfig, KSharedConfig::Ptr config, QObject *parent)
    : QAbstractListModel(parent)
    , m_config(std::move(stateConfig))
    , m_settings(std::move(config))
{
    load();

    connect(this, &QAbstractItemModel::rowsInserted, this, &PlaybackHistory::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &PlaybackHistory::countChanged);
    connect(this, &QAbstractItemModel::modelReset, this, &PlaybackHistory::countChanged);
}

int PlaybackHistory::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_entries.size();
}

QVariant PlaybackHistory::data(const QModelIndex &index, int role) const
{
    if (!checkIndex(index, CheckIndexOption::IndexIsValid | CheckIndexOption::ParentIsInvalid)) {
        return {};
    }

    const HistoryEntry &entry = m_entries.at(index.row());
    switch (role) {
    case Qt::DisplayRole:
    case TitleRole:
        return entry.title;
    case UrlRole:
        return entry.url;
    case PositionRole:
        return entry.position;
    case DurationRole:
        return entry.duration;
    case LastPlayedRole:
        return entry.lastPlayed;
    case FinishedRole:
        return entry.isFinished();
    case ProgressRole:
        return entry.progress();
    case EntryRole:
        return QVariant::fromValue(entry);
    }
    return {};
}

QHash<int, QByteArray> PlaybackHistory::roleNames() const
{
    return {
        {UrlRole, "url"},
        {TitleRole, "title"},
        {PositionRole, "position"},
        {DurationRole, "duration"},
        {LastPlayedRole, "lastPlayed"},
        {FinishedRole, "finished"},
        {ProgressRole, "progress"},
        {EntryRole, "entry"},
    };
}

QVariant PlaybackHistory::lastUnfinished() const
{
    const auto it = std::ranges::find_if(m_entries, [](const HistoryEntry &entry) {
        return entry.progress() > 0;
    });
    return it != m_entries.cend() ? QVariant::fromValue(*it) : QVariant();
}

bool PlaybackHistory::isSaving() const
{
    return m_settings->group(u"History"_s).readEntry("Saving", true);
}

void PlaybackHistory::setSaving(bool saving)
{
    if (isSaving() == saving) {
        return;
    }
    KConfigGroup group = m_settings->group(u"History"_s);
    group.writeEntry("Saving", saving);
    group.sync();
    Q_EMIT savingChanged();
}

void PlaybackHistory::update(const QUrl &url, const QString &title, qint64 position, qint64 duration)
{
    if (url.isEmpty() || !isSaving()) {
        return;
    }

    int row = indexOf(url);
    if (row > 0) {
        beginMoveRows(QModelIndex(), row, row, QModelIndex(), 0);
        m_entries.move(row, 0);
        endMoveRows();
    } else if (row < 0) {
        HistoryEntry entry;
        entry.url = url;
        beginInsertRows(QModelIndex(), 0, 0);
        m_entries.prepend(entry);
        endInsertRows();
    }

    HistoryEntry &entry = m_entries.first();
    entry.title = title;
    entry.position = std::max<qint64>(0, position);
    entry.duration = std::max<qint64>(0, duration);
    entry.lastPlayed = QDateTime::currentDateTime();
    Q_EMIT dataChanged(index(0), index(0));

    if (m_entries.size() > MAXIMUM_ENTRIES) {
        beginRemoveRows(QModelIndex(), MAXIMUM_ENTRIES, m_entries.size() - 1);
        const QList<HistoryEntry> removed = m_entries.sliced(MAXIMUM_ENTRIES);
        m_entries.resize(MAXIMUM_ENTRIES);
        endRemoveRows();

        for (const HistoryEntry &entry : removed) {
            forget(entry.url);
            Q_EMIT entryChanged(entry.url);
        }
    }

    save(entry);
    Q_EMIT entryChanged(url);
    Q_EMIT lastUnfinishedChanged();
}

void PlaybackHistory::remove(const QUrl &url)
{
    const int row = indexOf(url);
    if (row < 0) {
        return;
    }

    beginRemoveRows(QModelIndex(), row, row);
    m_entries.removeAt(row);
    endRemoveRows();

    forget(url);
    Q_EMIT entryChanged(url);
    Q_EMIT lastUnfinishedChanged();
}

void PlaybackHistory::clear()
{
    if (m_entries.isEmpty()) {
        return;
    }

    beginResetModel();
    const QList<HistoryEntry> entries = std::exchange(m_entries, {});
    endResetModel();

    m_config->deleteGroup(u"History"_s);
    m_config->sync();

    for (const HistoryEntry &entry : entries) {
        Q_EMIT entryChanged(entry.url);
    }
    Q_EMIT lastUnfinishedChanged();
}

qint64 PlaybackHistory::resumePosition(const QUrl &url) const
{
    const HistoryEntry *entry = find(url);
    return entry ? entry->resumePosition() : 0;
}

qreal PlaybackHistory::progress(const QUrl &url) const
{
    const HistoryEntry *entry = find(url);
    return entry ? entry->progress() : -1;
}

int PlaybackHistory::indexOf(const QUrl &url) const
{
    const auto it = std::ranges::find(m_entries, url, &HistoryEntry::url);
    return it != m_entries.cend() ? std::distance(m_entries.cbegin(), it) : -1;
}

const HistoryEntry *PlaybackHistory::find(const QUrl &url) const
{
    const int row = indexOf(url);
    return row >= 0 ? &m_entries.at(row) : nullptr;
}

// Each entry is saved in its own group named after its url
void PlaybackHistory::load()
{
    KConfigGroup history = m_config->group(u"History"_s);
    bool changed = false;
    for (const QString &name : history.groupList()) {
        const QUrl url(name);

        // Delete entries that don't exist
        if (url.isLocalFile() && !QFileInfo::exists(url.toLocalFile())) {
            history.deleteGroup(name);
            changed = true;
            continue;
        }

        const KConfigGroup group = history.group(name);
        m_entries.append(HistoryEntry{
            .url = url,
            .title = group.readEntry("Title", QString()),
            .position = group.readEntry("Position", qint64(0)),
            .duration = group.readEntry("Duration", qint64(0)),
            .lastPlayed = group.readEntry("LastPlayed", QDateTime()),
        });
    }

    std::ranges::sort(m_entries, std::greater(), &HistoryEntry::lastPlayed);
    while (m_entries.size() > MAXIMUM_ENTRIES) {
        history.deleteGroup(m_entries.takeLast().url.toString());
        changed = true;
    }

    if (changed) {
        m_config->sync();
    }
}

void PlaybackHistory::save(const HistoryEntry &entry)
{
    KConfigGroup group = m_config->group(u"History"_s).group(entry.url.toString());
    group.writeEntry("Title", entry.title);
    group.writeEntry("Position", entry.position);
    group.writeEntry("Duration", entry.duration);
    group.writeEntry("LastPlayed", entry.lastPlayed);
    m_config->sync();
}

void PlaybackHistory::forget(const QUrl &url)
{
    m_config->group(u"History"_s).deleteGroup(url.toString());
    m_config->sync();
}

HistoryFilterModel::HistoryFilterModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
}

HistoryFilterModel::Filter HistoryFilterModel::filter() const
{
    return m_filter;
}

void HistoryFilterModel::setFilter(Filter filter)
{
    if (m_filter == filter) {
        return;
    }
    beginFilterChange();
    m_filter = filter;
    endFilterChange(Direction::Rows);
    Q_EMIT filterChanged();
}

bool HistoryFilterModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    const QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
    switch (m_filter) {
    case Unfinished:
        return index.data(PlaybackHistory::ProgressRole).toReal() > 0;
    case Finished:
        return index.data(PlaybackHistory::FinishedRole).toBool();
    }
    return false;
}
