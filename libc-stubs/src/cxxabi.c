#ifdef __cplusplus

#include <__exception/exception_ptr.h>
#include <cxxabi.h>
#include <stdio.h>
#include <cstddef>
#include <cstdlib>
#include <typeinfo>


extern "C" {
void* __cxa_allocate_exception(size_t) {
  fprintf(
      stderr, 
      "__cxa_allocate_exception are not implemented in wasi-libc. Aborting.");
  abort();
}

void __cxa_throw(void* thrown_exception,
                std::type_info* tinfo,
#ifdef __wasm__
                void*(_LIBCXXABI_DTOR_FUNC* dest)(void*)
#else
                void(_LIBCXXABI_DTOR_FUNC* dest)(void*)
#endif
)
{
  fprintf(stderr, "__cxa_throw are not implemented in wasi-libc. Aborting.");
  abort();
}
}
#endif