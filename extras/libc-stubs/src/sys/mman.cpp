#include <sys/mman.h>

extern "C" {
int msync(void* addr, size_t len, int flags) {
  return -1;  // Not implemented
}

void* mremap(void* old_address,
             size_t old_size,
             size_t new_size,
             int flags,
             ...) {
  return nullptr;  // Not implemented
}
}
