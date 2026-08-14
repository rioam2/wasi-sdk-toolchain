include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

set(ENV{WASI_SDK_PATH} "")
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")

message(FATAL_ERROR "expected a missing WASI_SDK_ROOT to be reported")
