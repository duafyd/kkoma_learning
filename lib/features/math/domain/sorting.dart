enum SortingKind { quantity, size, color, shape }

class SortingRound {
  final String id, prompt;
  final SortingKind kind;
  final List<int> pieces, targets;
  const SortingRound(
    this.id,
    this.prompt,
    this.kind,
    this.pieces,
    this.targets,
  );
}

class SortingState {
  final int round, failures, hints;
  final int? selected;
  final Map<int, int> placed;
  final bool assisted;
  final String message;
  const SortingState({
    this.round = 0,
    this.failures = 0,
    this.hints = 0,
    this.selected,
    this.placed = const {},
    this.assisted = false,
    this.message = '친구를 바구니로 옮겨요. 눌러서 짝지어도 좋아요.',
  });
  Map<String, dynamic> toJson() => {
    'round': round,
    'failures': failures,
    'hints': hints,
    'selected': selected,
    'placed': {for (final e in placed.entries) '${e.key}': e.value},
    'assisted': assisted,
    'message': message,
  };
  factory SortingState.fromJson(Map<String, dynamic> j) => SortingState(
    round: j['round'] as int? ?? 0,
    failures: j['failures'] as int? ?? 0,
    hints: j['hints'] as int? ?? 0,
    selected: j['selected'] as int?,
    placed: {
      for (final e in (j['placed'] as Map? ?? {}).entries)
        int.parse(e.key as String): e.value as int,
    },
    assisted: j['assisted'] as bool? ?? false,
    message: j['message'] as String? ?? '다시 함께 해요.',
  );
  SortingState change(Map<String, dynamic> j) =>
      SortingState.fromJson({...toJson(), ...j});
}

class SortingRules {
  final List<SortingRound> rounds;
  const SortingRules(this.rounds);
  SortingRound activity(SortingState s) => rounds[s.round];
  bool done(SortingState s) => s.placed.length == activity(s).pieces.length;
  SortingState restore(SortingState s) {
    if (s.round < 0 || s.round >= rounds.length) return const SortingState();
    final r = activity(s);
    final valid = s.placed.entries.every(
      (e) =>
          e.key >= 0 &&
          e.key < r.pieces.length &&
          e.value >= 0 &&
          e.value < r.targets.length &&
          r.pieces[e.key] == r.targets[e.value],
    );
    if (!valid) return SortingState(round: s.round);
    if (s.selected != null &&
        (s.selected! < 0 ||
            s.selected! >= r.pieces.length ||
            s.placed.containsKey(s.selected))) {
      return s.change({'selected': null});
    }
    return s;
  }

  SortingState select(SortingState s, int piece) =>
      piece < 0 ||
          piece >= activity(s).pieces.length ||
          s.placed.containsKey(piece)
      ? s
      : s.change({'selected': piece, 'message': '짝이 되는 바구니를 눌러요.'});
  SortingState place(SortingState s, int piece, int target) {
    final r = activity(s);
    if (done(s) ||
        piece < 0 ||
        piece >= r.pieces.length ||
        target < 0 ||
        target >= r.targets.length ||
        s.placed.containsKey(piece)) {
      return s;
    }
    if (r.pieces[piece] != r.targets[target]) {
      return s.change({
        'selected': piece,
        'failures': s.failures + 1,
        'message': '모양과 수를 한 번 더 살펴볼까요?',
      });
    }
    final placed = {...s.placed, piece: target};
    return s.change({
      'placed': {for (final e in placed.entries) '${e.key}': e.value},
      'selected': null,
      'message': placed.length == r.pieces.length
          ? '모두 짝지었어요! 끝까지 집중했어요.'
          : '같은 친구끼리 만났어요!',
    });
  }

  int? hintTarget(SortingState s) => s.hints == 0 || s.selected == null
      ? null
      : activity(s).targets.indexOf(activity(s).pieces[s.selected!]);
  SortingState hint(SortingState s) {
    if (done(s)) return s;
    final piece =
        s.selected ??
        List.generate(
          activity(s).pieces.length,
          (i) => i,
        ).firstWhere((i) => !s.placed.containsKey(i));
    return s.change({
      'selected': piece,
      'hints': s.hints + 1,
      'message': '빛나는 친구와 바구니를 함께 보아요.',
    });
  }

  SortingState assist(
    SortingState s, {
    required bool allowed,
    required int after,
  }) {
    if (!allowed || s.failures < after || done(s)) return s;
    var next = s;
    for (var i = 0; i < activity(s).pieces.length; i++) {
      next = place(next, i, activity(s).targets.indexOf(activity(s).pieces[i]));
    }
    return next.change({'assisted': true, 'message': '친구와 함께 모두 모았어요!'});
  }

  SortingState next(SortingState s) =>
      !done(s) ? s : SortingState(round: (s.round + 1) % rounds.length);
}
