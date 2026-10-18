cmake_minimum_required(VERSION 3.24)

project(PlankPlayer LANGUAGES CXX)
set(PROJECT_VERSION "5.27.80")
set(PROJECT_VERSION_MAJOR 5)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(QT_MIN_VERSION "6.11.0")
set(KF6_MIN_VERSION "6.14.0")

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake")

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(ECMQmlModule)
include(ECMFindQmlModule)
include(FeatureSummary)

find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    QuickControls2
    Multimedia
    Concurrent
)

find_package(KF6 ${KF6_MIN_VERSION} REQUIRED COMPONENTS
    Config
    CoreAddons
    I18n
    Kirigami
)

ecm_find_qmlmodule(org.kde.bigscreen.ui 1.0)
ecm_find_qmlmodule(QtMultimedia)
ecm_find_qmlmodule(Qt.labs.folderlistmodel)

add_subdirectory(app)

install(FILES org.kde.plank-player.metainfo.xml DESTINATION ${KDE_INSTALL_METAINFODIR})
install(FILES org.kde.plank-player.svg DESTINATION ${KDE_INSTALL_FULL_ICONDIR}/hicolor/scalable/apps/)

ki18n_install(po)

feature_summary(WHAT ALL INCLUDE_QUIET_PACKAGES FATAL_ON_MISSING_REQUIRED_PACKAGES)
