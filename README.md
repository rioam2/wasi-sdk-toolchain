# wasi-sdk-toolchain

A batteries-included CMake toolchain for cross-compiling C/C++ code to wasm32-wasi (WebAssembly/WASI). 
Built on top of releases from https://github.com/WebAssembly/wasi-sdk

## Getting started

Add the following cmake file somewhere in your project. For this example, it is named `wasi-sdk.toolchain.cmake` in a `cmake/wasi-sdk` directory.

```cmake
include(FetchContent)

# Fetch the WASI toolchain from Github
set(FETCHCONTENT_FULLY_DISCONNECTED_OLD ${FETCHCONTENT_FULLY_DISCONNECTED})
set(FETCHCONTENT_FULLY_DISCONNECTED OFF)
FetchContent_Declare(
  wasi_sdk_toolchain
  SOURCE_DIR "${CMAKE_BINARY_DIR}/_deps/wasi-sdk"
  GIT_REPOSITORY https://github.com/rioam2/wasi-sdk-toolchain.git
  GIT_TAG scratch/make-init-generic
)
FetchContent_MakeAvailable(wasi_sdk_toolchain)
set(FETCHCONTENT_FULLY_DISCONNECTED ${FETCHCONTENT_FULLY_DISCONNECTED_OLD})

# Source toolchain file(s)
include("${wasi_sdk_toolchain_SOURCE_DIR}/wasi-sdk.toolchain.cmake")

# Initialize a specific version of the WASI toolchain
# These are example versions, set them as needed for your project
initialize_wasi_toolchain(
  WIT_BINDGEN_TAG "v0.29.0"
  WASMTIME_TAG "v23.0.1"
  WASM_TOOLS_TAG "v1.215.0"
  WASI_SDK_TAG "wasi-sdk-23"
  TARGET_TRIPLET "wasm32-wasip1-threads"
)
```

`FETCHCONTENT_FULLY_DISCONNECTED` is forced to off to ensure that the toolchain is always fetched and loaded, regardless of your project's configuration. It is set back to it's original value after the toolchain is loaded.

The tag in this example is set to `wasi-sdk-23`. This is configurable and can be set to any tag within this repository.

Finally, set this CMake cache variable:

`cmake ... -DCMAKE_TOOLCHAIN_FILE=path/to/wasi-sdk.toolchain.cmake`

## Using wit-bindgen to create a component

The toolchain provides a helper function to generate WebAssembly Interface Type bindings (WIT-bindings) using wit-bindgen

```cmake
wit_bindgen(
    INTERFACE_FILE_INPUT "${CMAKE_CURRENT_SOURCE_DIR}/module.wit"
    BINDINGS_DIR_INPUT "${CMAKE_CURRENT_SOURCE_DIR}/bindings"
    GENERATED_FILES_OUTPUT wit_codegen_output_files
)

# ...

add_executable(<target> ${wit_codegen_output_files} ...)

# Create a WebAssembly Component
wasm_create_component(
    COMPONENT_TARGET <name_of_wasm_component_target>
    CORE_WASM_TARGET <target>
    COMPONENT_TYPE "reactor"
)
```

This generates WIT bindings for the `.wit` file provided by `INTERFACE_FILE_INPUT`. The resulting bindings will be placed in the `BINDINGS_DIR_INPUT` directory. Additionally, a list of the generated files will be placed in a list variable given by `GENERATED_FILES_OUTPUT`. This list can be provided to a later call to `add_executable` as sources/headers to link with your executable.