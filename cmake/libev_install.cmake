# libev installation for cmake

include(GNUInstallDirs)

set(LIBEV_PC_IN "${CMAKE_CURRENT_SOURCE_DIR}/cmake/libev.pc.in" CACHE FILEPATH "pkg-config template for libev")
set(LIBEV_LIBDATA_DIR $<IF:$<STREQUAL:${CMAKE_SYSTEM_NAME},FreeBSD>,libdata,${CMAKE_INSTALL_LIBDIR}> CACHE STRING "library data dir, relative to prefix")

install(TARGETS ev DESTINATION ${CMAKE_INSTALL_LIBDIR})

install(FILES ev.h ev++.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

if(${LIBEV_INSTALL_LIBEVENT_COMPAT})
    install(FILES event.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
endif()

install(FILES ev.3 DESTINATION ${CMAKE_INSTALL_MANDIR}/man3)

install(FILES README README.embed LICENSE Changes ev.pod DESTINATION ${CMAKE_INSTALL_DOCDIR})


#
# build and install libev.pc, iff building shared libraries
#

if(${BUILD_SHARED_LIBS})
set(_ev_lib ev)

# note that this will not translate any generator expressions
get_property(LIBEV_DEFS TARGET ev PROPERTY COMPILE_DEFINITIONS)

foreach(_def IN LISTS LIBEV_DEFS)
    string(APPEND LIBEV_CFLAGS_PC " -D${_def}")
endforeach()

get_property(LIBEV_LIBS_CMAKE TARGET ev PROPERTY LINK_LIBRARIES)
foreach(_lpath IN LISTS LIBEV_LIBS_CMAKE)
    get_filename_component(_libname ${_lpath} NAME)
    string(REGEX REPLACE "^${CMAKE_SHARED_LIBRARY_PREFIX}" "" _libsfx ${_libname})
    string(REGEX REPLACE "${CMAKE_SHARED_LIBRARY_SUFFIX}$" "" _lib ${_libsfx})
    string(APPEND LIBEV_LIBS_PC " -l${_lib}")
endforeach()

configure_file(${LIBEV_PC_IN} ${CMAKE_CURRENT_BINARY_DIR}/libev.pc @ONLY)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libev.pc DESTINATION ${LIBEV_LIBDATA_DIR}/pkgconfig)

endif() # BUILD_SHARED_LIBS
