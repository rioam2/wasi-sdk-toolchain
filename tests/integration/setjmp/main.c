#include <setjmp.h>
#include <stdio.h>

static jmp_buf env;

static void jump_back(void) { longjmp(env, 42); }

int main(void) {
  int value = setjmp(env);
  if (value == 0) {
    jump_back();
    return 1;
  }
  printf("longjmp delivered %d\n", value);
  return value == 42 ? 0 : 1;
}
