include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

# Standard is the default: runtimes have dropped the legacy encoding.
set(WASI_SDK_ROOT "${FIXTURE_SDK}")
set(WASI_SDK_EXCEPTIONS wasm)
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")
expect_match("${CMAKE_CXX_FLAGS_INIT}" "-wasm-use-legacy-eh=false"
  "standard encoding by default")

# A fresh scope, since the toolchain only contributes flags once per read.
unset(_WASI_SDK_FLAGS_APPLIED)
set(CMAKE_CXX_FLAGS_INIT "")
set(CMAKE_C_FLAGS_INIT "")
set(WASI_SDK_EXCEPTION_ENCODING legacy)
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")
expect_no_match("${CMAKE_CXX_FLAGS_INIT}" "wasm-use-legacy-eh"
  "legacy relies on the compiler default")

# The encoding is meaningless without exception opcodes, so it must not leak
# into builds that enabled neither exceptions nor setjmp.
unset(_WASI_SDK_FLAGS_APPLIED)
set(CMAKE_CXX_FLAGS_INIT "")
set(CMAKE_C_FLAGS_INIT "")
set(WASI_SDK_EXCEPTION_ENCODING standard)
set(WASI_SDK_EXCEPTIONS off)
set(WASI_SDK_SETJMP OFF)
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")
expect_no_match("${CMAKE_CXX_FLAGS_INIT}" "wasm-use-legacy-eh"
  "no encoding flag without exception opcodes")

message(STATUS "exception encoding OK")
