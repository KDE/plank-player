// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "folders.h"

#include <QDir>
#include <QFileInfo>

QUrl Folders::resolve(const QString &path) const
{
    QString input = path.trimmed();
    if (input.startsWith(QLatin1Char('~'))) {
        input.replace(0, 1, QDir::homePath());
    }

    const QString localPath = QUrl::fromUserInput(input, QString(), QUrl::AssumeLocalFile).toLocalFile();
    if (!QFileInfo(localPath).isDir()) {
        return {};
    }
    return QUrl::fromLocalFile(QDir::cleanPath(localPath));
}
