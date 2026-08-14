include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

# Every input that changes the compile or link command must be forwarded into
# try_compile, otherwise compiler probes and check_<lang>_source_compiles() see
# a different toolchain than the real build.
set(WASI_SDK_ROOT "${FIXTURE_SDK}")
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")

foreach(input IN ITEMS
    WASI_SDK_ROOT
    WASI_SDK_TARGET_TRIPLE
    WASI_SDK_EMULATED_FEATURES
    WASI_SDK_EXCEPTIONS
    WASI_SDK_EXCEPTION_ENCODING
    WASI_SDK_SETJMP
    WASI_SDK_CXX_STDLIB
    WASI_SDK_CROSSCOMPILING_EMULATOR)
  if(NOT input IN_LIST CMAKE_TRY_COMPILE_PLATFORM_VARIABLES)
    message(FATAL_ERROR
      "assertion failed: ${input} is not forwarded to try_compile\n"
      "  CMAKE_TRY_COMPILE_PLATFORM_VARIABLES=${CMAKE_TRY_COMPILE_PLATFORM_VARIABLES}")
  endif()
endforeach()

message(STATUS "try_compile forwarding OK")
