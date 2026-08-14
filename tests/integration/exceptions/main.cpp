#include <cstdio>
#include <stdexcept>
#include <string>

int main() {
  try {
    throw std::runtime_error("thrown");
  } catch (const std::runtime_error& error) {
    std::printf("caught: %s\n", error.what());
    return std::string(error.what()) == "thrown" ? 0 : 1;
  }
  return 1;
}
