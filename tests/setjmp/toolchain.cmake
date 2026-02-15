# Source toolchain file(s)
include("$ENV{WASI_SDK_TOOLCHAIN_FILE}")

# Initialize a specific version of the WASI toolchain
initialize_wasi_toolchain(
  WIT_BINDGEN_TAG "v0.42.1"
  WASMTIME_TAG "v33.0.0"
  WASM_TOOLS_TAG "v1.234.0"
  WASI_SDK_TAG "wasi-sdk-29"
  TARGET_TRIPLET "wasm32-wasi"
  ENABLE_EXPERIMENTAL_SETJMP ON
)
