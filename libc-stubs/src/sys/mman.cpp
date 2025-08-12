#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <sys/mman.h>

extern "C" {
int msync(void* addr, size_t len, int flags) {
  fprintf(stderr, "msync is not implemented in wasi-libc. Aborting.");
  abort();
}

void* mremap(void* old_address,
             size_t old_size,
             size_t new_size,
             int flags,
             ...) {
  fprintf(stderr, "mremap is not implemented in wasi-libc. Aborting.");
  abort();
}
}
