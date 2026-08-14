include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

# The encoding flag is only valid for a language that also emits exception
# opcodes. -fwasm-exceptions is C++ only, so applying the flag to C makes the
# backend abort with "-exception-model=wasm only allowed with ...".
set(WASI_SDK_ROOT "${FIXTURE_SDK}")
set(WASI_SDK_EXCEPTIONS wasm)
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")

expect_match("${CMAKE_CXX_FLAGS_INIT}" "-wasm-use-legacy-eh=false" "C++ requests the encoding")
expect_no_match("${CMAKE_C_FLAGS_INIT}" "wasm-use-legacy-eh" "C emits no exception opcodes")
expect_no_match("${CMAKE_C_FLAGS_INIT}" "start-no-unused-arguments"
  "no empty wrapper is added to C")

# setjmp does apply to both languages, so there the flag belongs on each.
unset(_WASI_SDK_FLAGS_APPLIED)
set(CMAKE_C_FLAGS_INIT "")
set(CMAKE_CXX_FLAGS_INIT "")
set(WASI_SDK_EXCEPTIONS off)
set(WASI_SDK_SETJMP ON)
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")

foreach(lang IN ITEMS C CXX)
  expect_match("${CMAKE_${lang}_FLAGS_INIT}" "-wasm-use-legacy-eh=false"
    "${lang} uses setjmp and so needs the encoding")
endforeach()

message(STATUS "per-language exception opcode flags OK")
