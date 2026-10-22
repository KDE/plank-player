// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <KCoreDirLister>
#include <QSortFilterProxyModel>
#include <QStandardItemModel>
#include <QtQmlIntegration/qqmlintegration.h>

class MediaFolderModel : public QSortFilterProxyModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QUrl folder READ folder WRITE setFolder NOTIFY folderChanged)
    Q_PROPERTY(QUrl parentFolder READ parentFolder NOTIFY folderChanged)
    Q_PROPERTY(QStringList nameFilters READ nameFilters WRITE setNameFilters NOTIFY nameFiltersChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Role {
        FileUrlRole = Qt::UserRole + 1,
        FileNameRole,
        FileSuffixRole,
        FileIsDirRole,
        FileSizeRole,
    };
    Q_ENUM(Role)

    explicit MediaFolderModel(QObject *parent = nullptr);

    QUrl folder() const;
    void setFolder(const QUrl &folder);
    QUrl parentFolder() const;
    QStringList nameFilters() const;
    void setNameFilters(const QStringList &filters);
    bool loading() const;

    Q_INVOKABLE QVariant get(int row, const QString &role) const;
    Q_INVOKABLE int indexOf(const QUrl &url) const;

Q_SIGNALS:
    void folderChanged();
    void nameFiltersChanged();
    void loadingChanged();
    void countChanged();

protected:
    bool lessThan(const QModelIndex &left, const QModelIndex &right) const override;

private:
    QModelIndex sourceIndexForUrl(const QUrl &url) const;
    void updateItem(const QUrl &oldUrl, const KFileItem &item);
    void setLoading(bool loading);

    QStandardItemModel m_items;
    KCoreDirLister m_lister;
    QUrl m_folder;
    QStringList m_nameFilters;
    bool m_loading = false;
};
