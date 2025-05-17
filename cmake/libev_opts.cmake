# Build-time options for libev
#
# Reference:
# - Preprocessor Symbols/Macros in manual page ev(3)
#
# These are each defined with a reasonable default in ev.h,
# with a corresponding description availble in the ev(3) manual
# page.
#

set(EV_MINPRI "-2" CACHE STRING "Minimum libev watcher priority (int)")
set(EV_MAXPRI "2" CACHE STRING "Maximum libev watcher priority (int)")
set(EV_MULTIPLICITY ON CACHE BOOL "Build with support for multiple event loops")


target_compile_definitions(ev PUBLIC
    EV_MINPRI=${EV_MINPRI}
    EV_MAXPRI=${EV_MAXPRI})

## avoiding generator expressions here,
## which are non-trivial to translate
## to literal values when generating
## libev.pc

list(APPEND EV_BOOL_DEFS EV_MULTIPLICITY)


foreach(_name ${EV_BOOL_DEFS})
if(${${_name}})
    target_compile_definitions(ev PUBLIC -D${_name}=1)
else()
    target_compile_definitions(ev PUBLIC -D${_name}=0)
endif()
endforeach()


