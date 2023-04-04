cmake_minimum_required(VERSION 3.16)

project(PlankPlayer LANGUAGES CXX)
set(PROJECT_VERSION "5.27.4")
set(PROJECT_VERSION_MAJOR 5)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(QT_MIN_VERSION "5.15.2")
set(KF5_MIN_VERSION "5.102.0")
set(AUTORCC_OPTIONS "/app/qml.qrc")

find_package(ECM ${KF5_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake")

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(ECMInstallIcons)
include(FeatureSummary)

find_package(Qt${QT_MAJOR_VERSION} ${QT_MIN_VERSION} REQUIRED COMPONENTS
    Core
    Qml
    Quick
    QuickControls2
    Multimedia
)

find_package(KF5 ${KF5_MIN_VERSION} REQUIRED
    Kirigami2
    I18n
)

include(ECMFindQmlModule)
ecm_find_qmlmodule(QtQuick 2.12)
ecm_find_qmlmodule(QtQuick.Window 2.12)
ecm_find_qmlmodule(QtQuick.Controls 2.12)
ecm_find_qmlmodule(QtQuick.Layouts 1.12)
ecm_find_qmlmodule(QtMultimedia 5.12)
ecm_find_qmlmodule(org.kde.kirigami 2.12)
ecm_find_qmlmodule(Qt.labs.folderlistmodel 2.12)
ecm_find_qmlmodule(QtQuick.Templates 2.12)
ecm_find_qmlmodule(QtGraphicalEffects 1.0)

add_subdirectory(app)
add_subdirectory(icons)

install(FILES org.kde.invent.plank_player.metainfo.xml DESTINATION ${KDE_INSTALL_METAINFODIR})

ki18n_install(po)

feature_summary(WHAT ALL INCLUDE_QUIET_PACKAGES FATAL_ON_MISSING_REQUIRED_PACKAGES)
