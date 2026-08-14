include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")
include("${REPO_DIR}/cmake/WasiSdkAcquire.cmake")

set(ENV{WASI_SDK_CACHE_DIR} "")
set(ENV{XDG_CACHE_HOME} "/tmp/xdg-cache")
wasi_sdk_cache_root(root)
if(NOT CMAKE_HOST_WIN32)
  expect_eq("${root}" "/tmp/xdg-cache/wasi-sdk" "XDG_CACHE_HOME is honoured")
endif()

set(ENV{WASI_SDK_CACHE_DIR} "/tmp/explicit-cache")
wasi_sdk_cache_root(root)
expect_eq("${root}" "/tmp/explicit-cache" "WASI_SDK_CACHE_DIR wins over XDG_CACHE_HOME")

set(WASI_SDK_CACHE_DIR "/tmp/variable-cache")
wasi_sdk_cache_root(root)
expect_eq("${root}" "/tmp/variable-cache" "the CMake variable wins over the environment")

message(STATUS "cache root precedence OK")
