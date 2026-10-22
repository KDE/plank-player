// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "mediafoldermodel.h"

#include <QFileInfo>

MediaFolderModel::MediaFolderModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    m_items.setItemRoleNames(
        {{FileUrlRole, "fileUrl"}, {FileNameRole, "fileName"}, {FileSuffixRole, "fileSuffix"}, {FileIsDirRole, "fileIsDir"}, {FileSizeRole, "fileSize"}});
    setSourceModel(&m_items);
    setSortRole(FileNameRole);
    setSortCaseSensitivity(Qt::CaseInsensitive);
    sort(0);

    connect(this, &QAbstractItemModel::rowsInserted, this, &MediaFolderModel::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &MediaFolderModel::countChanged);
    connect(this, &QAbstractItemModel::modelReset, this, &MediaFolderModel::countChanged);
    connect(&m_lister, &KCoreDirLister::started, this, [this] {
        setLoading(true);
    });
    connect(&m_lister, &KCoreDirLister::completed, this, [this] {
        setLoading(false);
    });
    connect(&m_lister, &KCoreDirLister::canceled, this, [this] {
        setLoading(false);
    });
    connect(&m_lister, &KCoreDirLister::clear, &m_items, [this] {
        m_items.removeRows(0, m_items.rowCount());
    });
    connect(&m_lister, &KCoreDirLister::newItems, this, [this](const KFileItemList &items) {
        for (const auto &item : items) {
            updateItem(item.url(), item);
        }
    });
    connect(&m_lister, &KCoreDirLister::itemsDeleted, this, [this](const KFileItemList &items) {
        for (const auto &item : items) {
            QModelIndex index = sourceIndexForUrl(item.url());
            if (index.isValid()) {
                m_items.removeRow(index.row());
            }
        }
    });
    connect(&m_lister, &KCoreDirLister::refreshItems, this, [this](const QList<QPair<KFileItem, KFileItem>> &items) {
        for (const auto &[oldItem, newItem] : items) {
            updateItem(oldItem.url(), newItem);
        }
    });
    connect(&m_lister, &KCoreDirLister::redirection, this, [this](const QUrl &, const QUrl &url) {
        m_folder = url;
        Q_EMIT folderChanged();
    });
}

QUrl MediaFolderModel::folder() const
{
    return m_folder;
}

void MediaFolderModel::setFolder(const QUrl &folder)
{
    QUrl normalized = folder.adjusted(QUrl::NormalizePathSegments | QUrl::StripTrailingSlash);
    if (m_folder == normalized) {
        return;
    }
    m_folder = normalized;
    setLoading(true);
    Q_EMIT folderChanged();
    if (!m_lister.openUrl(m_folder)) {
        setLoading(false);
    }
}

QUrl MediaFolderModel::parentFolder() const
{
    return m_folder.adjusted(QUrl::RemoveFilename | QUrl::StripTrailingSlash);
}

QStringList MediaFolderModel::nameFilters() const
{
    return m_nameFilters;
}

void MediaFolderModel::setNameFilters(const QStringList &filters)
{
    if (m_nameFilters == filters) {
        return;
    }
    m_nameFilters = filters;
    m_lister.setNameFilter(filters.join(u' '));
    m_lister.emitChanges();
    Q_EMIT nameFiltersChanged();
}

bool MediaFolderModel::loading() const
{
    return m_loading;
}

void MediaFolderModel::setLoading(bool loading)
{
    if (m_loading == loading) {
        return;
    }
    m_loading = loading;
    Q_EMIT loadingChanged();
}

QVariant MediaFolderModel::get(int row, const QString &role) const
{
    int id = roleNames().key(role.toUtf8(), -1);
    return data(index(row, 0), id);
}

int MediaFolderModel::indexOf(const QUrl &url) const
{
    return mapFromSource(sourceIndexForUrl(url)).row();
}

QModelIndex MediaFolderModel::sourceIndexForUrl(const QUrl &url) const
{
    auto matches = m_items.match(m_items.index(0, 0), FileUrlRole, url, 1, Qt::MatchExactly);
    return matches.isEmpty() ? QModelIndex() : matches.first();
}

void MediaFolderModel::updateItem(const QUrl &oldUrl, const KFileItem &item)
{
    QModelIndex index = sourceIndexForUrl(oldUrl);
    if (!item.isReadable()) {
        if (index.isValid()) {
            m_items.removeRow(index.row());
        }
        return;
    }
    QMap<int, QVariant> roles{{FileUrlRole, item.url()},
                              {FileNameRole, item.name()},
                              {FileSuffixRole, QFileInfo(item.name()).suffix()},
                              {FileIsDirRole, item.isDir()},
                              {FileSizeRole, QVariant::fromValue(item.size())}};
    if (index.isValid()) {
        m_items.setItemData(index, roles);
    } else {
        auto row = new QStandardItem;
        for (auto it = roles.cbegin(); it != roles.cend(); ++it) {
            row->setData(it.value(), it.key());
        }
        m_items.appendRow(row);
    }
}

bool MediaFolderModel::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
    bool leftDir = left.data(FileIsDirRole).toBool();
    bool rightDir = right.data(FileIsDirRole).toBool();
    if (leftDir != rightDir) {
        return leftDir;
    }
    return QSortFilterProxyModel::lessThan(left, right);
}
