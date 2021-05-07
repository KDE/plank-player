cmake_minimum_required(VERSION 3.14)

project(PlankPlayer LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(QT_MIN_VERSION "5.12.0")
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

add_subdirectory(app)
add_subdirectory(icons)
