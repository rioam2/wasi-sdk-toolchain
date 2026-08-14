// Mirrors the shape of a real dependency (fmt's os.cc) that fails to compile
// against wasi-libc because these are simply not declared there.
#include <fcntl.h>
#include <sys/file.h>
#include <sys/mman.h>
#include <unistd.h>

int duplicate(int fd) {
  return ::dup(fd);
}
int duplicate_onto(int from, int to) {
  return ::dup2(from, to);
}
int lock_file(int fd) {
  return ::flock(fd, 0);
}
int sync_mapping(void* addr, size_t len) {
  return ::msync(addr, len, 0);
}
