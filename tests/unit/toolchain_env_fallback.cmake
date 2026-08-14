include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

# Matches the variable wasi-sdk's own documentation tells users to export.
set(ENV{WASI_SDK_PATH} "${FIXTURE_SDK}")
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")

expect_eq("${WASI_SDK_ROOT}" "${FIXTURE_SDK}" "WASI_SDK_PATH is used as a fallback")
expect_eq("${CMAKE_SYSROOT}" "${FIXTURE_SDK}/share/wasi-sysroot" "sysroot follows the env root")

message(STATUS "WASI_SDK_PATH fallback OK")
