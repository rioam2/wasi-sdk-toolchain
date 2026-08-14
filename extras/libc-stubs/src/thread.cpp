#include <cstdlib>

// Stub implementations for thread-related functions when building without
// threads.
#if defined(_LIBCPP_HAS_NO_THREADS)
extern "C" {
int __cxa_thread_atexit(void (*func)(void*), void* arg, void* dso_handle) {
  // This implementation ignores thread-specific cleanup.
  abort();
  return 0;
}
}
#endif