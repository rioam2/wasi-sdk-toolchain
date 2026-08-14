include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

set(WASI_SDK_ROOT "${FIXTURE_SDK}")
set(WASI_SDK_EXCEPTIONS ignore)
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")

expect_match("${CMAKE_CXX_FLAGS_INIT}" "-fignore-exceptions" "try/catch keeps compiling")
expect_no_match("${CMAKE_CXX_FLAGS_INIT}" "-fno-exceptions" "the default is replaced, not added to")
# This mode deliberately leaves the exception ABI undefined; wasi::abort-exceptions
# supplies it, so the toolchain must not quietly link an unwinder instead.
expect_no_match("${CMAKE_CXX_STANDARD_LIBRARIES}" "-lunwind" "no unwinder in ignore mode")

message(STATUS "ignore-exceptions mode OK")
