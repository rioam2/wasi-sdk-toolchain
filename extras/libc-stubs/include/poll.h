#pragma once

#if __has_include_next(<poll.h>)
#include_next <poll.h>
#endif

#define POLLPRI 0x002
