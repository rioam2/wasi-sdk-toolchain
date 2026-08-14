#include <wasi_reactor_module>

// Exported so a host can initialise globals/statics before calling any other
// export. Defined once here rather than force-included, which would emit a
// duplicate definition in every translation unit of the consuming target.
extern "C" __attribute__((export_name("_start"))) void _start() {
  __wasm_call_ctors();
}
