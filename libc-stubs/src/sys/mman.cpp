#include <__functions_malloc.h>
#include <__functions_memcpy.h>
#include <sys/mman.h>
#include <unordered_map>

extern "C" {
/**
 * This file contains an implementation of memory-mapped files (mmap) for
 * WebAssembly/WASI targets The implementation uses malloc and raw pointers to
 * store memory mapped sections of files. Native mmap support should be used
 * when implemented upstream by wasi-libc
 */

namespace {
// Keep track of mmapped ptr -> fd for unmapping resources
std::unordered_map<int, std::pair<void*, size_t> > mappedFiles;
}  // namespace

void* mmap(void* addr, size_t len, int prot, int flags, int fildes, off_t off) {
  void* ptr = malloc(len);
  memset(ptr, 0x00, len);
  std::unordered_map<int, std::pair<void*, size_t> >::iterator itr =
      mappedFiles.find(fildes);
  if (itr != std::end(mappedFiles)) {
    const void* oldPtr = itr->second.first;
    const size_t oldSize = itr->second.second;
    std::memcpy(ptr, oldPtr, std::min(len, oldSize));
    mappedFiles.erase(fildes);
  }
  mappedFiles.insert(std::make_pair(fildes, std::make_pair(ptr, len)));
  return ptr;
}

int munmap(void* addr, size_t len) {
  if (!addr) {
    return -1;
  }
  std::unordered_map<int, std::pair<void*, size_t> >::iterator it =
      mappedFiles.begin();
  while (it != mappedFiles.end()) {
    if (it->second.first == addr) {
      it = mappedFiles.erase(it);
    } else {
      ++it;
    }
  }
  std::free(addr);
  return 0;
}

int msync(void* addr, size_t len, int flags) {
  return -1;  // Not implemented
}
}
