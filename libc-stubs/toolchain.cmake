# Source toolchain file(s)
include("$ENV{WASI_SDK_TOOLCHAIN_FILE}")

# Initialize a specific version of the WASI toolchain
initialize_wasi_toolchain(
  WIT_BINDGEN_TAG "v0.50.0"
  WASMTIME_TAG "v40.0.0"
  WASM_TOOLS_TAG "v1.244.0"
  WASI_SDK_TAG "wasi-sdk-29"
  TARGET_TRIPLET "wasm32-wasip1"
)
