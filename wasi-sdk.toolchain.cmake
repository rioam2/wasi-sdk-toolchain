# CMake toolchain for cross-compiling to wasm32-wasi* with a wasi-sdk release.
#
# This file only describes the toolchain. It downloads nothing, declares no
# build targets and mutates no directory state, so it stays correct when CMake
# re-reads it (every project() call, every try_compile). Everything with a side
# effect lives in cmake/WasiSdkAcquire.cmake or cmake/WasiSdkExtras.cmake.
#
# Required input:
#   WASI_SDK_ROOT                     Extracted wasi-sdk release. Falls back to
#                                     the WASI_SDK_PATH environment variable.
#
# Optional inputs:
#   WASI_SDK_TARGET_TRIPLE            Default "wasm32-wasip1".
#   WASI_SDK_EMULATED_FEATURES        Any of: signal, mman, process-clocks,
#                                     getpid. Empty by default.
#   WASI_SDK_EXCEPTIONS               "off" (default, -fno-exceptions), "wasm"
#                                     (-fwasm-exceptions) or "ignore"
#                                     (-fignore-exceptions, needs the
#                                     wasi::abort-exceptions extra to link).
#   WASI_SDK_SETJMP                   Boolean, off by default.
#   WASI_SDK_EXCEPTION_ENCODING       "standard" (default) or "legacy"; only
#                                     applies when exceptions or setjmp are on.
#   WASI_SDK_CXX_STDLIB               Default "libc++"; "default" leaves the
#                                     compiler default alone.
#   WASI_SDK_CROSSCOMPILING_EMULATOR  Command used to run test executables.
#
# Optimisation levels, LTO and memory layout are deliberately not set here;
# see README.md for why those belong to the consuming project.

if(CMAKE_VERSION VERSION_LESS 3.25)
  message(FATAL_ERROR "wasi-sdk: this toolchain requires CMake 3.25 or newer")
endif()

# ---------------------------------------------------------------------------
# SDK location
# ---------------------------------------------------------------------------

if(NOT DEFINED WASI_SDK_ROOT OR WASI_SDK_ROOT STREQUAL "")
  if(DEFINED ENV{WASI_SDK_PATH} AND NOT "$ENV{WASI_SDK_PATH}" STREQUAL "")
    set(WASI_SDK_ROOT "$ENV{WASI_SDK_PATH}")
  endif()
endif()

if(NOT DEFINED WASI_SDK_ROOT OR WASI_SDK_ROOT STREQUAL "")
  message(FATAL_ERROR
    "wasi-sdk: WASI_SDK_ROOT is not set.\n"
    "  Point it at an extracted wasi-sdk release, export WASI_SDK_PATH, or use\n"
    "  wasi-sdk-bootstrap.toolchain.cmake to download one automatically.")
endif()

file(TO_CMAKE_PATH "${WASI_SDK_ROOT}" WASI_SDK_ROOT)

if(CMAKE_HOST_WIN32)
  set(_wasi_host_exe ".exe")
else()
  set(_wasi_host_exe "")
endif()

set(WASI_SDK_BIN "${WASI_SDK_ROOT}/bin")
set(CMAKE_SYSROOT "${WASI_SDK_ROOT}/share/wasi-sysroot")

if(NOT EXISTS "${WASI_SDK_BIN}/clang${_wasi_host_exe}")
  message(FATAL_ERROR
    "wasi-sdk: '${WASI_SDK_ROOT}' does not look like a wasi-sdk release.\n"
    "  Expected to find ${WASI_SDK_BIN}/clang${_wasi_host_exe}")
endif()
if(NOT IS_DIRECTORY "${CMAKE_SYSROOT}")
  message(FATAL_ERROR
    "wasi-sdk: missing sysroot at ${CMAKE_SYSROOT}\n"
    "  The wasi-sdk release at '${WASI_SDK_ROOT}' looks incomplete.")
endif()

# ---------------------------------------------------------------------------
# Target selection
# ---------------------------------------------------------------------------

if(NOT DEFINED WASI_SDK_TARGET_TRIPLE OR WASI_SDK_TARGET_TRIPLE STREQUAL "")
  set(WASI_SDK_TARGET_TRIPLE "wasm32-wasip1")
endif()

if(NOT IS_DIRECTORY "${CMAKE_SYSROOT}/lib/${WASI_SDK_TARGET_TRIPLE}")
  file(GLOB _wasi_available RELATIVE "${CMAKE_SYSROOT}/lib" "${CMAKE_SYSROOT}/lib/*")
  list(FILTER _wasi_available INCLUDE REGEX "^wasm")
  list(SORT _wasi_available)
  string(REPLACE ";" ", " _wasi_available_text "${_wasi_available}")
  message(FATAL_ERROR
    "wasi-sdk: target triple '${WASI_SDK_TARGET_TRIPLE}' is not provided by this SDK.\n"
    "  Available: ${_wasi_available_text}")
endif()

set(CMAKE_SYSTEM_NAME WASI)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR wasm32)

