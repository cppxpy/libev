# cmake port for libev.m4

set(LIBEV_CONFIG_H_IN "cmake/config.h.in" CACHE FILEPATH "Template file for config.h")
set(LIBEV_AVOID_LIBRT OFF CACHE BOOL "Avoid using librt")
set(LIBEV_AVOID_LIBM OFF CACHE BOOL "Avoid using libm")

if(POLICY CMP0075)
    cmake_policy(SET CMP0075 NEW)
endif()

# check if libm is available, for floor
if(NOT ${LIBEV_AVOID_LIBM})
    find_library(LIBEV_LIBM m)
    if(LIBEV_LIBM)
        list(APPEND CMAKE_REQUIRED_LIBRARIES m)
        target_link_libraries(ev PUBLIC ${LIBEV_LIBM})
    endif()
endif()

set(CONFIG_H "${CMAKE_CURRENT_BINARY_DIR}/include/config.h")

include_directories(${CMAKE_CURRENT_BINARY_DIR}/include/)

message(STATUS "Creating ${CONFIG_H} from ${LIBEV_CONFIG_H_IN}")

configure_file(${LIBEV_CONFIG_H_IN} ${CONFIG_H} @ONLY)

## %% porting AC_CHECK_HEADERS

include(CheckIncludeFile)
include(CheckFunctionExists)
include(CheckCSourceRuns)

