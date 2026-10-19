# SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
# SPDX-License-Identifier: GPL-3.0-or-later

cmake_minimum_required(VERSION 3.24)

project(udemy-tv VERSION 0.1.0)

set(QT_MIN_VERSION "6.11.0")
set(KF_MIN_VERSION "6.14.0")

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(ECM ${KF_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(ECMQmlModule)
include(FeatureSummary)

find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS
    Core
    Gui
    Network
    Qml
    Quick
    QuickControls2
    Sql
    Widgets
    Multimedia
    WebEngineQuick
    WebChannel
)
find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS
    Kirigami
    I18n
    CoreAddons
    ColorScheme
)

option(USE_SYSTEM_BIGSCREEN_UI
    "Use an installed org.kde.bigscreen.ui QML module instead of the vendored copy" OFF)
if(NOT USE_SYSTEM_BIGSCREEN_UI)
    # Bigscreen UI is not packaged yet. Build the vendored copy and install it to a private
    # QML directory so it can never clash with a system package installed later.
    set(UDEMYTV_PRIVATE_QMLDIR "${KDE_INSTALL_LIBDIR}/udemy-tv/qml")
    set(_system_qmldir "${KDE_INSTALL_QMLDIR}")
    set(KDE_INSTALL_QMLDIR "${UDEMYTV_PRIVATE_QMLDIR}")
    add_subdirectory(3rdparty/bigscreen-ui/src)
    set(KDE_INSTALL_QMLDIR "${_system_qmldir}")
endif()

add_subdirectory(src)
add_subdirectory(data)

if(BUILD_TESTING)
    add_subdirectory(tests)
endif()

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)

# Debian packages, made with: cpack -G DEB (configure with -DCMAKE_INSTALL_PREFIX=/usr)
set(CPACK_PACKAGE_NAME "udemy-tv")
set(CPACK_PACKAGE_VENDOR "Jan Claussen")
set(CPACK_PACKAGE_CONTACT "Jan Claussen <jan.claussen10@web.de>")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Unofficial Udemy app for Plasma Bigscreen")
set(CPACK_PACKAGE_HOMEPAGE_URL "https://github.com/jclsn/udemy-tv")
set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)
set(CPACK_DEBIAN_PACKAGE_SECTION "education")
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
# QML modules are loaded at run time, so shlibdeps cannot find them
set(CPACK_DEBIAN_PACKAGE_DEPENDS
    "qml6-module-org-kde-kirigami, qml6-module-qtwebengine, qml6-module-qtwebchannel, \
qml6-module-qtmultimedia, qml6-module-qtquick-layouts, qml6-module-qtquick-templates, \
qml6-module-qtquick-effects, qml6-module-qtcore, libqt6sql6-sqlite")
set(CPACK_DEBIAN_PACKAGE_RECOMMENDS "qml6-module-qtquick-pdf, qml6-module-org-kde-desktop")
include(CPack)
