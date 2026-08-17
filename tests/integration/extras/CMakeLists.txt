cmake_minimum_required(VERSION 3.25)
project(wasi_extras LANGUAGES C CXX)

if(NOT WASI_SDK_EXCEPTIONS STREQUAL "ignore")
  message(FATAL_ERROR "this project expects WASI_SDK_EXCEPTIONS=ignore")
endif()

wasi_sdk_add_extras()

foreach(target IN ITEMS wasi::reactor wasi::abort-exceptions wasi::libc-stubs)
  if(NOT TARGET ${target})
    message(FATAL_ERROR "extras did not declare ${target}")
  endif()
endforeach()

# Three translation units linking the same helper: the previous force-include
# approach emitted the definitions once per TU and failed here.
add_executable(abort_exceptions_multi_tu
  abort_exceptions/main.cpp
  abort_exceptions/a.cpp
  abort_exceptions/b.cpp)
target_link_libraries(abort_exceptions_multi_tu PRIVATE wasi::abort-exceptions)

add_executable(reactor reactor/module.cpp)
target_link_libraries(reactor PRIVATE wasi::reactor)

add_executable(libc_stubs libc_stubs/main.c)
target_link_libraries(libc_stubs PRIVATE wasi::libc-stubs)

# The stub headers shadow real wasi-libc ones, so they must reach only the
# target that opted in.
get_target_property(stub_includes wasi_sdk_libc_stubs INTERFACE_INCLUDE_DIRECTORIES)
get_target_property(reactor_includes reactor INCLUDE_DIRECTORIES)
if(reactor_includes AND stub_includes)
  foreach(dir IN LISTS stub_includes)
    if(dir IN_LIST reactor_includes)
      message(FATAL_ERROR "libc stub headers leaked onto a target that did not ask for them")
    endif()
  endforeach()
endif()
