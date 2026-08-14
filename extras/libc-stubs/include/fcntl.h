#pragma once

#if __has_include_next(<fcntl.h>)
#include_next <fcntl.h>
#endif

#define F_DUPFD 0
#define O_LARGEFILE 0

#ifdef __cplusplus
extern "C" {
#endif

int fcntl(int fd, int op, ...);

#ifdef __cplusplus
}
#endif