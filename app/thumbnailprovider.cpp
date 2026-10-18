// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "thumbnailprovider.h"

#include <QCoreApplication>
#include <QCryptographicHash>
#include <QDir>
#include <QFileInfo>
#include <QFutureWatcher>
#include <QMediaMetaData>
#include <QMediaPlayer>
#include <QQuickTextureFactory>
#include <QStandardPaths>
#include <QTimer>
#include <QVideoFrame>
#include <QVideoSink>
#include <QtConcurrentRun>

using namespace Qt::StringLiterals;

// Thumbnails cache width
constexpr int CACHE_WIDTH = 640;

// How many files are opened at once
constexpr int MAX_RUNNING = 2;

// Max time to render file before giving up
constexpr int TIMEOUT_MS = 10000;

QImage scaledToRequest(const QImage &image, const QSize &requestedSize)
{
    if (image.isNull() || !requestedSize.isValid() || (image.width() <= requestedSize.width() && image.height() <= requestedSize.height())) {
        return image;
    }
    return image.scaled(requestedSize, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
}

ThumbnailResponse::ThumbnailResponse(const QUrl &url, const QSize &requestedSize)
    : m_url(url)
    , m_requestedSize(requestedSize)
{
}

QQuickTextureFactory *ThumbnailResponse::textureFactory() const
{
    return QQuickTextureFactory::textureFactoryForImage(m_image);
}

QString ThumbnailResponse::errorString() const
{
    return m_image.isNull() ? u"No thumbnail available"_s : QString();
}

QUrl ThumbnailResponse::url() const
{
    return m_url;
}

void ThumbnailResponse::finish(QFuture<QImage> image)
{
    auto watcher = new QFutureWatcher<QImage>(this);
    connect(watcher, &QFutureWatcher<QImage>::finished, this, [this, watcher] {
        finish(watcher->result());
    });
    watcher->setFuture(image.then(QtFuture::Launch::Async, [size = m_requestedSize](const QImage &image) {
        return scaledToRequest(image, size);
    }));
}

void ThumbnailResponse::finish(const QImage &image)
{
    m_image = scaledToRequest(image, m_requestedSize);
    Q_EMIT finished();
}

ThumbnailProvider::ThumbnailProvider()
    : m_generator(new ThumbnailGenerator(QCoreApplication::instance()))
{
}

QQuickImageResponse *ThumbnailProvider::requestImageResponse(const QString &id, const QSize &requestedSize)
{
    const QUrl url(QUrl::fromPercentEncoding(QByteArray::fromHex(id.toLatin1())));
    auto response = new ThumbnailResponse(url, requestedSize);

    response->moveToThread(m_generator->thread());
    QMetaObject::invokeMethod(m_generator, [generator = m_generator, response = QPointer(response)] {
        if (response) {
            generator->enqueue(response);
        }
    });
    return response;
}

ThumbnailGenerator::ThumbnailGenerator(QObject *parent)
    : QObject(parent)
{
}

QString ThumbnailGenerator::cachePath(const QUrl &url)
{
    const QFileInfo info(url.toLocalFile());
    const QByteArray key = url.toString().toUtf8() + QByteArray::number(info.lastModified().toSecsSinceEpoch());
    const QString name = QString::fromLatin1(QCryptographicHash::hash(key, QCryptographicHash::Sha1).toHex());
    return QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + u"/thumbnails/"_s + name + u".jpg"_s;
}

void ThumbnailGenerator::enqueue(ThumbnailResponse *response)
{
    const QString path = cachePath(response->url());
    if (m_missing.contains(path)) {
        response->finish(QImage());
        return;
    }
    if (QFileInfo::exists(path)) {
        response->finish(QtConcurrent::run([path] {
            return QImage(path);
        }));
        return;
    }
    m_queue.append(response);
    startNext();
}

void ThumbnailGenerator::startNext()
{
    while (m_running < MAX_RUNNING && !m_queue.isEmpty()) {
        const QPointer<ThumbnailResponse> response = m_queue.takeFirst();
        if (response) {
            render(response);
        }
    }
}

void ThumbnailGenerator::render(ThumbnailResponse *response)
{
    ++m_running;

    auto player = new QMediaPlayer(this);
    auto sink = new QVideoSink(player);
    auto timeout = new QTimer(player);
    player->setVideoSink(sink);

    const QPointer<ThumbnailResponse> target(response);
    const QUrl url = response->url();
    auto done = std::make_shared<bool>(false);

    auto finish = [this, player, target, url, done](const QImage &image) {
        if (*done) {
            return;
        }
        *done = true;

        const QString path = cachePath(url);
        if (image.isNull()) {
            m_missing.insert(path);
            if (target) {
                target->finish(QImage());
            }
        } else {
            const QFuture<QImage> thumbnail = QtConcurrent::run([image, path] {
                const QImage thumbnail = image.width() > CACHE_WIDTH ? image.scaledToWidth(CACHE_WIDTH, Qt::SmoothTransformation) : image;
                QDir().mkpath(QFileInfo(path).absolutePath());
                thumbnail.save(path, "JPG", 85);
                return thumbnail;
            });
            if (target) {
                target->finish(thumbnail);
            }
        }

        player->stop();
        player->deleteLater();
        --m_running;
        startNext();
    };

    timeout->setSingleShot(true);
    connect(timeout, &QTimer::timeout, player, [finish] {
        finish({});
    });

    connect(player, &QMediaPlayer::errorOccurred, player, [finish] {
        finish({});
    });

    connect(player, &QMediaPlayer::mediaStatusChanged, player, [player, finish](QMediaPlayer::MediaStatus status) {
        if (status == QMediaPlayer::InvalidMedia) {
            finish({});
            return;
        }
        if (status != QMediaPlayer::LoadedMedia) {
            return;
        }
        if (!player->hasVideo()) {
            // Audio or anything else without pictures -> use its cover art
            const QMediaMetaData metaData = player->metaData();
            QImage cover = metaData.value(QMediaMetaData::CoverArtImage).value<QImage>();
            if (cover.isNull()) {
                cover = metaData.value(QMediaMetaData::ThumbnailImage).value<QImage>();
            }
            finish(cover);
            return;
        }

        // Skip past the opening to take frame for thumbnail
        player->setPosition(player->duration() / 10);
        player->play();
    });

    connect(sink, &QVideoSink::videoFrameChanged, player, [player, finish](const QVideoFrame &frame) {
        const qint64 target = player->duration() / 10;
        if (!frame.isValid() || frame.startTime() / 1000 < target - 1000) {
            return;
        }
        finish(frame.toImage());
    });

    player->setSource(url);
    timeout->start(TIMEOUT_MS);
}

#include "moc_thumbnailprovider.cpp"
