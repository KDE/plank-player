qt_add_executable(plank-player
    folders.cpp
    folders.h
    main.cpp
    playbackhistory.cpp
    playbackhistory.h
    thumbnailprovider.cpp
    thumbnailprovider.h
)

ecm_add_qml_module(plank-player
    URI org.kde.plank.player
    GENERATE_PLUGIN_SOURCE
    NO_IMPORT_SCAN
    DEPENDENCIES
        QtQuick
        QtMultimedia
        org.kde.bigscreen.ui
        org.kde.kirigami
)

set_source_files_properties(
    qml/MediaFiles.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

ecm_target_qml_sources(plank-player SOURCES
    qml/DetailsPage.qml
    qml/HomePage.qml
    qml/LibraryPage.qml
    qml/Main.qml
    qml/MediaFiles.qml
    qml/PlayerPage.qml
    qml/SettingsPage.qml
)

ecm_target_qml_sources(plank-player PATH components SOURCES
    qml/components/AudioBackground.qml
    qml/components/AudioCover.qml
    qml/components/Breadcrumbs.qml
    qml/components/FileCard.qml
    qml/components/LibraryHeader.qml
    qml/components/LocationsDialog.qml
    qml/components/PlaybackOptionsDrawer.qml
)

qt_add_resources(plank-player "icon"
    PREFIX "/"
    BASE ".."
    FILES ../org.kde.plank-player.svg
)

target_compile_definitions(plank-player PRIVATE PROJECT_VERSION="${PROJECT_VERSION}")

target_link_libraries(plank-player PRIVATE
    Qt::Core
    Qt::Gui
    Qt::Qml
    Qt::Quick
    Qt::QuickControls2
    Qt::Multimedia
    Qt::Concurrent
    KF6::ConfigCore
    KF6::CoreAddons
    KF6::I18n
    KF6::I18nQml
)

install(TARGETS plank-player ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})

set(DesktopNoDisplay "false")
set(DesktopMimeType "application/ogg;application/x-ogg;audio/ogg;audio/vorbis;audio/x-vorbis;audio/x-vorbis+ogg;video/ogg;video/x-ogm;video/x-ogm+ogg;video/x-theora+ogg;video/x-theora;audio/x-speex;audio/opus;application/x-flac;audio/flac;audio/x-flac;audio/x-ms-asf;audio/x-ms-asx;audio/x-ms-wax;audio/x-ms-wma;video/x-ms-asf;video/x-ms-asf-plugin;video/x-ms-asx;video/x-ms-wm;video/x-ms-wmv;video/x-ms-wmx;video/x-ms-wvx;video/x-msvideo;audio/x-pn-windows-acm;video/divx;video/msvideo;video/vnd.divx;video/avi;video/x-avi;application/vnd.rn-realmedia;application/vnd.rn-realmedia-vbr;audio/vnd.rn-realaudio;audio/x-pn-realaudio;audio/x-pn-realaudio-plugin;audio/x-real-audio;audio/x-realaudio;video/vnd.rn-realvideo;audio/mpeg;audio/mpg;audio/mp1;audio/mp2;audio/mp3;audio/x-mp1;audio/x-mp2;audio/x-mp3;audio/x-mpeg;audio/x-mpg;video/mp2t;video/mpeg;video/mpeg-system;video/x-mpeg;video/x-mpeg2;video/x-mpeg-system;application/mpeg4-iod;application/mpeg4-muxcodetable;application/x-extension-m4a;application/x-extension-mp4;audio/aac;audio/m4a;audio/mp4;audio/x-m4a;audio/x-aac;video/mp4;video/mp4v-es;video/x-m4v;application/x-quicktime-media-link;application/x-quicktimeplayer;video/quicktime;application/x-matroska;audio/x-matroska;video/x-matroska;video/webm;audio/webm;audio/3gpp;audio/3gpp2;audio/AMR;audio/AMR-WB;video/3gp;video/3gpp;video/3gpp2;x-scheme-handler/mms;x-scheme-handler/mmsh;x-scheme-handler/rtsp;x-scheme-handler/rtp;x-scheme-handler/rtmp;x-scheme-handler/icy;x-scheme-handler/icyx;application/x-cd-image;x-content/video-vcd;x-content/video-svcd;x-content/video-dvd;x-content/audio-cdda;x-content/audio-player;application/ram;application/xspf+xml;audio/mpegurl;audio/x-mpegurl;audio/scpls;audio/x-scpls;text/google-video-pointer;text/x-google-video-pointer;video/vnd.mpegurl;application/vnd.apple.mpegurl;application/vnd.ms-asf;application/vnd.ms-wpl;application/sdp;audio/dv;video/dv;audio/x-aiff;audio/x-pn-aiff;video/x-anim;video/x-nsv;video/fli;video/flv;video/x-flc;video/x-fli;video/x-flv;audio/wav;audio/x-pn-au;audio/x-pn-wav;audio/x-wav;audio/x-adpcm;audio/ac3;audio/eac3;audio/vnd.dts;audio/vnd.dts.hd;audio/vnd.dolby.heaac.1;audio/vnd.dolby.heaac.2;audio/vnd.dolby.mlp;audio/basic;audio/midi;audio/x-ape;audio/x-gsm;audio/x-musepack;audio/x-tta;audio/x-wavpack;audio/x-shorten;application/x-shockwave-flash;application/x-flash-video;misc/ultravox;image/vnd.rn-realpix;audio/x-it;audio/x-mod;audio/x-s3m;audio/x-xm;application/mxf")
set(DesktopExec "plank-player %u")
configure_file(org.kde.plank-player.desktop.cmake ${CMAKE_CURRENT_BINARY_DIR}/org.kde.plank-player.desktop)
install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/org.kde.plank-player.desktop DESTINATION ${KDE_INSTALL_APPDIR})
