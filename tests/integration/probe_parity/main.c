#include <stdio.h>
#include <sys/mman.h>
#include <unistd.h>

int main(void) {
  printf("pid=%d\n", (int)getpid());

  void* page = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0);
  if (page == MAP_FAILED) {
    return 1;
  }
  munmap(page, 4096);
  return 0;
}
