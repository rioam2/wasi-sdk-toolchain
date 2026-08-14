#include <cstdio>
#include <string>
#include <vector>

int main() {
  std::vector<std::string> parts{"wasi", "sdk", "toolchain"};
  std::string joined;
  for (const auto& part : parts) {
    if (!joined.empty()) joined += '-';
    joined += part;
  }
  std::printf("%s\n", joined.c_str());
  return joined == "wasi-sdk-toolchain" ? 0 : 1;
}
