#pragma once

#if __has_include_next(<grp.h>)
#include_next <grp.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

struct group {
  char* gr_name;
  char* gr_passwd;
  gid_t gr_gid;
  char** gr_mem;
};

#ifdef __cplusplus
}
#endif
