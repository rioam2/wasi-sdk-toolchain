# wasi-sdk-toolchain

A CMake toolchain for cross-compiling C/C++ to `wasm32-wasi*`, built on releases
from [WebAssembly/wasi-sdk](https://github.com/WebAssembly/wasi-sdk).

It is split into three pieces so a project can take only what it needs:

| File | Purpose |
| --- | --- |
| `wasi-sdk.toolchain.cmake` | Describes the toolchain. No downloads, no targets, no directory state. |
| `wasi-sdk-bootstrap.toolchain.cmake` | The above, plus downloading a pinned SDK first. |
| `cmake/WasiSdkExtras.cmake` | Opt-in helper targets for reactor modules, exception stubs and libc stubs. |

## Getting started

### With an SDK you already have

```sh
cmake -B build \
  -DCMAKE_TOOLCHAIN_FILE=/path/to/wasi-sdk.toolchain.cmake \
  -DWASI_SDK_ROOT=/path/to/wasi-sdk-33.0-x86_64-linux
```

`WASI_SDK_ROOT` may also come from the `WASI_SDK_PATH` environment variable.

### Letting the toolchain download one

```sh
cmake -B build \
  -DCMAKE_TOOLCHAIN_FILE=/path/to/wasi-sdk-bootstrap.toolchain.cmake \
  -DWASI_SDK_VERSION=33
```

The archive is verified against a checksum pinned in
`cmake/WasiSdkChecksums.cmake` and unpacked into a shared cache
(`$XDG_CACHE_HOME/wasi-sdk`, `~/.cache/wasi-sdk`, or `%LOCALAPPDATA%\wasi-sdk`;
override with `WASI_SDK_CACHE_DIR`). Subsequent configures reuse it.

Prefer the non-bootstrap toolchain when something else already manages the SDK,
such as a package manager or a container image: a configure step that reaches
the network cannot run offline or hermetically.

To pre-populate the cache without configuring a project:

```sh
cmake -DVERSION=33 -P cmake/WasiSdkAcquire.cmake
```

### Vendoring the repository

```cmake
include(FetchContent)
FetchContent_Declare(wasi_sdk_toolchain
  GIT_REPOSITORY https://github.com/rioam2/wasi-sdk-toolchain.git
  GIT_TAG <commit>)
FetchContent_MakeAvailable(wasi_sdk_toolchain)
```

There is no `CMakeLists.txt` at the repository root, so this populates the
sources without adding anything to your build.

## Options

All options are plain CMake variables, settable with `-D` or by a wrapper
toolchain that includes this one. Each is forwarded into `try_compile`, so
compiler probes and `check_<lang>_source_compiles()` see the same flags as the
real build.

| Variable | Default | Meaning |
| --- | --- | --- |
| `WASI_SDK_ROOT` | *(required)* | Extracted wasi-sdk release. |
| `WASI_SDK_TARGET_TRIPLE` | `wasm32-wasip1` | Any triple the SDK's sysroot provides. |
| `WASI_SDK_EMULATED_FEATURES` | *(none)* | Any of `signal`, `mman`, `process-clocks`, `getpid`. Comma or semicolon separated. |
| `WASI_SDK_EXCEPTIONS` | `off` | `off`, `wasm`, or `ignore`. |
| `WASI_SDK_EXCEPTION_ENCODING` | `standard` | `standard` or `legacy`. Only applies when exception opcodes are emitted. |
| `WASI_SDK_SETJMP` | `OFF` | Enable `setjmp`/`longjmp` via the SJLJ lowering. |
| `WASI_SDK_CXX_STDLIB` | `libc++` | Passed to `-stdlib=`; `default` leaves it to the compiler. |
| `WASI_SDK_CROSSCOMPILING_EMULATOR` | *(none)* | Sets `CMAKE_CROSSCOMPILING_EMULATOR` so `ctest` can run the output. |

### Exceptions

`WASI_SDK_EXCEPTIONS` has to be explicit because clang selects the sysroot's
include *and* library directories from it:

- `off` uses `-fno-exceptions` and the `noeh` multilib. `throw` and `try` become
  compile errors. This is the wasi-sdk default configuration.
- `wasm` uses `-fwasm-exceptions` and the `eh` multilib, and links `libunwind`.
  Exceptions work.
- `ignore` uses `-fignore-exceptions`, which keeps `try`/`catch` compiling for
  unported code but leaves the exception ABI undefined. Link
  `wasi::abort-exceptions` from the extras to supply symbols that abort.

Building without any of these leaves libc++ emitting calls into an exception ABI
that the selected multilib does not provide, which fails at link time.

`WASI_SDK_EXCEPTION_ENCODING` exists because clang still defaults to the legacy
exception opcode encoding, while runtimes have moved on — wasmtime removed
`--wasm legacy-exceptions` in version 47. Run such modules with
`wasmtime run -W exceptions=y`.

### What this toolchain does not set

Optimisation levels, LTO, `--gc-sections`, initial memory and stack size are
project policy rather than properties of the target, so they are left to the
consuming project. For a release build you probably want something like:

```cmake
add_compile_options($<$<CONFIG:Release>:-O3>)
add_link_options($<$<CONFIG:Release>:-Wl,--gc-sections,--strip-debug>)
```

## Extras

```cmake
include(<toolchain-dir>/cmake/WasiSdkExtras.cmake)
wasi_sdk_add_extras()

target_link_libraries(my_module PRIVATE wasi::reactor)
```

| Target | Purpose |
| --- | --- |
| `wasi::reactor` | Reactor-style module: exports `_start`/`__wasm_call_ctors` and adds `-nostartfiles -Wl,--no-entry`. |
| `wasi::abort-exceptions` | Defines `__cxa_throw`/`__cxa_allocate_exception` so they abort. For `WASI_SDK_EXCEPTIONS=ignore`. |
| `wasi::libc-stubs` | Declarations and stub definitions for libc functionality wasi-libc lacks. |

These are libraries rather than force-included headers so their definitions
appear once per target instead of once per translation unit, and they are not
declared by the toolchain so they can be exported and do not reappear in nested
`project()` calls.

`wasi::libc-stubs` headers shadow real wasi-libc ones, so they reach only the
targets that link it. Everything it declares fails at runtime; see
`extras/libc-stubs/README.md`.

## Updating the pinned SDK list

```sh
GITHUB_TOKEN=$(gh auth token) cmake -P tools/update-checksums.cmake
```

This regenerates `cmake/WasiSdkChecksums.cmake` from the digests GitHub
publishes for each release asset. Releases before wasi-sdk-26 have no digests
and are skipped; pass `WASI_SDK_SHA256` to use one anyway.

## Tests

```sh
cmake -S tests -B build
ctest --test-dir build --output-on-failure
```

`ctest -L unit` covers the CMake logic without a network or a compiler.
`ctest -L integration` downloads the SDK and compiles real WebAssembly, and also
executes it when `wasmtime` is on `PATH`. Pass
`-DWASI_SDK_TESTS_INTEGRATION=OFF` to skip the latter, or
`-DWASI_SDK_TESTS_VERSION=<n>` to target a different release.
