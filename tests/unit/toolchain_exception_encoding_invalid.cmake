include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

set(WASI_SDK_ROOT "${FIXTURE_SDK}")
set(WASI_SDK_EXCEPTION_ENCODING modern)
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")

message(FATAL_ERROR "expected an invalid exception encoding to be rejected")
