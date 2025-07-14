#include <sys/eventfd.h>

extern "C" {
int eventfd(unsigned int initval, int flags) {
  return -1;  // Not implemented
}

int eventfd_read(int __fd, eventfd_t* __value) {
  return -1;  // Not implemented
}

int eventfd_write(int __fd, eventfd_t __value) {
  return -1;  // Not implemented
}
}
