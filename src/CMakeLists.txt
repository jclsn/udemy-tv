# SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
# SPDX-License-Identifier: GPL-3.0-or-later

qt_add_executable(udemy-tv
    main.cpp
    apptheme.cpp
    apptheme.h
    captionparser.cpp
    captionparser.h
    captiontrack.cpp
    captiontrack.h
    coursedetails.cpp
    coursedetails.h
    courselistmodel.cpp
    courselistmodel.h
    coursesession.cpp
    coursesession.h
    curriculummodel.cpp
    curriculummodel.h
    demobackend.cpp
    demobackend.h
    lectureloader.cpp
    lectureloader.h
    lectureparser.cpp
    lectureparser.h
    remotefile.cpp
    remotefile.h
    udemyclient.cpp
    udemyclient.h
    webbridge.cpp
    webbridge.h
)

ecm_add_qml_module(udemy-tv
    URI io.github.udemytv
    GENERATE_PLUGIN_SOURCE
    NO_IMPORT_SCAN
    DEPENDENCIES
        QtQuick
        QtMultimedia
        QtWebEngine
        org.kde.bigscreen.ui
        org.kde.kirigami
)

set_source_files_properties(qml/Style.qml qml/Preferences.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

ecm_target_qml_sources(udemy-tv SOURCES
    qml/Main.qml
    qml/Preferences.qml
    qml/Style.qml

    qml/components/ApiBridge.qml
    qml/components/Avatar.qml
    qml/components/CourseCard.qml
    qml/components/OptionsDrawer.qml
    qml/components/PrimaryButton.qml
    qml/components/ProtectedVideo.qml
    qml/components/StarRating.qml
    qml/components/UdemyTabBar.qml
    qml/components/Wordmark.qml

    qml/pages/ArticleView.qml
    qml/pages/BrowsePage.qml
    qml/pages/CoursePage.qml
    qml/pages/HomePage.qml
    qml/pages/LecturePage.qml
    qml/pages/LoginPage.qml
    qml/pages/MessageView.qml
    qml/pages/NativePlayer.qml
    qml/pages/SettingsPage.qml
    qml/pages/SplashPage.qml
    qml/pages/StoreCoursePage.qml
    qml/pages/TokenPage.qml
    qml/pages/WebPage.qml
    qml/pages/WebPlayer.qml
)

qt_add_resources(udemy-tv appdata
    PREFIX /
    FILES
        bridge.js
        protectedplayer.js
        webplayer.js
        UdemyTV.colors
        UdemyTV-Dark.colors
)

# Plays copy-protected lectures with the browser engine's Widevine module
set(SHAKA_PLAYER "${CMAKE_SOURCE_DIR}/3rdparty/shaka-player/shaka-player.compiled.js")
set_source_files_properties(${SHAKA_PLAYER} PROPERTIES QT_RESOURCE_ALIAS shaka-player.compiled.js)
qt_add_resources(udemy-tv shaka
    PREFIX /
    FILES ${SHAKA_PLAYER}
)

# Sample data for --demo, shaped like the real API responses
qt_add_resources(udemy-tv demodata
    PREFIX /
    FILES
        demo/courses.json
        demo/archived.json
        demo/wishlist.json
        demo/collections.json
        demo/search.json
        demo/curriculum.json
        demo/progress.json
        demo/lecture-video.json
        demo/lecture-mashup.json
        demo/lecture-article.json
        demo/lecture-drm.json
        demo/me.json
        demo/captions-en.vtt
        demo/captions-de.vtt
        demo/slides/slide1.svg
        demo/slides/slide2.svg
        demo/slides/slide3.svg
        demo/slides/slide4.svg
        demo/slides/slide5.svg
        demo/images/altai.jpg
        demo/images/coast.jpg
        demo/images/flow.jpg
        demo/images/honeywave.jpg
        demo/images/milkyway.jpg
        demo/images/mountain.jpg
        demo/images/patak.jpg
        demo/images/scarlettree.jpg
        demo/images/shell.jpg
        demo/images/volna.jpg
)

target_link_libraries(udemy-tv PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Network
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Widgets
    Qt6::WebEngineQuick
    KF6::I18n
    KF6::I18nQml
    KF6::CoreAddons
    KF6::ColorScheme
)

if(NOT USE_SYSTEM_BIGSCREEN_UI)
    add_dependencies(udemy-tv bigscreenuiplugin)
    target_compile_definitions(udemy-tv PRIVATE
        UDEMYTV_PRIVATE_QMLDIR="${KDE_INSTALL_FULL_LIBDIR}/udemy-tv/qml")
endif()
target_compile_definitions(udemy-tv PRIVATE UDEMYTV_VERSION="${PROJECT_VERSION}")

install(TARGETS udemy-tv ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
