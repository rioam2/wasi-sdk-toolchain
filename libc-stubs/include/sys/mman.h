
#pragma once

#if __has_include_next(<sys/mman.h>)
#include_next <sys/mman.h>
#endif

void* mmap(void* addr, size_t len, int prot, int flags, int fildes, off_t off);
int munmap(void* addr, size_t len);
int msync(void* addr, size_t len, int flags);
void* mremap(void* old_address,
             size_t old_size,
             size_t new_size,
             int flags,
             ...);
