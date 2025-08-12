#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>


int kill(int pid, int sig) { 
  fprintf(stderr, "kill is not implemented in wasi-libc. Aborting.");
  abort();
}

int sigaltstack(const stack_t* __restrict stack, stack_t* __restrict oldstack) { 
  fprintf(stderr, "signalstack is not implemented in wasi-libc. Aborting.");
  abort();
}

int sigaction(int signum, 
              const struct sigaction *__restrict act, 
              struct sigaction *__restrict oldact) { 
  fprintf(stderr, "sigaction is not implemented in wasi-libc. Aborting.");
  abort();
}
