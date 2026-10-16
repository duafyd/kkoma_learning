class CountingChange {
  final int before, after;
  const CountingChange(this.before, this.after);
  int get delta => after - before;
  String get equation =>
      '$before ${delta > 0 ? '+' : '−'} ${delta.abs()} = $after';
}

class CountingState {
  final int available;
  final Set<int> basket;
  final CountingChange? change;
  const CountingState(this.available, {this.basket = const {}, this.change});
}
