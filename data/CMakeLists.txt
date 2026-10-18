# SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
# SPDX-License-Identifier: GPL-3.0-or-later

install(PROGRAMS io.github.udemytv.desktop DESTINATION ${KDE_INSTALL_APPDIR})
install(FILES io.github.udemytv.metainfo.xml DESTINATION ${KDE_INSTALL_METAINFODIR})
install(FILES io.github.udemytv.svg DESTINATION ${KDE_INSTALL_ICONDIR}/hicolor/scalable/apps)
