cmake_minimum_required(VERSION 3.19)

file(READ "${CMAKE_CURRENT_SOURCE_DIR}/wyvrn.json" WYVRN_JSON)
string(JSON WYVRN_PROJECT_VERSION GET "${WYVRN_JSON}" version)

project(imgui VERSION ${WYVRN_PROJECT_VERSION} LANGUAGES CXX)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

set(IMGUI_SOURCES
    imgui.cpp
    imgui_demo.cpp
    imgui_draw.cpp
    imgui_tables.cpp
    imgui_widgets.cpp)

set(IMGUI_PUBLIC_HEADERS
    imgui.h
    imconfig.h)

set(IMGUI_INTERNAL_HEADERS
    imgui_internal.h
    imstb_rectpack.h
    imstb_textedit.h
    imstb_truetype.h)

add_library(imgui STATIC ${IMGUI_SOURCES})
add_library(imgui::imgui ALIAS imgui)

target_include_directories(imgui PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)

set_target_properties(imgui PROPERTIES
    DEBUG_POSTFIX d
    RELWITHDEBINFO_POSTFIX rd
    MINSIZEREL_POSTFIX msr)

install(TARGETS imgui EXPORT imguiTargets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

install(FILES ${IMGUI_PUBLIC_HEADERS} ${IMGUI_INTERNAL_HEADERS}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

install(EXPORT imguiTargets
    FILE imguiTargets.cmake
    NAMESPACE imgui::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/imgui)

file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/imguiConfig.cmake"
    "include(\"\${CMAKE_CURRENT_LIST_DIR}/imguiTargets.cmake\")\n")

write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/imguiConfigVersion.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY AnyNewerVersion)

install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/imguiConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/imguiConfigVersion.cmake"
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/imgui)
