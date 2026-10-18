// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <KSharedConfig>

#include <QAbstractListModel>
#include <QDateTime>
#include <QHash>
#include <QSortFilterProxyModel>
#include <QUrl>
#include <QtQmlIntegration/qqmlintegration.h>

class HistoryEntry
{
    Q_GADGET
    QML_VALUE_TYPE(historyEntry)

    Q_PROPERTY(QUrl url MEMBER url)
    Q_PROPERTY(QString title MEMBER title)
    Q_PROPERTY(qint64 position MEMBER position)
    Q_PROPERTY(qint64 duration MEMBER duration)
    Q_PROPERTY(QDateTime lastPlayed MEMBER lastPlayed)
    Q_PROPERTY(bool finished READ isFinished)
    Q_PROPERTY(qreal progress READ progress)

public:
    QUrl url;
    QString title;
    qint64 position = 0; // ms
    qint64 duration = 0; // ms
    QDateTime lastPlayed;

    // Was watched
    bool isFinished() const;

    // Progress (0-1) of media
    qreal progress() const;

    // Resume position in ms
    qint64 resumePosition() const;
};

class PlaybackHistory : public QAbstractListModel
{
    Q_OBJECT
    QML_NAMED_ELEMENT(History)
    QML_SINGLETON

    // Most recently unfinished media
    Q_PROPERTY(QVariant lastUnfinished READ lastUnfinished NOTIFY lastUnfinishedChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(bool saving READ isSaving WRITE setSaving NOTIFY savingChanged)

public:
    enum Roles {
        UrlRole = Qt::UserRole + 1,
        TitleRole,
        PositionRole,
        DurationRole,
        LastPlayedRole,
        FinishedRole,
        ProgressRole,
        EntryRole,
    };
    Q_ENUM(Roles)

    explicit PlaybackHistory(QObject *parent = nullptr);
    explicit PlaybackHistory(KSharedConfig::Ptr stateConfig, KSharedConfig::Ptr config, QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    QVariant lastUnfinished() const;

    bool isSaving() const;
    void setSaving(bool saving);

    Q_INVOKABLE void update(const QUrl &url, const QString &title, qint64 position, qint64 duration);
    Q_INVOKABLE void remove(const QUrl &url);

    Q_INVOKABLE void clear();

    Q_INVOKABLE qint64 resumePosition(const QUrl &url) const;
    Q_INVOKABLE qreal progress(const QUrl &url) const;

Q_SIGNALS:
    void lastUnfinishedChanged();
    void countChanged();
    void savingChanged();
    void entryChanged(const QUrl &url);

private:
    int indexOf(const QUrl &url) const;
    const HistoryEntry *find(const QUrl &url) const;
    void load();
    void save(const HistoryEntry &entry);
    void forget(const QUrl &url);

    KSharedConfig::Ptr m_config;
    KSharedConfig::Ptr m_settings;
    QList<HistoryEntry> m_entries;
};

class HistoryFilterModel : public QSortFilterProxyModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(Filter filter READ filter WRITE setFilter NOTIFY filterChanged)

public:
    enum Filter {
        Unfinished,
        Finished,
    };
    Q_ENUM(Filter)

    explicit HistoryFilterModel(QObject *parent = nullptr);

    Filter filter() const;
    void setFilter(Filter filter);

Q_SIGNALS:
    void filterChanged();

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;

private:
    Filter m_filter = Unfinished;
};
