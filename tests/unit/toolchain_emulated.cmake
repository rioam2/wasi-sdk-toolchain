include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

set(WASI_SDK_ROOT "${FIXTURE_SDK}")
set(WASI_SDK_EMULATED_FEATURES signal mman process-clocks getpid)
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")

# The define and the library name are derived from one feature name, so a typo
# in either half of the mapping shows up here.
foreach(pair IN ITEMS
    "signal|SIGNAL"
    "mman|MMAN"
    "process-clocks|PROCESS_CLOCKS"
    "getpid|GETPID")
  string(REPLACE "|" ";" parts "${pair}")
  list(GET parts 0 feature)
  list(GET parts 1 macro_suffix)

  foreach(lang IN ITEMS C CXX)
    expect_match("${CMAKE_${lang}_FLAGS_INIT}" "-D_WASI_EMULATED_${macro_suffix}"
      "${lang} defines _WASI_EMULATED_${macro_suffix}")
    expect_match("${CMAKE_${lang}_STANDARD_LIBRARIES}" "-lwasi-emulated-${feature}"
      "${lang} links wasi-emulated-${feature}")
  endforeach()
endforeach()

# Emulated libraries belong at the end of the link line, not in the flags.
expect_no_match("${CMAKE_C_FLAGS_INIT}" "-lwasi-emulated"
  "emulated libraries are standard libraries, not compile flags")

message(STATUS "emulated features OK")
