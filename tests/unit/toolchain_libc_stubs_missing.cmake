include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

set(WASI_SDK_ROOT "${FIXTURE_SDK}")
set(WASI_SDK_LIBC_STUBS ON)
set(WASI_SDK_LIBC_STUBS_DIR "${REPO_DIR}/tests/fixtures")
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")

message(FATAL_ERROR "expected a stubs directory without headers to be rejected")
