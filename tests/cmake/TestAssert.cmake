# Assertion helpers for the script-mode unit tests.

cmake_minimum_required(VERSION 3.25)

include_guard(GLOBAL)

function(_expect_fail message)
  message(FATAL_ERROR "assertion failed: ${message}")
endfunction()

function(expect_eq actual expected)
  if(NOT "${actual}" STREQUAL "${expected}")
    _expect_fail("${ARGN}\n  expected: '${expected}'\n  actual:   '${actual}'")
  endif()
endfunction()

function(expect_match text regex)
  if(NOT "${text}" MATCHES "${regex}")
    _expect_fail("${ARGN}\n  expected match: '${regex}'\n  in:             '${text}'")
  endif()
endfunction()

function(expect_no_match text regex)
  if("${text}" MATCHES "${regex}")
    _expect_fail("${ARGN}\n  unexpected match: '${regex}'\n  in:               '${text}'")
  endif()
endfunction()

function(expect_true value)
  if(NOT value)
    _expect_fail("${ARGN}\n  expected a true value, got '${value}'")
  endif()
endfunction()

function(expect_count_eq text regex expected)
  string(REGEX MATCHALL "${regex}" matches "${text}")
  list(LENGTH matches actual)
  if(NOT actual EQUAL expected)
    _expect_fail("${ARGN}\n  expected ${expected} occurrence(s) of '${regex}', found ${actual}\n  in: '${text}'")
  endif()
endfunction()

# CMake's regex engine has no {n} quantifier, so length is checked separately.
function(expect_sha256 value)
  string(LENGTH "${value}" length)
  if(NOT length EQUAL 64 OR NOT value MATCHES "^[0-9a-f]+$")
    _expect_fail("${ARGN}\n  expected a lowercase 64-character sha256, got '${value}'")
  endif()
endfunction()

if(NOT DEFINED REPO_DIR)
  message(FATAL_ERROR "REPO_DIR must be passed to unit test scripts")
endif()
set(FIXTURE_SDK "${REPO_DIR}/tests/fixtures/fake-sdk")