# CMake gained Platform/WASI*.cmake in 3.31; older versions need the copies
# shipped alongside this file.
if(CMAKE_VERSION VERSION_LESS 3.31)
  list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")
  list(REMOVE_DUPLICATES CMAKE_MODULE_PATH)
endif()

# ---------------------------------------------------------------------------
# Tools
# ---------------------------------------------------------------------------

set(CMAKE_C_COMPILER   "${WASI_SDK_BIN}/clang${_wasi_host_exe}")
set(CMAKE_CXX_COMPILER "${WASI_SDK_BIN}/clang++${_wasi_host_exe}")
set(CMAKE_ASM_COMPILER "${WASI_SDK_BIN}/clang${_wasi_host_exe}")

set(CMAKE_C_COMPILER_TARGET   "${WASI_SDK_TARGET_TRIPLE}")
set(CMAKE_CXX_COMPILER_TARGET "${WASI_SDK_TARGET_TRIPLE}")
set(CMAKE_ASM_COMPILER_TARGET "${WASI_SDK_TARGET_TRIPLE}")

set(CMAKE_AR     "${WASI_SDK_BIN}/llvm-ar${_wasi_host_exe}")
set(CMAKE_RANLIB "${WASI_SDK_BIN}/llvm-ranlib${_wasi_host_exe}")
set(CMAKE_NM     "${WASI_SDK_BIN}/llvm-nm${_wasi_host_exe}")
set(CMAKE_STRIP  "${WASI_SDK_BIN}/llvm-strip${_wasi_host_exe}")

# CMAKE_LINKER is left alone on purpose: linking runs through the clang driver,
# and naming wasm-ld here confuses CMake's linker detection.

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# CMake's own Platform/WASI.cmake is empty, so nothing else names the extension
# every wasm consumer expects.
set(CMAKE_EXECUTABLE_SUFFIX ".wasm")
set(CMAKE_EXECUTABLE_SUFFIX_C ".wasm")
set(CMAKE_EXECUTABLE_SUFFIX_CXX ".wasm")
set(CMAKE_EXECUTABLE_SUFFIX_ASM ".wasm")

# ---------------------------------------------------------------------------
# Optional feature flags
# ---------------------------------------------------------------------------

set(_wasi_c_flags "")
set(_wasi_cxx_flags "")
set(_wasi_c_libs "")
set(_wasi_cxx_libs "")
set(_wasi_llvm_opts_c "")
set(_wasi_llvm_opts_cxx "")

# Tracked per language: the backend rejects the encoding flag unless that same
# language also enables exceptions or setjmp.
set(_wasi_eh_opcodes_c FALSE)
set(_wasi_eh_opcodes_cxx FALSE)

if(NOT DEFINED WASI_SDK_CXX_STDLIB OR WASI_SDK_CXX_STDLIB STREQUAL "")
  set(WASI_SDK_CXX_STDLIB "libc++")
endif()
if(NOT WASI_SDK_CXX_STDLIB STREQUAL "default")
  string(APPEND _wasi_cxx_flags " -stdlib=${WASI_SDK_CXX_STDLIB}")
endif()

set(_wasi_known_emulated signal mman process-clocks getpid)
# Commas are accepted so the list survives a -D on a shell command line.
string(REPLACE "," ";" _wasi_emulated_features "${WASI_SDK_EMULATED_FEATURES}")
foreach(_wasi_feature IN LISTS _wasi_emulated_features)
  # list(FIND) rather than IN_LIST: this file must not depend on CMP0057, which
  # is unset when the toolchain is read outside a project().
  list(FIND _wasi_known_emulated "${_wasi_feature}" _wasi_feature_index)
  if(_wasi_feature_index EQUAL -1)
    string(REPLACE ";" ", " _wasi_known_text "${_wasi_known_emulated}")
    message(FATAL_ERROR
      "wasi-sdk: unknown emulated feature '${_wasi_feature}'.\n"
      "  WASI_SDK_EMULATED_FEATURES accepts: ${_wasi_known_text}")
  endif()
  string(TOUPPER "${_wasi_feature}" _wasi_feature_macro)
  string(REPLACE "-" "_" _wasi_feature_macro "${_wasi_feature_macro}")
  string(APPEND _wasi_c_flags " -D_WASI_EMULATED_${_wasi_feature_macro}")
  string(APPEND _wasi_cxx_flags " -D_WASI_EMULATED_${_wasi_feature_macro}")
  string(APPEND _wasi_c_libs " -lwasi-emulated-${_wasi_feature}")
  string(APPEND _wasi_cxx_libs " -lwasi-emulated-${_wasi_feature}")
endforeach()

if(NOT DEFINED WASI_SDK_EXCEPTIONS OR WASI_SDK_EXCEPTIONS STREQUAL "")
  set(WASI_SDK_EXCEPTIONS "off")
endif()
string(TOLOWER "${WASI_SDK_EXCEPTIONS}" _wasi_exceptions)
# The mode has to be explicit because clang picks the sysroot's include and
# library directories from it: "noeh" expects -fno-exceptions, "eh" expects
# -fwasm-exceptions. Compiling without either leaves libc++ emitting calls to
# an exception ABI that the selected multilib does not provide.
if(_wasi_exceptions STREQUAL "off")
  string(APPEND _wasi_cxx_flags " -fno-exceptions")
