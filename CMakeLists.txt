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

add_subdirectory(data)

if(BUILD_TESTING)
    add_subdirectory(tests)
endif()

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)

