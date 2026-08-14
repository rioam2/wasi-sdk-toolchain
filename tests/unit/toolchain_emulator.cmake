include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

set(WASI_SDK_ROOT "${FIXTURE_SDK}")
set(WASI_SDK_CROSSCOMPILING_EMULATOR "wasmtime;run;--dir=.")
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")

expect_eq("${CMAKE_CROSSCOMPILING_EMULATOR}" "wasmtime;run;--dir=."
  "the emulator command is forwarded verbatim")

message(STATUS "emulator forwarding OK")
