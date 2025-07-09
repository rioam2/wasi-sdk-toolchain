#include <signal.h>

extern "C" {
int kill(int pid, int sig) {
  return -1;
}

int sigaltstack(const stack_t* __restrict stack, stack_t* __restrict oldstack) {
  return -1;
}

int sigaction(int signum,
              const struct sigaction* __restrict act,
              struct sigaction* __restrict oldact) {
  return -1;
}
}
