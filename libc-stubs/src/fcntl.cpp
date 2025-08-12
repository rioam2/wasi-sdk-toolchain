#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>

extern "C" {
int fcntl(int fd, int op, ...) {
  fprintf(stderr, "fcntl is not implemented in wasi-libc. Aborting.");
  abort();
}
}
