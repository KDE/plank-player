cmake_minimum_required(VERSION 3.16)

project(PlankPlayer LANGUAGES CXX)
set(PROJECT_VERSION "5.25.80")
set(PROJECT_VERSION_MAJOR 5)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(QT_MIN_VERSION "5.15.2")
set(AUTORCC_OPTIONS "/app/qml.qrc")

find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ECM_KDE_MODULE_DIR} "${CMAKE_SOURCE_DIR}/cmake")

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings)
include(ECMInstallIcons)
include(FeatureSummary)

find_package(Qt5 ${QT_MIN_VERSION} REQUIRED COMPONENTS
    Core
    Qml
    Quick
    QuickControls2
    Multimedia
)

find_package(KF5 ${KF5_MIN_VERSION} REQUIRED
    Kirigami2
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
