int from_a();
int from_b();

int main() {
  return from_a() + from_b() == 3 ? 0 : 1;
}
