#pragma once
#ifdef __cplusplus

#if __has_include_next(<cxxabi.h>)
#include_next <cxxabi.h>
#endif

extern "C" {

void* __cxa_allocate_exception(size_t);
void __cxa_throw(void* thrown_exception,
                 std::type_info* tinfo,
#ifdef __wasm__
                 void*(_LIBCXXABI_DTOR_FUNC* dest)(void*)
#else
                 void(_LIBCXXABI_DTOR_FUNC* dest)(void*)
#endif
);
}
#endif