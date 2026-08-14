include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

# The stub headers shadow real wasi-libc ones, so they must never appear unless
# asked for.
set(WASI_SDK_ROOT "${FIXTURE_SDK}")
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")
expect_no_match("${CMAKE_C_STANDARD_INCLUDE_DIRECTORIES}" "libc-stubs"
  "stub headers are off by default")

unset(_WASI_SDK_FLAGS_APPLIED)
set(WASI_SDK_LIBC_STUBS ON)
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")

foreach(lang IN ITEMS C CXX)
  expect_match("${CMAKE_${lang}_STANDARD_INCLUDE_DIRECTORIES}" "libc-stubs/include"
    "${lang} gets the stub headers when asked")
endforeach()

# Re-reading must not accumulate the directory.
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")
list(LENGTH CMAKE_C_STANDARD_INCLUDE_DIRECTORIES count)
expect_eq("${count}" "1" "stub include directory added once")

message(STATUS "libc stub headers OK")
