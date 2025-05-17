
cmake_minimum_required(VERSION 3.12)

project(
    libev
    VERSION 4.33
    DESCRIPTION "a high performance full-featured event loop"
    HOMEPAGE_URL "https://software.schmorp.de/pkg/libev.html"
    LANGUAGES C CXX)


set(LIBEV_INSTALL_LIBEVENT_COMPAT ON CACHE BOOL "Install compatibility header for libevent")
set(BUILD_SHARED_LIBS ON CACHE BOOL "Build shared libraries")
set(LIBEV_CFLAGS "" CACHE STRING "Semicolon (;) delimited list for cflags in the libev build")

add_library(ev ev.c event.c)

target_compile_definitions(ev PUBLIC ${LIBEV_CFLAGS})

include(cmake/libev_m4.cmake)
include(cmake/libev_opts.cmake)
include(cmake/libev_install.cmake)
