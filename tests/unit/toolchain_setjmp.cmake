include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

set(WASI_SDK_ROOT "${FIXTURE_SDK}")
set(WASI_SDK_SETJMP ON)
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")

foreach(lang IN ITEMS C CXX)
  expect_match("${CMAKE_${lang}_FLAGS_INIT}" "-mllvm -wasm-enable-sjlj"
    "${lang} enables the SJLJ lowering")
  expect_match("${CMAKE_${lang}_STANDARD_LIBRARIES}" "-lsetjmp"
    "${lang} links the setjmp runtime")
endforeach()

message(STATUS "setjmp support OK")
