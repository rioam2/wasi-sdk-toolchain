#pragma once

#if __has_include_next(<time.h>)
#include_next <time.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

void tzset();
extern char* tzname[2];

#ifdef __cplusplus
}
#endif