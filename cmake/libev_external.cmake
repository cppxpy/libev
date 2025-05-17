# example autotools-based build for libev with cmake

include(ExternalProject)
find_program(GNU_MAKE_PROGRAM NAMES gmake make smake REQUIRED)

set(LIBEV_SOURCE_DIR "${PROJECT_SOURCE_DIR}" CACHE PATH "libev source directory")
set(LIBEV_AUTORECONF "autoreconf" CACHE STRING "autoreconf command for libev build")

ExternalProject_Add(libev
    # DOWNLOAD_COMMAND    "" # use vendored source
    GIT_REPOSITORY      "https://github.com/cppxpy/libev.git"
    GIT_TAG             "main"
    GIT_SHALLOW         true
    UPDATE_DISCONNECTED true

    SOURCE_DIR          "${LIBEV_SOURCE_DIR}"
    BINARY_DIR          "${CMAKE_BINARY_DIR}/_deps/libev-build"

    CONFIGURE_COMMAND   "${LIBEV_SOURCE_DIR}/configure"
    BUILD_COMMAND       "${GNU_MAKE_PROGRAM}"
    INSTALL_COMMAND     "${GNU_MAKE_PROGRAM} -C ${CMAKE_BINARY_DIR}/_deps/libev-build install"
)

ExternalProject_Add_Step(libev autogen
    COMMAND           "${LIBEV_AUTORECONF}" --install --symlink --force
    COMMENT           "Run autoreconf for libev"
    DEPENDEES         update patch
    DEPENDERS         configure
    BYPRODUCTS        "${LIBEV_SOURCE_DIR}/configure"
    WORKING_DIRECTORY "${LIBEV_SOURCE_DIR}"
    LOG               on
)

add_custom_target(libev_vendor)
add_dependencies(libev_vendor libev)
