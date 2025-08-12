#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <unistd.h>

extern "C" {
int pipe(int pipefd[2]) {
  fprintf(stderr, "pipe is not implemented in wasi-libc. Aborting.");
  abort();
}

int pipe2(int pipefd[2], int flags) {
  fprintf(stderr, "pipe2 is not implemented in wasi-libc. Aborting.");
  abort();
}

int dup(int oldfd) {
  fprintf(stderr, "dup is not implemented in wasi-libc. Aborting.");
  abort();
}

int dup2(int oldfd, int newfd) {
  fprintf(stderr, "dup2 is not implemented in wasi-libc. Aborting.");
  abort();
}

int dup3(int oldfd, int newfd, int flags) {
  fprintf(stderr, "dup3 is not implemented in wasi-libc. Aborting.");
  abort();
}

int chown(const char* pathname, uint32_t owner, uint32_t group) {
  fprintf(stderr, "chown is not implemented in wasi-libc. Aborting.");
  abort();
}

int fchown(int fd, uint32_t owner, uint32_t group) {
  fprintf(stderr, "fchown is not implemented in wasi-libc. Aborting.");
  abort();
}

int lchown(const char* pathname, uint32_t owner, uint32_t group) {
  fprintf(stderr, "lchown is not implemented in wasi-libc. Aborting.");
  abort();
}

int fchownat(int dirfd,
             const char* pathname,
             uint32_t owner,
             uint32_t group,
             int flags) {
  fprintf(stderr, "fchownat is not implemented in wasi-libc. Aborting.");
  abort();
}

uint32_t getuid(void) {
  fprintf(stderr, "getuid is not implemented in wasi-libc. Aborting.");
  abort();
}

uint32_t geteuid(void) {
  fprintf(stderr, "geteuid is not implemented in wasi-libc. Aborting.");
  abort();
}

uint32_t getgid(void) {
  fprintf(stderr, "getgid is not implemented in wasi-libc. Aborting.");
  abort();
}

struct group* getgrgid(uint32_t gid) {
  fprintf(stderr, "getgrgid is not implemented in wasi-libc. Aborting.");
  abort();
}

struct passwd* getpwuid(uint32_t uid) {
  fprintf(stderr, "getpwuid is not implemented in wasi-libc. Aborting.");
  abort();
}

uint32_t getegid() {
  fprintf(stderr, "getegid is not implemented in wasi-libc. Aborting.");
  abort();
}

int getgroups(int size, uint32_t grouplist[]) {
  fprintf(stderr, "getgroups is not implemented in wasi-libc. Aborting.");
  abort();
}

int setuid(uint32_t uid) {
  fprintf(stderr, "setuid is not implemented in wasi-libc. Aborting.");
  abort();
}

int seteuid(uint32_t uid) {
  fprintf(stderr, "seteuid is not implemented in wasi-libc. Aborting.");
  abort();
}

int setgid(uint32_t gid) {
  fprintf(stderr, "setgid is not implemented in wasi-libc. Aborting.");
  abort();
}

int setegid(uint32_t gid) {
  fprintf(stderr, "setegid is not implemented in wasi-libc. Aborting.");
  abort();
}

pid_t gettid(void) {
  fprintf(stderr, "gettid is not implemented in wasi-libc. Aborting.");
  abort();
}

int syscall(int num, ...) {
  fprintf(stderr, "syscall is not implemented in wasi-libc. Aborting.");
  abort();
}

int gethostname(char* name, size_t len) {
  fprintf(stderr, "gethostname is not implemented in wasi-libc. Aborting.");
  abort();
}

int sethostname(const char* name, size_t len) {
  fprintf(stderr, "sethostname is not implemented in wasi-libc. Aborting.");
  abort();
}
}
