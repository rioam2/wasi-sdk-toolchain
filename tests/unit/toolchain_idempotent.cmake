include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

# A toolchain file is read again for every project() call. The previous
# implementation appended to CMAKE_<LANG>_FLAGS on each read, which duplicated
# every flag; this pins the fix.
set(WASI_SDK_ROOT "${FIXTURE_SDK}")
set(WASI_SDK_EMULATED_FEATURES signal)
set(WASI_SDK_SETJMP ON)

include("${REPO_DIR}/wasi-sdk.toolchain.cmake")
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")

expect_count_eq("${CMAKE_CXX_FLAGS_INIT}" "-stdlib=libc\\+\\+" 1 "stdlib flag")
expect_count_eq("${CMAKE_C_FLAGS_INIT}" "-D_WASI_EMULATED_SIGNAL" 1 "emulated define")
expect_count_eq("${CMAKE_C_FLAGS_INIT}" "-wasm-enable-sjlj" 1 "sjlj flag")
expect_count_eq("${CMAKE_C_STANDARD_LIBRARIES}" "-lwasi-emulated-signal" 1 "emulated library")
expect_count_eq("${CMAKE_CXX_STANDARD_LIBRARIES}" "-lsetjmp" 1 "setjmp library")

expect_count_eq("${CMAKE_TRY_COMPILE_PLATFORM_VARIABLES}" "WASI_SDK_ROOT" 1
  "try_compile variable list")

message(STATUS "re-reading the toolchain is idempotent")
