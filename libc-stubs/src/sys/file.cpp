#include <sys/file.h>

extern "C" {
int flock(int fd, int op) {
  return -1;
}
}
