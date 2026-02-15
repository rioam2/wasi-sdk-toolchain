#include <iostream>
#include <stdexcept>

int main() {
  try {
    throw std::runtime_error("This is a test exception");
  } catch (const std::exception& e) {
    // Print the exception message to standard output
    std::cout << "Caught exception: " << e.what() << std::endl;
    return 0;  // Indicate success
  }
  return 1;  // Indicate failure if no exception was caught
}