# headers to check
execute_process(
    COMMAND awk "BEGIN { ORS=\";\" }
        /^AC_CHECK_HEADERS/ {
            sub(\"AC_CHECK_HEADERS\", \"\", $0);
            gsub(\"[())]\", \"\", $0);
            gsub(\" +\", \";\", $0);
            print $0;}" ${PROJECT_SOURCE_DIR}/libev.m4
    OUTPUT_VARIABLE _libev_check_headers
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

# other headers to check
#
# this is based on one instance of config.h
# as generated with GNU autotools on a Linux host

list(APPEND _libev_check_headers "dlfcn.h;inttypes.h;memory.h")
list(APPEND _libev_check_headers "stdint.h;stdlib.h;strings.h;string.h")
list(APPEND _libev_check_headers "sys/stat.h;sys/types.h;unistd.h")

# functions to check, not requiring specific source expressions
execute_process(
    COMMAND awk "BEGIN { ORS=\";\" }
    /^AC_CHECK_FUNCS([^,]+)$/ {
        sub(\"AC_CHECK_FUNCS\", \"\", $0);
        gsub(\"[())]\", \"\", $0);
        gsub(\" +\", \";\", $0);
        print $0 }" ${PROJECT_SOURCE_DIR}/libev.m4
    OUTPUT_VARIABLE _libev_check_funcs
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

# check for headers (exists)

foreach(_header ${_libev_check_headers})
    string(REGEX REPLACE "[/.]" "_" _F ${_header})
    string(TOUPPER ${_F} _VV)
    set(_hname "HAVE_${_VV}")
    if(DEFINED ${_hname})
        set(${_hname} ${${_hname}} CACHE BOOL "Have header ${_header}")
    else()
        check_include_file(${_header} ${_hname})
    endif()
    file(APPEND ${CONFIG_H} "/* Define to 1 if you have the <${_header}> header file. */\n")
    if(${_hname})
        list(APPEND HAVE_HEADERS ${_hname})
        file(APPEND ${CONFIG_H} "#define ${_hname} 1\n\n")
    else()
        file(APPEND ${CONFIG_H} "/* #undef ${_hname} */\n\n")
    endif()
endforeach()

# check for functions (exists)

foreach(_check_func ${_libev_check_funcs})
string(TOUPPER ${_check_func} _VV)
set(_hname "HAVE_${_VV}")
    if(DEFINED ${_hname})
        set(${_hname} ${${_hname}} CACHE BOOL "Have function ${_hname}")
    else()
        check_function_exists(${_check_func} ${_hname})
    endif()
    file(APPEND ${CONFIG_H} "/* Define to 1 if you have the '${_check_func}' function. */\n")
    if(${_hname})
        list(APPEND HAVE_FUNCS ${_hname})
        file(APPEND ${CONFIG_H} "#define ${_hname} 1\n\n")
    else()
        file(APPEND ${CONFIG_H} "/* #undef ${_hname} */\n\n")
    endif()
endforeach()


#
# check 'floor'
#

if(NOT DEFINED HAVE_FLOOR)
    check_function_exists(floor HAVE_FLOOR)
endif()

file(APPEND ${CONFIG_H} "/* Define to 1 if you have the 'floor' function. */\n")
if(${HAVE_FLOOR})
    list(APPEND HAVE_FUNCS floor)
    file(APPEND ${CONFIG_H} "#define HAVE_FLOOR 1\n\n")
else()
    file(APPEND ${CONFIG_H} "/* #undef HAVE_FLOOR */\n\n")
endif()

#
# check for clock_gettime, via syscall or other definition
#

if(NOT (DEFINED HAVE_CLOCK_SYSCALL OR DEFINED HAVE_CLOCK_GETTIME))
check_c_source_runs("
#include <unistd.h>
#include <sys/syscall.h>
#include <time.h>

int main(void) {
    struct timespec ts;
    int status = syscall (SYS_clock_gettime, CLOCK_REALTIME, &ts);
}"
    HAVE_CLOCK_SYSCALL
)
endif()


file(APPEND ${CONFIG_H} "# /* Define to 1 to use the syscall interface for clock_gettime */\n")
if(DEFINED HAVE_CLOCK_SYSCALL)
    set(HAVE_CLOCK_SYSCALL OFF CACHE BOOL "True if clock_gettime is available via syscall")
    list(APPEND HAVE_FUNCS clock_sycall)
    file(APPEND ${CONFIG_H} "#define HAVE_CLOCK_SYSCALL 1\n\n")
else()
    file(APPEND ${CONFIG_H} "/* #undef HAVE_CLOCK_SYSCALL */\n\n")
endif()

# no syscall. check for other definition. use librt, if available
if(NOT (${HAVE_CLOCK_SYSCALL} OR ${LIBEV_AVOID_LIBRT}))
    find_library(LIBEV_LIBRT rt)
    if(LIBEV_LIBRT)
        set(LIBEV_HAVE_LIBRT ON)
        target_link_libraries(ev PUBLIC ${LIBEV_LIBRT})
        list(APPEND CMAKE_REQUIRED_LIBRARIES rt)
    endif()
    check_function_exists(clock_gettime HAVE_CLOCK_GETTIME)
endif()

if(DEFINED HAVE_CLOCK_GETTIME OR DEFINED HAVE_CLOCK_SYSCALL)
    set(HAVE_CLOCK_GETTIME ${HAVE_CLOCK_SYSCALL} CACHE BOOL "True if clock_gettime is defined")
endif()

file(APPEND ${CONFIG_H} "/* Define to 1 if you have the 'clock_gettime' function. */\n")
if(${HAVE_CLOCK_GETTIME})
    list(APPEND HAVE_FUNCS clock_gettime)
    file(APPEND ${CONFIG_H} "#define HAVE_CLOCK_GETTIME 1\n\n")
else()
    file(APPEND ${CONFIG_H} "/* #undef HAVE_CLOCK_GETTIME */\n\n")
endif()

#
# check for nanosleep. use librt, if available
#
# for emulating nanosleep on msvc platforms, see for instance
# https://stackoverflow.com/a/41862592/1061095

if(NOT (DEFINED HAVE_NANOSLEEP OR ${LIBEV_AVOID_LIBRT}))
    # if(NOT DEFINED LIBEV_LIBRT)
    #     find_library(LIBEV_LIBRT rt)
    #     if(LIBEV_LIBRT)
    #         set(LIBEV_HAVE_LIBRT ON)
    #         target_link_libraries(ev PUBLIC ${LIBEV_LIBRT})
    #         list(APPEND CMAKE_REQUIRED_LIBRARIES rt)
    #     endif()
    # endif()
    check_function_exists(nanosleep HAVE_NANOSLEEP)
endif()

file(APPEND ${CONFIG_H} "/* Define to 1 if you have the 'nanosleep' function. */\n")
if(DEFINED HAVE_NANOSLEEP AND ${HAVE_NANOSLEEP})
    list(APPEND HAVE_FUNCS nanosleep)
    file(APPEND ${CONFIG_H} "#define HAVE_NANOSLEEP 1\n\n")
else()
    file(APPEND ${CONFIG_H} "/* #undef HAVE_NANOSLEEP */\n\n")
endif()

#
# type checks
#

if(DEFINED HAVE_KERNEL_RWF_T)
    set(HAVE_KERNEL_RWF_T ${HAVE_KERNEL_RWF_T} CACHE BOOL "linux/fs.h has defined kernel_rwf_t")
else()
check_c_source_runs("
#include <linux/fs.h>

int main(void) {
    __kernel_rwf_t typecheck;
}"
    HAVE_KERNEL_RWF_T
)
endif()

file(APPEND ${CONFIG_H} "/* Define to 1 if linux/fs.h defined kernel_rwf_t */\n")
if(${HAVE_KERNEL_RWF_T})
    # list(APPEND HAVE_TYPES kernel_rwf_t)
    file(APPEND ${CONFIG_H} "#define HAVE_KERNEL_RWF_T 1\n\n")
else()
    file(APPEND ${CONFIG_H} "/* #undef HAVE_KERNEL_RWF_T */\n\n")
endif()
