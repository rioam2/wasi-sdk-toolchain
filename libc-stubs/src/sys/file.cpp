#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <sys/file.h>

extern "C" {
int flock(int fd, int op) {
  fprintf(stderr, "flock is not implemented in wasi-libc. Aborting.");
  abort();
}
}
