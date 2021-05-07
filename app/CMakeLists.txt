qt5_add_resources(plank_player_SRCS qml.qrc)
add_executable(PlankPlayer ${plank_player_SRCS}
    main.cpp
)

target_link_libraries(PlankPlayer
    Qt5::Quick
    Qt5::Core 
    Qt5::Qml
    Qt5::QuickControls2
    Qt5::Multimedia
    KF5::Kirigami2
)

install(TARGETS PlankPlayer ${INSTALL_TARGETS_DEFAULT_ARGS})

set(DesktopNoDisplay "false")
set(DesktopMimeType "application/vnd.debian.binary-package;application/x-rpm;")
set(DesktopExec "PlankPlayer %F")
configure_file(org.plank.player.desktop.cmake ${CMAKE_CURRENT_BINARY_DIR}/org.plank.player.desktop)
install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/org.plank.player.desktop DESTINATION ${XDG_APPS_INSTALL_DIR})
