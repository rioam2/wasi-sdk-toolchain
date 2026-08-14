include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

set(WASI_SDK_ROOT "${FIXTURE_SDK}")
# Semicolon lists are awkward to pass through -D on a command line, so commas
# have to work too.
set(WASI_SDK_EMULATED_FEATURES "signal,mman,process-clocks,getpid")
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")

foreach(macro_suffix IN ITEMS SIGNAL MMAN PROCESS_CLOCKS GETPID)
  expect_match("${CMAKE_C_FLAGS_INIT}" "-D_WASI_EMULATED_${macro_suffix}"
    "comma-separated features define _WASI_EMULATED_${macro_suffix}")
endforeach()

foreach(feature IN ITEMS signal mman process-clocks getpid)
  expect_match("${CMAKE_C_STANDARD_LIBRARIES}" "-lwasi-emulated-${feature}"
    "comma-separated features link wasi-emulated-${feature}")
endforeach()

message(STATUS "comma-separated features OK")
