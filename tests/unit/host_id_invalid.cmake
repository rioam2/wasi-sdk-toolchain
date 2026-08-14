include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")
include("${REPO_DIR}/cmake/WasiSdkHost.cmake")

wasi_sdk_host_id(id SYSTEM "Plan9" PROCESSOR "x86_64")

message(FATAL_ERROR "expected an unsupported host system to be rejected")
