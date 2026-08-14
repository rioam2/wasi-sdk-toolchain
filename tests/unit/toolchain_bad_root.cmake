include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

set(WASI_SDK_ROOT "${REPO_DIR}/tests/fixtures")
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")

message(FATAL_ERROR "expected a directory without a compiler to be rejected")
