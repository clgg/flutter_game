class Hp {
  const Hp(this.value) : assert(value >= 0);

  final int value;

  bool get isDead => value <= 0;
}
