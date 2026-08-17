include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

# Reading the toolchain must be enough to make the extras helper callable, so
# consumers never have to construct a path to cmake/WasiSdkExtras.cmake.
set(WASI_SDK_ROOT "${FIXTURE_SDK}")
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")

if(NOT COMMAND wasi_sdk_add_extras)
  message(FATAL_ERROR "assertion failed: the toolchain did not define wasi_sdk_add_extras()")
endif()

# The toolchain is re-read for every project() and try_compile, so the include
# must not be swallowed by a guard that the first read set.
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")
if(NOT COMMAND wasi_sdk_add_extras)
  message(FATAL_ERROR "assertion failed: wasi_sdk_add_extras() was lost on a second read")
endif()

if(NOT EXISTS "${REPO_DIR}/extras/CMakeLists.txt")
  message(FATAL_ERROR "assertion failed: no extras sources where the default path points")
endif()

message(STATUS "toolchain provides wasi_sdk_add_extras OK")
