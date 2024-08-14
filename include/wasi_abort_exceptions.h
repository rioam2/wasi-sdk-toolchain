#pragma once

#include <__exception/exception_ptr.h>
#include <cstddef>
#include <cstdlib>
#include <cxxabi.h>
#include <typeinfo>

extern "C" {
void *__cxa_allocate_exception(size_t) { std::abort(); }
void __cxa_throw(void *, std::type_info *, void(_LIBCXXABI_DTOR_FUNC *)(void *)) { abort(); }
}
