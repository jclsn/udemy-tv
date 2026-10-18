# SPDX-FileCopyrightText: 2026 Devin Lin <devin@kde.org>
# SPDX-License-Identifier: LGPL-2.0-or-later

ecm_add_qml_module(bigscreenuiplugin
    URI org.kde.bigscreen.ui
    VERSION 1.0
    GENERATE_PLUGIN_SOURCE
    DEPENDENCIES
        QtQuick
        org.kde.kirigami
)

set_source_files_properties(qml/Units.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

target_sources(bigscreenuiplugin PRIVATE
    backhandler.cpp
    backhandler.h
    keynavigationgroup.cpp
    keynavigationgroup.h
)

ecm_target_qml_sources(bigscreenuiplugin SOURCES
    qml/ApplicationWindow.qml
    qml/Page.qml
    qml/ScrollablePage.qml
    qml/Units.qml

    qml/controls/Badge.qml
    qml/controls/BusyIndicator.qml
    qml/controls/Button.qml
    qml/controls/Chip.qml
    qml/controls/ChipBar.qml
    qml/controls/Label.qml
    qml/controls/PlaceholderMessage.qml
    qml/controls/ProgressBar.qml
    qml/controls/RoundButton.qml
    qml/controls/SeekBar.qml
    qml/controls/SwitchIndicator.qml
    qml/controls/TextField.qml

    qml/delegates/ButtonDelegate.qml
    qml/delegates/ComboBoxDelegate.qml
    qml/delegates/ItemDelegate.qml
    qml/delegates/SwitchDelegate.qml
    qml/delegates/TextDelegate.qml

    qml/navigation/NavigationBar.qml
    qml/navigation/NavigationTab.qml
    qml/navigation/Sidebar.qml
    qml/navigation/StackView.qml

    qml/media/AmbientBackground.qml
    qml/media/BackdropImage.qml
    qml/media/ContentRail.qml
    qml/media/HeroBanner.qml
    qml/media/MediaCard.qml
    qml/media/MediaGrid.qml
    qml/media/PlayerOverlay.qml
    qml/media/RailView.qml

    qml/overlays/ContextDrawer.qml
    qml/overlays/ContextDrawerHeader.qml
    qml/overlays/Dialog.qml
    qml/overlays/DialogButtonBox.qml
    qml/overlays/QuitDialog.qml
    qml/overlays/Toast.qml

    qml/utils/DelegateBackground.qml
    qml/utils/EdgeFadeEffect.qml
    qml/utils/PopupBackground.qml

    qml/views/GridView.qml
    qml/views/ListView.qml
)

target_link_libraries(bigscreenuiplugin PRIVATE
    Qt6::Qml
    Qt6::Quick
)

ecm_finalize_qml_module(bigscreenuiplugin DESTINATION ${KDE_INSTALL_QMLDIR})
