cmake_minimum_required(VERSION 3.25)
project(wasi_probe_parity LANGUAGES C)

include(CheckCSourceCompiles)

# The feature defines must reach compiler probes, not just the real build.
check_c_source_compiles([[
#ifndef _WASI_EMULATED_GETPID
#error emulated feature defines did not reach the probe
#endif
int main(void) { return 0; }
]] PROBE_SEES_DEFINES)

if(NOT PROBE_SEES_DEFINES)
  message(FATAL_ERROR "try_compile did not inherit the emulated feature defines")
endif()

# Probes link too, so the emulated libraries must be present as standard
# libraries rather than as directory-scoped link options.
check_c_source_compiles([[
#include <unistd.h>
int main(void) { return getpid() > 0 ? 0 : 1; }
]] PROBE_LINKS_EMULATED)

if(NOT PROBE_LINKS_EMULATED)
  message(FATAL_ERROR "try_compile could not link against the emulated libraries")
endif()

add_executable(probe_parity main.c)
