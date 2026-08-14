include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

set(WASI_SDK_ROOT "${FIXTURE_SDK}")
# A triple the SDK does not ship must be reported during configure, with the
# available alternatives, rather than failing much later at link time.
set(WASI_SDK_TARGET_TRIPLE "wasm32-unknown")
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")

message(FATAL_ERROR "expected an unsupported triple to be rejected")
