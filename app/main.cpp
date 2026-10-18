// SPDX-FileCopyrightText: 2021 Aditya Mehra <aix.m@outlook.com>
// SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "thumbnailprovider.h"

#include <KAboutData>
#include <KLocalizedQmlContext>
#include <KLocalizedString>

#include <QCommandLineParser>
#include <QDir>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>

using namespace Qt::StringLiterals;

int main(int argc, char *argv[])
{
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        qputenv("QT_QUICK_CONTROLS_STYLE", "org.kde.desktop");
    }

    QGuiApplication application(argc, argv);

    KLocalizedString::setApplicationDomain("plank-player");
    KAboutData aboutData(u"plank-player"_s,
                         i18n("Plank Player"),
                         QStringLiteral(PROJECT_VERSION),
                         i18n("Play videos and music on the big screen"),
                         KAboutLicense::GPL_V2,
                         i18n("© 2021–2026 KDE Community"));
    aboutData.addAuthor(i18n("Aditya Mehra"), QString(), u"aix.m@outlook.com"_s);
    aboutData.addAuthor(i18n("Devin Lin"), QString(), u"devin@kde.org"_s);
    aboutData.setLicense(KAboutLicense::GPL_V2, KAboutLicense::OrLaterVersions);
    aboutData.setDesktopFileName(u"org.kde.plank-player"_s);
    KAboutData::setApplicationData(aboutData);
    QGuiApplication::setWindowIcon(QIcon::fromTheme(u"org.kde.plank-player"_s, QIcon(u":/org.kde.plank-player.svg"_s)));

    QCommandLineParser parser;
    aboutData.setupCommandLine(&parser);
    parser.addPositionalArgument(u"file"_s, i18n("Video or audio file to play"), u"[file]"_s);
    parser.process(application);
    aboutData.processCommandLine(&parser);

    QUrl initialUrl;
    if (!parser.positionalArguments().isEmpty()) {
        initialUrl = QUrl::fromUserInput(parser.positionalArguments().constFirst(), QDir::currentPath(), QUrl::AssumeLocalFile);
    }

    QQmlApplicationEngine engine;
    KLocalization::setupLocalizedContext(&engine);
    engine.addImageProvider(u"thumbnail"_s, new ThumbnailProvider);
    engine.setInitialProperties({{u"initialUrl"_s, initialUrl}});
    engine.loadFromModule("org.kde.plank.player", "Main");

    if (engine.rootObjects().isEmpty()) {
        return 1;
    }

    return application.exec();
}
