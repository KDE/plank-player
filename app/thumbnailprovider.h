// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <QFuture>
#include <QImage>
#include <QList>
#include <QPointer>
#include <QSet>
#include <QQuickAsyncImageProvider>
#include <QQuickImageResponse>
#include <QUrl>

class ThumbnailGenerator;

class ThumbnailResponse : public QQuickImageResponse
{
    Q_OBJECT

public:
    ThumbnailResponse(const QUrl &url, const QSize &requestedSize);

    QQuickTextureFactory *textureFactory() const override;
    QString errorString() const override;

    QUrl url() const;
    void finish(QFuture<QImage> image);
    void finish(const QImage &image);

private:
    QUrl m_url;
    QSize m_requestedSize;
    QImage m_image;
};

class ThumbnailProvider : public QQuickAsyncImageProvider
{
public:
    ThumbnailProvider();

    QQuickImageResponse *requestImageResponse(const QString &id, const QSize &requestedSize) override;

private:
    ThumbnailGenerator *m_generator;
};

class ThumbnailGenerator : public QObject
{
    Q_OBJECT

public:
    explicit ThumbnailGenerator(QObject *parent = nullptr);

    void enqueue(ThumbnailResponse *response);

    static QString cachePath(const QUrl &url);

private:
    void startNext();
    void render(ThumbnailResponse *response);

    QList<QPointer<ThumbnailResponse>> m_queue;
    int m_running = 0;

    // Files without a thumbnail, by cache path, so they aren't opened again
    QSet<QString> m_missing;
};
