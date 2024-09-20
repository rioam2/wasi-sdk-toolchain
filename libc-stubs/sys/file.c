#include <sys/file.h>

#ifdef __cplusplus
extern "C" {
#endif

int flock(int fd, int op) { return -1; }

#ifdef __cplusplus
}
#endif
