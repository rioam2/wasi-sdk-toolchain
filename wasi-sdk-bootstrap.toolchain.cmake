# Convenience toolchain: downloads a pinned wasi-sdk, then configures CMake to
# use it. Equivalent to running cmake/WasiSdkAcquire.cmake yourself and passing
# the result as WASI_SDK_ROOT to wasi-sdk.toolchain.cmake.
#
#   cmake -DCMAKE_TOOLCHAIN_FILE=.../wasi-sdk-bootstrap.toolchain.cmake \
#         -DWASI_SDK_VERSION=33 ...
#
# Prefer wasi-sdk.toolchain.cmake when something else already manages the SDK
# (a package manager, a container image, a CI cache): configure-time downloads
# make builds depend on network availability.

if(NOT DEFINED WASI_SDK_ROOT OR WASI_SDK_ROOT STREQUAL "")
  if(NOT DEFINED WASI_SDK_VERSION OR WASI_SDK_VERSION STREQUAL "")
    message(FATAL_ERROR
      "wasi-sdk: WASI_SDK_VERSION is required by the bootstrap toolchain.\n"
      "  Pass -DWASI_SDK_VERSION=<release>, for example 33.")
  endif()

  include("${CMAKE_CURRENT_LIST_DIR}/cmake/WasiSdkAcquire.cmake")
  wasi_sdk_acquire(
    VERSION "${WASI_SDK_VERSION}"
    DESTINATION "${WASI_SDK_CACHE_DESTINATION}"
    SHA256 "${WASI_SDK_SHA256}"
    OUTPUT_ROOT WASI_SDK_ROOT)
endif()

# WASI_SDK_ROOT is forwarded into try_compile by the toolchain below, so nested
# configures reuse the download rather than repeating this block.
include("${CMAKE_CURRENT_LIST_DIR}/wasi-sdk.toolchain.cmake")

list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES WASI_SDK_VERSION)
list(REMOVE_DUPLICATES CMAKE_TRY_COMPILE_PLATFORM_VARIABLES)
