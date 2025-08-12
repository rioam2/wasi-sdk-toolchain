#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <sys/eventfd.h>

extern "C" {
int eventfd(unsigned int initval, int flags) {
  fprintf(stderr, "eventfd is not implemented in wasi-libc. Aborting.");
  abort();
}

int eventfd_read(int __fd, eventfd_t* __value) {
  fprintf(stderr, "eventfd_read is not implemented in wasi-libc. Aborting.");
  abort();
}

int eventfd_write(int __fd, eventfd_t __value) {
  fprintf(stderr, "eventfd_write is not implemented in wasi-libc. Aborting.");
  abort();
}
}
