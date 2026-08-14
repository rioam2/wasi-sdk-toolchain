# Runs a script that is expected to fail, and asserts on its diagnostic.
#
#   cmake -DSCRIPT=<path> -DREPO_DIR=<path> -DEXPECT=<regex>|<regex> \
#         -P RunExpectFailure.cmake
#
# CTest's PASS_REGULAR_EXPRESSION would only give "any of these matched"; error
# messages are the feature under test here, so every pattern must match.

cmake_minimum_required(VERSION 3.25)

foreach(required IN ITEMS SCRIPT REPO_DIR EXPECT)
  if(NOT DEFINED ${required})
    message(FATAL_ERROR "RunExpectFailure.cmake: ${required} is required")
  endif()
endforeach()

execute_process(
  COMMAND "${CMAKE_COMMAND}" "-DREPO_DIR=${REPO_DIR}" -P "${SCRIPT}"
  RESULT_VARIABLE result
  OUTPUT_VARIABLE stdout_text
  ERROR_VARIABLE stderr_text)

set(output "${stdout_text}${stderr_text}")

if(result EQUAL 0)
  message(FATAL_ERROR "expected ${SCRIPT} to fail, but it succeeded:\n${output}")
endif()

string(REPLACE "|" ";" patterns "${EXPECT}")
foreach(pattern IN LISTS patterns)
  if(NOT output MATCHES "${pattern}")
    message(FATAL_ERROR
      "diagnostic did not match '${pattern}'.\n"
      "--- actual output ---\n${output}")
  endif()
endforeach()

message(STATUS "failed as expected: ${SCRIPT}")
