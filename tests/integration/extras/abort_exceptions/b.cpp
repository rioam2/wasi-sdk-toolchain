#include <wasi_abort_exceptions>

#include <stdexcept>

volatile bool b_should_throw = false;

int from_b() {
  if (b_should_throw) {
    throw std::logic_error("b");
  }
  return 2;
}
