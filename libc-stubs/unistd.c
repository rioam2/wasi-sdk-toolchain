#include <unistd.h>

#ifdef __cplusplus
extern "C" {
#endif

int pipe(int pipefd[2]) { return -1; }
int pipe2(int pipefd[2], int flags) { return -1; }
int dup(int oldfd) { return -1; }
int dup2(int oldfd, int newfd) { return -1; }
int dup3(int oldfd, int newfd, int flags) { return -1; }
int chown(const char* pathname, uint32_t owner, uint32_t group) { return -1; }
int fchown(int fd, uint32_t owner, uint32_t group) { return -1; }
int lchown(const char* pathname, uint32_t owner, uint32_t group) { return -1; }
int fchownat(int dirfd, const char* pathname, uint32_t owner, uint32_t group, int flags) { return -1; }
uint32_t getuid(void) { return 0; }
uint32_t geteuid(void) { return 0; }
uint32_t getgid(void) { return 0; }
struct group* getgrgid(uint32_t gid) { return 0x00; }
struct passwd* getpwuid(uint32_t uid) { return 0x00; }
uint32_t getegid() { return -1; }
int getgroups(int size, uint32_t grouplist[]) { return -1; }
int setuid(uint32_t uid) { return -1; }
int seteuid(uint32_t uid) { return -1; }
int setgid(uint32_t gid) { return -1; }
int setegid(uint32_t gid) { return -1; }
pid_t gettid(void) { return -1; }
int syscall(int num, ...) { return -1; }
int gethostname(char* name, size_t len) { return -1; }
int sethostname(const char* name, size_t len) { return -1; }

#ifdef __cplusplus
}
#endif