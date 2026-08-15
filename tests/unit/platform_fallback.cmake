include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

# CMake only ships Platform/WASI*.cmake from 3.31 onwards, and its copy leaves
# CMAKE_EXECUTABLE_SUFFIX empty, so the vendored modules must stay in place and
# take precedence on every supported version.
foreach(module IN ITEMS WASI WASI-Initialize)
  if(NOT EXISTS "${REPO_DIR}/Platform/${module}.cmake")
    message(FATAL_ERROR "assertion failed: missing vendored Platform/${module}.cmake")
  endif()
endforeach()

# Other consumers branch on if(WASI), which comes from the -Initialize
# module because it has to run before compiler detection.
file(READ "${REPO_DIR}/Platform/WASI-Initialize.cmake" initialize)
expect_match("${initialize}" "set\\(WASI 1\\)" "WASI-Initialize must define the platform variable")

file(READ "${REPO_DIR}/Platform/WASI.cmake" platform)
expect_match("${platform}" "set\\(CMAKE_EXECUTABLE_SUFFIX \"\\.wasm\"\\)"
  "Platform/WASI.cmake must re-apply the executable suffix")

file(READ "${REPO_DIR}/wasi-sdk.toolchain.cmake" toolchain)
expect_no_match("${toolchain}" "VERSION_LESS 3\\.31"
  "the vendored modules must not be gated on the CMake version")

message(STATUS "platform module fallback OK")
