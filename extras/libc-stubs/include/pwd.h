#pragma once

#if __has_include_next(<pwd.h>)
#include_next <pwd.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

struct passwd {
  char* pw_name;
  char* pw_passwd;
  uid_t pw_uid;
  gid_t pw_gid;
  time_t pw_change;
  char* pw_class;
  char* pw_gecos;
  char* pw_dir;
  char* pw_shell;
  time_t pw_expire;
};

#ifdef __cplusplus
}
#endif
