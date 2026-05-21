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

# Backends driven by wyvrn options (-DIMGUI_PLATFORM=..., -DIMGUI_RENDERER=...).
# Both empty → core-only build (matches pre-options behaviour for direct cmake use).
set(IMGUI_PLATFORM "" CACHE STRING "ImGui platform backend (glfw, win32)")
set(IMGUI_RENDERER "" CACHE STRING "ImGui renderer backend (directx12, directx11, opengl, vulkan)")

set(IMGUI_BACKEND_HEADERS "")
set(IMGUI_BACKEND_LIBS "")

# Treat "none" as the explicit opt-out (same as empty), so consumers can
# disable a backend via wyvrn options without dropping back to defaults.
if(IMGUI_PLATFORM STREQUAL "none")
    set(IMGUI_PLATFORM "")
endif()
if(IMGUI_RENDERER STREQUAL "none")
    set(IMGUI_RENDERER "")
endif()

if(IMGUI_PLATFORM STREQUAL "glfw")
    list(APPEND IMGUI_SOURCES         backends/imgui_impl_glfw.cpp)
    list(APPEND IMGUI_BACKEND_HEADERS backends/imgui_impl_glfw.h)
    find_package(glfw3 CONFIG REQUIRED)
    list(APPEND IMGUI_BACKEND_LIBS glfw)
elseif(IMGUI_PLATFORM STREQUAL "win32")
    list(APPEND IMGUI_SOURCES         backends/imgui_impl_win32.cpp)
    list(APPEND IMGUI_BACKEND_HEADERS backends/imgui_impl_win32.h)
    list(APPEND IMGUI_BACKEND_LIBS dwmapi)
elseif(NOT IMGUI_PLATFORM STREQUAL "")
    message(FATAL_ERROR "Unknown IMGUI_PLATFORM '${IMGUI_PLATFORM}' — expected: glfw, win32")
endif()

if(IMGUI_RENDERER STREQUAL "directx11")
    list(APPEND IMGUI_SOURCES         backends/imgui_impl_dx11.cpp)
    list(APPEND IMGUI_BACKEND_HEADERS backends/imgui_impl_dx11.h)
    list(APPEND IMGUI_BACKEND_LIBS d3d11 dxgi d3dcompiler)
elseif(IMGUI_RENDERER STREQUAL "directx12")
    list(APPEND IMGUI_SOURCES         backends/imgui_impl_dx12.cpp)
    list(APPEND IMGUI_BACKEND_HEADERS backends/imgui_impl_dx12.h)
    list(APPEND IMGUI_BACKEND_LIBS d3d12 dxgi d3dcompiler)
elseif(IMGUI_RENDERER STREQUAL "opengl")
    list(APPEND IMGUI_SOURCES         backends/imgui_impl_opengl3.cpp)
    list(APPEND IMGUI_BACKEND_HEADERS backends/imgui_impl_opengl3.h
                                      backends/imgui_impl_opengl3_loader.h)
    find_package(OpenGL REQUIRED)
    list(APPEND IMGUI_BACKEND_LIBS OpenGL::GL)
elseif(IMGUI_RENDERER STREQUAL "vulkan")
    list(APPEND IMGUI_SOURCES         backends/imgui_impl_vulkan.cpp)
    list(APPEND IMGUI_BACKEND_HEADERS backends/imgui_impl_vulkan.h)
    find_package(Vulkan REQUIRED)
    list(APPEND IMGUI_BACKEND_LIBS Vulkan::Vulkan)
elseif(NOT IMGUI_RENDERER STREQUAL "")
    message(FATAL_ERROR "Unknown IMGUI_RENDERER '${IMGUI_RENDERER}' — expected: directx12, directx11, opengl, vulkan")
endif()

add_library(imgui STATIC ${IMGUI_SOURCES})
add_library(imgui::imgui ALIAS imgui)

target_include_directories(imgui PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/backends>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)

if(IMGUI_BACKEND_LIBS)
    target_link_libraries(imgui PUBLIC ${IMGUI_BACKEND_LIBS})
endif()

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

if(IMGUI_BACKEND_HEADERS)
    install(FILES ${IMGUI_BACKEND_HEADERS}
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/backends)
endif()

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