elseif(_wasi_exceptions STREQUAL "wasm")
  string(APPEND _wasi_cxx_flags " -fwasm-exceptions")
  string(APPEND _wasi_cxx_libs " -lunwind")
  set(_wasi_eh_opcodes_cxx TRUE)
elseif(_wasi_exceptions STREQUAL "ignore")
  # Keeps try/catch compiling for unported code, but the exception ABI symbols
  # are left undefined; link wasi::abort-exceptions from the extras to supply
  # versions that abort.
  string(APPEND _wasi_cxx_flags " -fignore-exceptions")
else()
  message(FATAL_ERROR
    "wasi-sdk: WASI_SDK_EXCEPTIONS must be 'off', 'wasm' or 'ignore', got '${WASI_SDK_EXCEPTIONS}'")
endif()

if(WASI_SDK_SETJMP)
  string(APPEND _wasi_llvm_opts_c " -mllvm -wasm-enable-sjlj")
  string(APPEND _wasi_llvm_opts_cxx " -mllvm -wasm-enable-sjlj")
  string(APPEND _wasi_c_libs " -lsetjmp")
  string(APPEND _wasi_cxx_libs " -lsetjmp")
  set(_wasi_eh_opcodes_c TRUE)
  set(_wasi_eh_opcodes_cxx TRUE)
endif()

# Both wasm exceptions and the SJLJ lowering emit exception opcodes, which have
# two encodings. clang still defaults to the legacy one, but runtimes have
# dropped it (wasmtime removed --wasm legacy-exceptions in 47), so the standard
# encoding is requested here instead.
if(NOT DEFINED WASI_SDK_EXCEPTION_ENCODING OR WASI_SDK_EXCEPTION_ENCODING STREQUAL "")
  set(WASI_SDK_EXCEPTION_ENCODING "standard")
endif()
string(TOLOWER "${WASI_SDK_EXCEPTION_ENCODING}" _wasi_encoding)
if(_wasi_encoding STREQUAL "standard")
  if(_wasi_eh_opcodes_c)
    string(APPEND _wasi_llvm_opts_c " -mllvm -wasm-use-legacy-eh=false")
  endif()
  if(_wasi_eh_opcodes_cxx)
    string(APPEND _wasi_llvm_opts_cxx " -mllvm -wasm-use-legacy-eh=false")
  endif()
elseif(NOT _wasi_encoding STREQUAL "legacy")
  message(FATAL_ERROR
    "wasi-sdk: WASI_SDK_EXCEPTION_ENCODING must be 'legacy' or 'standard', "
    "got '${WASI_SDK_EXCEPTION_ENCODING}'")
endif()

# These reach the driver on link-only invocations too, where they are not used;
# without the wrapper every link emits -Wunused-command-line-argument.
if(NOT _wasi_llvm_opts_c STREQUAL "")
  string(APPEND _wasi_c_flags
    " --start-no-unused-arguments${_wasi_llvm_opts_c} --end-no-unused-arguments")
endif()
if(NOT _wasi_llvm_opts_cxx STREQUAL "")
  string(APPEND _wasi_cxx_flags
    " --start-no-unused-arguments${_wasi_llvm_opts_cxx} --end-no-unused-arguments")
endif()

if(DEFINED WASI_SDK_CROSSCOMPILING_EMULATOR AND NOT WASI_SDK_CROSSCOMPILING_EMULATOR STREQUAL "")
  set(CMAKE_CROSSCOMPILING_EMULATOR "${WASI_SDK_CROSSCOMPILING_EMULATOR}")
endif()

# _INIT variables seed the cache once, so guard against contributing twice when
# a single configure reads this file for more than one project().
if(NOT _WASI_SDK_FLAGS_APPLIED)
  string(APPEND CMAKE_C_FLAGS_INIT "${_wasi_c_flags}")
  string(APPEND CMAKE_CXX_FLAGS_INIT "${_wasi_cxx_flags}")
  string(APPEND CMAKE_ASM_FLAGS_INIT "${_wasi_c_flags}")
  string(APPEND CMAKE_C_STANDARD_LIBRARIES "${_wasi_c_libs}")
  string(APPEND CMAKE_CXX_STANDARD_LIBRARIES "${_wasi_cxx_libs}")
  set(_WASI_SDK_FLAGS_APPLIED 1)
endif()

# Without this, compiler probes and check_<lang>_source_compiles() would run
# with a different flag set than the real build.
list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES
  WASI_SDK_ROOT
  WASI_SDK_TARGET_TRIPLE
  WASI_SDK_EMULATED_FEATURES
  WASI_SDK_EXCEPTIONS
  WASI_SDK_EXCEPTION_ENCODING
  WASI_SDK_SETJMP
  WASI_SDK_CXX_STDLIB
  WASI_SDK_CROSSCOMPILING_EMULATOR)
list(REMOVE_DUPLICATES CMAKE_TRY_COMPILE_PLATFORM_VARIABLES)
