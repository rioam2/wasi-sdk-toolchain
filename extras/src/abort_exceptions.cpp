#include <wasi_abort_exceptions>

#include <cstdio>
#include <cstdlib>
#include <typeinfo>

namespace {
[[noreturn]] void abort_with_message() {
  std::fputs("Exceptions are not available in this build. Aborting.\n", stderr);
  std::abort();
}
}  // namespace

// Signatures follow libc++abi's __wasm__ branch, where the destructor argument
// returns void* rather than void.
extern "C" {

void* __cxa_allocate_exception(size_t) noexcept { abort_with_message(); }

void __cxa_throw(void*, std::type_info*, void* (*)(void*)) { abort_with_message(); }
}
