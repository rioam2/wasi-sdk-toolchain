cmake_minimum_required(VERSION 3.25)
project(wasi_reentrancy LANGUAGES CXX)

# Nested project() calls make CMake re-read the toolchain file. Anything that is
# not idempotent shows up here as duplicated flags or a redeclared target.
add_subdirectory(nested)

add_executable(outer main.cpp)
target_link_libraries(outer PRIVATE nested)

foreach(var IN ITEMS CMAKE_CXX_FLAGS CMAKE_C_FLAGS)
  string(REGEX MATCHALL "-stdlib=libc\\+\\+" matches "${${var}}")
  list(LENGTH matches count)
  if(count GREATER 1)
    message(FATAL_ERROR "${var} accumulated ${count} copies of -stdlib: ${${var}}")
  endif()
endforeach()

string(REGEX MATCHALL "-lwasi-emulated-getpid" libs "${CMAKE_CXX_STANDARD_LIBRARIES}")
list(LENGTH libs lib_count)
if(lib_count GREATER 1)
  message(FATAL_ERROR
    "CMAKE_CXX_STANDARD_LIBRARIES accumulated ${lib_count} copies: ${CMAKE_CXX_STANDARD_LIBRARIES}")
endif()
