#include <sys/file.h>
#include <unistd.h>

// Declared by the stub headers and defined by the stub library; wasi-libc
// provides neither.
int main(void) {
  int fds[2];
  (void)pipe(fds);
  (void)flock(0, 0);
  return 0;
}
