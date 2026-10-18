# SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
# SPDX-License-Identifier: GPL-3.0-or-later

include(ECMAddTests)

find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS Test)

ecm_add_test(lectureparsertest.cpp ${CMAKE_SOURCE_DIR}/src/lectureparser.cpp
    TEST_NAME lectureparsertest
    LINK_LIBRARIES Qt6::Test Qt6::Core)
target_include_directories(lectureparsertest PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_compile_definitions(lectureparsertest PRIVATE
    DEMO_DIR="${CMAKE_SOURCE_DIR}/src/demo"
    TEST_DATA_DIR="${CMAKE_CURRENT_SOURCE_DIR}/data")

ecm_add_test(captionparsertest.cpp ${CMAKE_SOURCE_DIR}/src/captionparser.cpp
    TEST_NAME captionparsertest
    LINK_LIBRARIES Qt6::Test Qt6::Core)
target_include_directories(captionparsertest PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_compile_definitions(captionparsertest PRIVATE DEMO_DIR="${CMAKE_SOURCE_DIR}/src/demo")
