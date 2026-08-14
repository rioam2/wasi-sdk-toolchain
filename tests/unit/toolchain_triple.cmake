include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

set(WASI_SDK_ROOT "${FIXTURE_SDK}")
set(WASI_SDK_TARGET_TRIPLE "wasm32-wasip2")
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")

foreach(lang IN ITEMS C CXX ASM)
  expect_eq("${CMAKE_${lang}_COMPILER_TARGET}" "wasm32-wasip2" "${lang} honours the requested triple")
endforeach()

message(STATUS "custom triple OK")
