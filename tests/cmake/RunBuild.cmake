# Configures and builds a project out-of-tree, used by the integration tests.
#
#   cmake -DSRC=<dir> -DBIN=<dir> [-DCFG_ARGS=a|b] [-DEXPECT_FILE=<path>]
#         [-DBUILD_TARGET=<name>] -P RunBuild.cmake

cmake_minimum_required(VERSION 3.25)

foreach(required IN ITEMS SRC BIN)
  if(NOT DEFINED ${required})
    message(FATAL_ERROR "RunBuild.cmake: ${required} is required")
  endif()
endforeach()

set(extra_args "")
if(DEFINED CFG_ARGS AND NOT CFG_ARGS STREQUAL "")
  string(REPLACE "|" ";" extra_args "${CFG_ARGS}")
endif()

# Always start from scratch so a stale cache cannot mask a configure regression.
file(REMOVE_RECURSE "${BIN}")
file(MAKE_DIRECTORY "${BIN}")

execute_process(
  COMMAND "${CMAKE_COMMAND}" -S "${SRC}" -B "${BIN}" -G Ninja ${extra_args}
  RESULT_VARIABLE configure_result)
if(NOT configure_result EQUAL 0)
  message(FATAL_ERROR "configure failed (${configure_result})")
endif()

set(build_args "")
if(DEFINED BUILD_TARGET AND NOT BUILD_TARGET STREQUAL "")
  set(build_args --target "${BUILD_TARGET}")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" --build "${BIN}" ${build_args}
  RESULT_VARIABLE build_result)
if(NOT build_result EQUAL 0)
  message(FATAL_ERROR "build failed (${build_result})")
endif()

if(DEFINED EXPECT_FILE AND NOT EXPECT_FILE STREQUAL "")
  string(REPLACE "|" ";" expected_files "${EXPECT_FILE}")
  foreach(expected IN LISTS expected_files)
    if(NOT EXISTS "${BIN}/${expected}")
      file(GLOB_RECURSE produced RELATIVE "${BIN}" "${BIN}/*.wasm")
      string(REPLACE ";" "\n    " produced_text "${produced}")
      message(FATAL_ERROR
        "expected build output '${expected}' was not produced.\n"
        "  wasm files in the build tree:\n    ${produced_text}")
    endif()
  endforeach()
endif()

message(STATUS "RunBuild: ${SRC} OK")
