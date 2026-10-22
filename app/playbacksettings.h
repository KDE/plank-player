// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <KSharedConfig>
#include <QObject>
#include <QUrl>
#include <QVariantMap>
#include <QtQmlIntegration/qqmlintegration.h>

class PlaybackSettings : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit PlaybackSettings(QObject *parent = nullptr);
    explicit PlaybackSettings(KSharedConfig::Ptr config, KSharedConfig::Ptr stateConfig, QObject *parent = nullptr);

    Q_INVOKABLE QVariantMap load(const QUrl &source) const;
    Q_INVOKABLE void save(const QUrl &source, const QVariantMap &options);

private:
    KSharedConfig::Ptr m_config;
    KSharedConfig::Ptr m_stateConfig;
};
