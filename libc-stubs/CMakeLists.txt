cmake_minimum_required(VERSION 3.15)

# Project information
project(wasi-sdk-toolchain-libc-stubs VERSION 1.0.0 LANGUAGES C CXX)

# Specify the C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Pure C stubs - implementations that don't require C++ features.
# Headers already have extern "C" guards, so these can be linked from C++ code.
add_library(c-stubs STATIC
    "${CMAKE_CURRENT_SOURCE_DIR}/src/fcntl.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/setjmp.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/signal.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/time.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/unistd.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/sys/eventfd.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/sys/file.c"
)

# C++ specific stubs - implementations that require C++ features (cxxabi, etc.).
# Links against c-stubs to include all C stubs as well.
add_library(cxx-stubs STATIC
    "${CMAKE_CURRENT_SOURCE_DIR}/src/cxxabi.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/thread.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/sys/mman.cpp"
)

set_target_properties(c-stubs
    PROPERTIES 
        LINKER_LANGUAGE C
)

set_target_properties(cxx-stubs
    PROPERTIES 
        LINKER_LANGUAGE CXX
)

target_include_directories(c-stubs PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_include_directories(cxx-stubs PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

# cxx-stubs links against c-stubs so C++ programs get all stubs
target_link_libraries(cxx-stubs PUBLIC c-stubs)

install(TARGETS c-stubs DESTINATION lib)
install(TARGETS cxx-stubs DESTINATION lib)
