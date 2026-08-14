#include <signal.h>
#include <stdio.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>

// Each call needs both the -D_WASI_EMULATED_* define and the matching
// -lwasi-emulated-* library, so this fails to build or link if either half of
// a feature mapping is wrong.
int main(void) {
  printf("pid=%d\n", (int)getpid());

  void* page = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0);
  if (page == MAP_FAILED) return 1;
  munmap(page, 4096);

  if (clock() == (clock_t)-1) return 1;

  signal(SIGINT, SIG_DFL);
  return 0;
}
