#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>

int fcntl(int fd, int op, ...) { 
  fprintf(stderr, "fcntl is not implemented in wasi-libc. Aborting.");
  abort();
}
