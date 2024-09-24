#include <setjmp.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>

#ifdef __cplusplus
extern "C" {
#endif

int setjmp(jmp_buf env) { return 0; }
void longjmp(jmp_buf env, int status) { fprintf(stderr, "longjmp is not implemented in wasi-libc. Aborting."); abort(); }

#ifdef __cplusplus
}
#endif