#pragma once

#if __has_include_next(<unistd.h>)
#include_next <unistd.h>
#endif

#include <grp.h>
#include <pwd.h>

#define SYS_gettid gettid

#ifdef __cplusplus
extern "C" {
#endif

int pipe(int[2]);
int pipe2(int[2], int);
int dup(int);
int dup2(int, int);
int dup3(int, int, int);
int chown(const char*, uid_t, gid_t);
int fchown(int, uid_t, gid_t);
int lchown(const char*, uid_t, gid_t);
int fchownat(int, const char*, uid_t, gid_t, int);
uid_t getuid(void);
uid_t geteuid(void);
gid_t getgid(void);
struct group* getgrgid(gid_t);
struct passwd* getpwuid(uid_t);
gid_t getegid(void);
int getgroups(int, gid_t[]);
int setuid(uid_t);
int seteuid(uid_t);
int setgid(gid_t);
int setegid(gid_t);
pid_t gettid(void);
int syscall(int, ...);
int gethostname(char* name, size_t len);
int sethostname(const char* name, size_t len);

#ifndef _LIBCPP_HAS_DEFINED_TERMINATE
#define _LIBCPP_HAS_DEFINED_TERMINATE

#include_next <cstdlib>
namespace std {
[[noreturn]] void terminate() noexcept;
}  // namespace std

#endif

#ifdef __cplusplus
}
#endif