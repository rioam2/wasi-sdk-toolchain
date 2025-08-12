#include <setjmp.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>

extern "C" {
int setjmp(jmp_buf env) {
  fprintf(stderr, "setjmp is not implemented in wasi-libc. Aborting.");
  abort();
}

void longjmp(jmp_buf env, int status) {
  fprintf(stderr, "longjmp is not implemented in wasi-libc. Aborting.");
  abort();
}
}
