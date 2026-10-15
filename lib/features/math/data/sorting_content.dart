import '../domain/sorting.dart';

List<SortingRound> sortingRounds(int level) {
  final result = <SortingRound>[];
  for (var variant = 0; variant < 3; variant++) {
    for (final kind in SortingKind.values) {
      final values = kind == SortingKind.quantity
          ? level == 2
                ? [1, 2 + variant % 2]
                : level == 3
                ? [1 + variant, 2 + variant]
                : [1 + variant, 4 + variant, 7 + variant]
          : level <= 3
          ? [0, 2]
          : [0, 1, 2];
      final shift = variant % values.length;
      final ordered = [...values.skip(shift), ...values.take(shift)];
      final pieces = kind == SortingKind.quantity
          ? [...ordered]
          : [...ordered, ...ordered.reversed];
      result.add(
        SortingRound(
          '${kind.name}-$variant',
          switch (kind) {
            SortingKind.quantity => '같은 수의 친구끼리 짝지어요',
            SortingKind.size => '작은 친구와 큰 친구를 나누어요',
            SortingKind.color => '같은 색의 바구니에 모아요',
            SortingKind.shape => '같은 모양끼리 모아요',
          },
          kind,
          List.unmodifiable(pieces),
          List.unmodifiable(values.reversed),
        ),
      );
    }
  }
  return List.unmodifiable(result);
}
