#pragma once

#if __has_include_next(<sys/eventfd.h>)
#include_next <sys/eventfd.h>
#endif

#include <unistd.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef uint64_t eventfd_t;

int eventfd(unsigned int initval, int flags);

int eventfd_read(int __fd, eventfd_t* __value);

int eventfd_write(int __fd, eventfd_t __value);

#ifdef __cplusplus
}
#endif
