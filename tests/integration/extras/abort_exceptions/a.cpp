#include <wasi_abort_exceptions>

#include <stdexcept>

volatile bool a_should_throw = false;

int from_a() {
  if (a_should_throw) {
    throw std::runtime_error("a");
  }
  return 1;
}
