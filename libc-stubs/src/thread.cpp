#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>

#if defined(_LIBCPP_HAS_NO_THREADS)
extern "C" {
int __cxa_thread_atexit(void (*func)(void*), void* arg, void* dso_handle) {
  fprintf(stderr,
          "__cxa_thread_atexit is not implemented in wasi-libc. Aborting.");
  abort();
}
}
#endif