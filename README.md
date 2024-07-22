# wasi-sdk-toolchain

A batteries-included CMake toolchain for cross-compiling C/C++ code to wasm32-wasi (WebAssembly/WASI). 
Built on top of releases from https://github.com/WebAssembly/wasi-sdk

## Getting started

### Method 1: Using FetchContent to load the toolchain from Github

Add the following cmake file somewhere in your project. For this example, it is named `wasi-sdk.toolchain.cmake` in a `cmake/wasi-sdk` directory.

```cmake
include(FetchContent)

set(FETCHCONTENT_FULLY_DISCONNECTED_OLD ${FETCHCONTENT_FULLY_DISCONNECTED})
set(FETCHCONTENT_FULLY_DISCONNECTED OFF)
FetchContent_Declare(
  wasi_sdk_toolchain
  SOURCE_DIR "${CMAKE_BINARY_DIR}/_deps/wasi-sdk"
  GIT_REPOSITORY https://github.com/rioam2/wasi-sdk-toolchain.git
  GIT_TAG wasi-sdk-21
)
FetchContent_MakeAvailable(wasi_sdk_toolchain)
set(FETCHCONTENT_FULLY_DISCONNECTED ${FETCHCONTENT_FULLY_DISCONNECTED_OLD})

include("${wasi_sdk_toolchain_SOURCE_DIR}/wasi-sdk.toolchain.cmake")
```

`FETCHCONTENT_FULLY_DISCONNECTED` is forced to off to ensure that the toolchain is always fetched and loaded, regardless of your project's configuration. It is set back to it's original value after the toolchain is loaded.

The tag in this example is set to `wasi-sdk-21`. This is configurable and can be set to any tag within this repository.

Finally, set this CMake cache variable:

`cmake ... -DCMAKE_TOOLCHAIN_FILE=path/to/wasi-sdk.toolchain.cmake`


### Method 2: Cloning the toolchain directly

Clone this repo directly into a directory of your choosing, then set `CMAKE_TOOLCHAIN_FILE` to point to `wasi-sdk.toolchain.cmake`.