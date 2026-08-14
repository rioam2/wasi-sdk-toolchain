include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

# The toolchain file must stay free of directory-scoped and target-declaring
# commands. Those do not survive being re-read for try_compile or a nested
# project(), which is what made the previous implementation diverge between
# compiler probes and the real build.
set(banned
  "add_compile_options"
  "add_compile_definitions"
  "add_link_options"
  "add_definitions"
  "include_directories"
  "link_directories"
  "link_libraries"
  "add_library"
  "add_executable"
  "add_subdirectory"
  "add_custom_target"
  "add_custom_command"
  "find_package"
  "include_guard"
  "execute_process"
  "file[ \t]*\\([ \t]*DOWNLOAD"
  "cmake_minimum_required"
  # Needs CMP0057, which is unset when the toolchain is read outside project().
  "IN_LIST")

file(STRINGS "${REPO_DIR}/wasi-sdk.toolchain.cmake" lines)
set(code "")
foreach(line IN LISTS lines)
  string(STRIP "${line}" stripped)
  if(NOT stripped MATCHES "^#")
    string(APPEND code "${line}\n")
  endif()
endforeach()

foreach(command IN LISTS banned)
  if(code MATCHES "(^|[ \t\n])${command}")
    message(FATAL_ERROR
      "assertion failed: wasi-sdk.toolchain.cmake uses '${command}'.\n"
      "  Side effects belong in cmake/WasiSdkAcquire.cmake or cmake/WasiSdkExtras.cmake.")
  endif()
endforeach()

message(STATUS "toolchain purity OK")
