// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "playbacksettings.h"

#include <KConfigGroup>

#include <utility>

using namespace Qt::StringLiterals;

PlaybackSettings::PlaybackSettings(QObject *parent)
    : PlaybackSettings(KSharedConfig::openConfig(), KSharedConfig::openStateConfig(), parent)
{
}

PlaybackSettings::PlaybackSettings(KSharedConfig::Ptr config, KSharedConfig::Ptr stateConfig, QObject *parent)
    : QObject(parent)
    , m_config(std::move(config))
    , m_stateConfig(std::move(stateConfig))
{
}

QVariantMap PlaybackSettings::load(const QUrl &source) const
{
    KConfigGroup defaults = m_config->group(u"Playback"_s);
    KConfigGroup tracks = m_stateConfig->group(u"Playback"_s).group(source.toString());
    QVariantMap options{{u"playbackRate"_s, defaults.readEntry("playbackRate", 1.0)},
                        {u"fillMode"_s, defaults.readEntry("fillMode", int(Qt::KeepAspectRatio))}};
    for (const auto *key : {"audioTrack", "subtitleTrack"}) {
        if (tracks.hasKey(key)) {
            options.insert(QString::fromLatin1(key), tracks.readEntry(key, -1));
        }
    }
    return options;
}

void PlaybackSettings::save(const QUrl &source, const QVariantMap &options)
{
    KConfigGroup defaults = m_config->group(u"Playback"_s);
    for (const auto *key : {"playbackRate", "fillMode"}) {
        if (options.contains(QLatin1String(key))) {
            defaults.writeEntry(key, options.value(QLatin1String(key)));
        }
    }
    if (!source.isEmpty()) {
        KConfigGroup tracks = m_stateConfig->group(u"Playback"_s).group(source.toString());
        for (const auto *key : {"audioTrack", "subtitleTrack"}) {
            if (options.contains(QLatin1String(key))) {
                tracks.writeEntry(key, options.value(QLatin1String(key)));
            }
        }
    }
    m_config->sync();
    m_stateConfig->sync();
}
