include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

set(WASI_SDK_ROOT "${FIXTURE_SDK}")
set(WASI_SDK_EMULATED_FEATURES signal nonsense)
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")

message(FATAL_ERROR "expected an unknown emulated feature to be rejected")
