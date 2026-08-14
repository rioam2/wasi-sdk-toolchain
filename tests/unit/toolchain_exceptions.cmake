include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

set(WASI_SDK_ROOT "${FIXTURE_SDK}")
set(WASI_SDK_EXCEPTIONS wasm)
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")

expect_match("${CMAKE_CXX_FLAGS_INIT}" "-fwasm-exceptions" "C++ gets wasm exceptions")
expect_no_match("${CMAKE_CXX_FLAGS_INIT}" "-fno-exceptions" "the default is replaced, not added to")
# The "eh" multilib's libc++abi needs the unwinder, which nothing else links.
expect_match("${CMAKE_CXX_STANDARD_LIBRARIES}" "-lunwind" "wasm exceptions link libunwind")
# C has no exceptions; passing the flag there only produces warnings.
expect_no_match("${CMAKE_C_FLAGS_INIT}" "-fwasm-exceptions" "C is left alone")

message(STATUS "wasm exceptions OK")
