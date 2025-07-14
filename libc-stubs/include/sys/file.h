#pragma once

#if __has_include_next(<sys/file.h>)
#include_next <sys/file.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

int flock(int fd, int op);

#ifdef __cplusplus
}
#endif
