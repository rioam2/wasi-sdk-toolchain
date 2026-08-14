include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

# CMake ships Platform/WASI*.cmake from 3.31 onwards, but the toolchain still
# supports 3.25, so the vendored copies must stay in place and keep matching
# what CMake provides.
foreach(module IN ITEMS WASI WASI-Initialize)
  if(NOT EXISTS "${REPO_DIR}/Platform/${module}.cmake")
    message(FATAL_ERROR "assertion failed: missing vendored Platform/${module}.cmake")
  endif()
endforeach()

# Other consumers branch on if(WASI), which comes from the -Initialize
# module because it has to run before compiler detection.
file(READ "${REPO_DIR}/Platform/WASI-Initialize.cmake" initialize)
expect_match("${initialize}" "set\\(WASI 1\\)" "WASI-Initialize must define the platform variable")

file(READ "${REPO_DIR}/wasi-sdk.toolchain.cmake" toolchain)
expect_match("${toolchain}" "VERSION_LESS 3\\.31"
  "the vendored modules must only be used for CMake older than 3.31")

message(STATUS "platform module fallback OK")
