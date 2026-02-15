#include <setjmp.h>
#include <stdio.h>
#include <stdlib.h>

// jmp_buf holds the state of the program (registers, stack pointer, etc.)
jmp_buf buf;

void jump_function() {
  printf("  Inside jump_function: Now longjmping...\n");
  // longjmp transfers control back to where setjmp was called.
  // The second argument is the value setjmp will return.
  longjmp(buf, 1);
  printf("  This will never be printed.\n");
}

int main() {
  printf("1. Calling setjmp\n");

  // setjmp saves the environment and returns 0 the first time.
  if (setjmp(buf) == 0) {
    printf("2. setjmp returned 0\n");
    jump_function();
  } else {
    // If longjmp is called, setjmp returns the value from longjmp.
    printf("3. Back in main! (longjmp returned here)\n");
  }

  return 0;
}