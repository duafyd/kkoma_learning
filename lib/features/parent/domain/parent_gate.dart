import 'dart:math';

class ParentGate {
  final int a, b;
  ParentGate({int? a, int? b})
    : a = a ?? Random.secure().nextInt(9) + 11,
      b = b ?? Random.secure().nextInt(9) + 3;
  String get prompt => '$a + $b = ?';
  bool accepts(String input) => int.tryParse(input.trim()) == a + b;
}
