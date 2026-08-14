cmake_minimum_required(VERSION 3.25)
project(wasi_reentrancy_nested LANGUAGES CXX)

add_library(nested STATIC nested.cpp)
