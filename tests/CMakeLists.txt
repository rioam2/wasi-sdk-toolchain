cmake_minimum_required(VERSION 3.25)
project(wasi_sdk_toolchain_tests NONE)

# Deliberately not a top-level CMakeLists.txt for the repository: consumers pull
# this repo in with FetchContent, which would try to build whatever sits at the
# root. Configure this directory explicitly instead:
#
#   cmake -S tests -B build -G Ninja && ctest --test-dir build --output-on-failure

enable_testing()

# Every test here is a script, so no configuration exists to select. Under a
# multi-config generator ctest still gates them behind one and reports them as
# "Not available without configuration" unless -C is passed.
if(CMAKE_CONFIGURATION_TYPES)
  message(WARNING
    "multi-config generator (${CMAKE_GENERATOR}): ctest must be given "
    "'-C Debug', or configure with -G Ninja instead.")
endif()

get_filename_component(REPO_DIR "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
set(PURE_TOOLCHAIN "${REPO_DIR}/wasi-sdk.toolchain.cmake")
set(BOOTSTRAP_TOOLCHAIN "${REPO_DIR}/wasi-sdk-bootstrap.toolchain.cmake")

set(WASI_SDK_TESTS_VERSION "33" CACHE STRING
  "wasi-sdk release the integration tests build against")
option(WASI_SDK_TESTS_INTEGRATION
  "Run tests that download a real wasi-sdk and compile WebAssembly" ON)

# ---------------------------------------------------------------------------
# Unit tests: pure CMake logic, no network and no compiler.
# ---------------------------------------------------------------------------

function(add_unit_test name)
  add_test(NAME "unit.${name}"
    COMMAND "${CMAKE_COMMAND}" "-DREPO_DIR=${REPO_DIR}"
            -P "${CMAKE_CURRENT_LIST_DIR}/unit/${name}.cmake")
  set_tests_properties("unit.${name}" PROPERTIES LABELS unit)
endfunction()

# add_error_test(<name> EXPECT <regex>...) - every pattern must appear.
function(add_error_test name)
  cmake_parse_arguments(PARSE_ARGV 1 arg "" "" "EXPECT")
  string(REPLACE ";" "|" packed "${arg_EXPECT}")
  add_test(NAME "unit.${name}"
    COMMAND "${CMAKE_COMMAND}"
      "-DSCRIPT=${CMAKE_CURRENT_LIST_DIR}/unit/${name}.cmake"
      "-DREPO_DIR=${REPO_DIR}"
      "-DEXPECT=${packed}"
      -P "${CMAKE_CURRENT_LIST_DIR}/cmake/RunExpectFailure.cmake")
  set_tests_properties("unit.${name}" PROPERTIES LABELS unit)
endfunction()

foreach(name IN ITEMS
    host_id
    version_normalize
    checksums_table
    lookup_known
    cache_root
    toolchain_defaults
    toolchain_emulated
    toolchain_emulated_commas
    toolchain_exceptions
    toolchain_exceptions_ignore
    toolchain_exception_encoding
    toolchain_eh_flags_per_language
    toolchain_setjmp
    toolchain_triple
    toolchain_emulator
    toolchain_env_fallback
    toolchain_idempotent
    toolchain_trycompile_vars
    toolchain_purity
    platform_fallback)
  add_unit_test("${name}")
endforeach()

add_error_test(lookup_unknown
  EXPECT "no pinned checksum for version '999.0'" "update-checksums")
add_error_test(host_id_invalid
  EXPECT "unsupported host system 'Plan9'")
add_error_test(version_invalid
  EXPECT "invalid version 'latest'")
add_error_test(toolchain_missing_root
  EXPECT "WASI_SDK_ROOT is not set" "wasi-sdk-bootstrap")
add_error_test(toolchain_bad_root
  EXPECT "does not look like a wasi-sdk release")
add_error_test(toolchain_emulated_invalid
  EXPECT "unknown emulated feature 'nonsense'" "signal, mman, process-clocks, getpid")
add_error_test(toolchain_exceptions_invalid
  EXPECT "must be 'off', 'wasm' or 'ignore'")
add_error_test(toolchain_exception_encoding_invalid
  EXPECT "must be 'legacy' or 'standard'")
add_error_test(toolchain_triple_invalid
  EXPECT "is not provided by this SDK" "wasm32-wasip1, wasm32-wasip2")

# ---------------------------------------------------------------------------
# Integration tests: real SDK, real WebAssembly output.
# ---------------------------------------------------------------------------

if(NOT WASI_SDK_TESTS_INTEGRATION)
  message(STATUS "wasi-sdk tests: integration tests disabled")
  return()
endif()

# Acquired once here so the tests themselves stay offline and can run in
# parallel; this also exercises the acquisition module on every configure.
include("${REPO_DIR}/cmake/WasiSdkAcquire.cmake")
wasi_sdk_acquire(
  VERSION "${WASI_SDK_TESTS_VERSION}"
  OUTPUT_ROOT WASI_SDK_TEST_ROOT)
message(STATUS "wasi-sdk tests: using ${WASI_SDK_TEST_ROOT}")

find_program(WASMTIME_EXECUTABLE wasmtime)
if(WASMTIME_EXECUTABLE)
  message(STATUS "wasi-sdk tests: wasmtime found, build output will be executed")
else()
  message(STATUS "wasi-sdk tests: wasmtime not found, build-only coverage")
endif()

set(ALL_EMULATED "signal,mman,process-clocks,getpid")

# add_build_test(NAME <n> DIR <d> [TOOLCHAIN <f>] [EXPECT <file>...] [ARGS <-D...>...])
function(add_build_test)
  cmake_parse_arguments(PARSE_ARGV 0 arg "" "NAME;DIR;TOOLCHAIN" "EXPECT;ARGS;FORBID_OUTPUT")

  if(NOT DEFINED arg_TOOLCHAIN OR arg_TOOLCHAIN STREQUAL "")
    set(arg_TOOLCHAIN "${PURE_TOOLCHAIN}")
  endif()

  set(configure_args
    "-DCMAKE_TOOLCHAIN_FILE=${arg_TOOLCHAIN}"
    "-DWASI_SDK_ROOT=${WASI_SDK_TEST_ROOT}"
    "-DWASI_SDK_TOOLCHAIN_DIR=${REPO_DIR}"
    ${arg_ARGS})

  # '|' survives add_test's own list flattening; no argument contains one.
  string(REPLACE ";" "|" packed_args "${configure_args}")
  string(REPLACE ";" "|" packed_expect "${arg_EXPECT}")
  string(REPLACE ";" "|" packed_forbid "${arg_FORBID_OUTPUT}")

  add_test(NAME "integration.${arg_NAME}"
    COMMAND "${CMAKE_COMMAND}"
      "-DSRC=${CMAKE_CURRENT_LIST_DIR}/integration/${arg_DIR}"
      "-DBIN=${CMAKE_CURRENT_BINARY_DIR}/builds/${arg_NAME}"
      "-DCFG_ARGS=${packed_args}"
      "-DEXPECT_FILE=${packed_expect}"
      "-DFORBID_OUTPUT=${packed_forbid}"
      -P "${CMAKE_CURRENT_LIST_DIR}/cmake/RunBuild.cmake")
  set_tests_properties("integration.${arg_NAME}" PROPERTIES LABELS integration)
endfunction()

add_build_test(NAME smoke DIR smoke EXPECT smoke.wasm smoke_c.wasm)

add_build_test(NAME bootstrap DIR smoke
  TOOLCHAIN "${BOOTSTRAP_TOOLCHAIN}"
  ARGS "-DWASI_SDK_VERSION=${WASI_SDK_TESTS_VERSION}"
  EXPECT smoke.wasm)

add_build_test(NAME wasip2 DIR smoke
  ARGS "-DWASI_SDK_TARGET_TRIPLE=wasm32-wasip2"
  EXPECT smoke.wasm)

add_build_test(NAME emulated DIR emulated
  ARGS "-DWASI_SDK_EMULATED_FEATURES=${ALL_EMULATED}"
  EXPECT emulated.wasm)

add_build_test(NAME probe_parity DIR probe_parity
  ARGS "-DWASI_SDK_EMULATED_FEATURES=${ALL_EMULATED}"
  EXPECT probe_parity.wasm)

add_build_test(NAME exceptions DIR exceptions
  ARGS "-DWASI_SDK_EXCEPTIONS=wasm"
  EXPECT exceptions.wasm exceptions_c.wasm
  FORBID_OUTPUT "unused-command-line-argument")

add_build_test(NAME setjmp DIR setjmp
  ARGS "-DWASI_SDK_SETJMP=ON"
  EXPECT setjmp_test.wasm
  FORBID_OUTPUT "unused-command-line-argument")

add_build_test(NAME extras DIR extras
  ARGS "-DWASI_SDK_EMULATED_FEATURES=${ALL_EMULATED}" "-DWASI_SDK_EXCEPTIONS=ignore"
  EXPECT abort_exceptions_multi_tu.wasm reactor.wasm libc_stubs.wasm)

add_build_test(NAME reentrancy DIR reentrancy
  ARGS "-DWASI_SDK_EMULATED_FEATURES=getpid"
  EXPECT outer.wasm)

# Covers what a package manager does: unpack into a directory it owns, keeping
# the archive for reuse.
add_test(NAME "integration.acquire_destination"
  COMMAND "${CMAKE_COMMAND}"
    "-DREPO_DIR=${REPO_DIR}"
    "-DWORK_DIR=${CMAKE_CURRENT_BINARY_DIR}/acquire"
    "-DVERSION=${WASI_SDK_TESTS_VERSION}"
    -P "${CMAKE_CURRENT_LIST_DIR}/integration/acquire_destination.cmake")
set_tests_properties("integration.acquire_destination" PROPERTIES LABELS integration)

# ---------------------------------------------------------------------------
# Execution: only possible when a runtime is installed.
# ---------------------------------------------------------------------------

if(NOT WASMTIME_EXECUTABLE)
  return()
endif()

function(add_run_test name build expected_output)
  # SJLJ lowering and -fwasm-exceptions emit exception opcodes, which wasmtime
  # still gates behind a feature flag.
  add_test(NAME "integration.run_${name}"
    COMMAND "${WASMTIME_EXECUTABLE}" run -W exceptions=y
      "${CMAKE_CURRENT_BINARY_DIR}/builds/${build}")
  set_tests_properties("integration.run_${name}" PROPERTIES
    LABELS integration
    DEPENDS "integration.${name}"
    PASS_REGULAR_EXPRESSION "${expected_output}")
endfunction()

add_run_test(smoke smoke/smoke.wasm "wasi-sdk-toolchain")
add_run_test(exceptions exceptions/exceptions.wasm "caught: thrown")
add_run_test(setjmp setjmp/setjmp_test.wasm "longjmp delivered 42")
add_run_test(emulated emulated/emulated.wasm "pid=")
