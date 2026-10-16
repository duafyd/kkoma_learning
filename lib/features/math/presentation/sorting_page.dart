import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/activity_scaffold.dart';
import '../../../core/audio/audio_service.dart';
import '../../parent/presentation/usage_vm.dart';
import '../../profile/presentation/profile_vm.dart';
import '../../profile/domain/settings.dart';
import '../domain/sorting.dart';
import 'sorting_vm.dart';
import '../../learning/domain/learning_models.dart';
import '../../story/presentation/story_picture_quiz.dart';

class SortingPage extends ConsumerStatefulWidget {
  const SortingPage({super.key});
  static const names = ['수량 짝짓기', '크기 나누기', '색 모으기', '모양 모으기'];
  @override
  ConsumerState<SortingPage> createState() => _SortingPageState();
}

class _SortingPageState extends ConsumerState<SortingPage> {
  String? announced;
  bool lineMode = false;
  final scroll = ScrollController();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsProvider).value ?? const ParentSettings();
    final snapshot = ref.watch(sortingProvider(settings.level));
    final vm = ref.read(sortingProvider(settings.level).notifier);
    if (snapshot.hasValue && settings.autoRead) {
      final s = snapshot.requireValue,
          key = '${settings.level}-${snapshot.requireValue.round}';
      if (announced != key) {
        announced = key;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref
                .read(audioProvider)
                .speak(vm.rules.activity(s).prompt, settings);
          }
        });
      }
    }
    Future<void> safe(Future<void> Function() action) async {
      try {
        await action();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('저장하지 못했어요. 다시 시도해 주세요.')),
          );
        }
      }
    }

    return ActivityScaffold(
      title: '짝꿍 바구니',
      child: snapshot.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Column(
          children: [
            const Text('놀이를 열지 못했어요.'),
            FilledButton(
              onPressed: () => ref.invalidate(sortingProvider(settings.level)),
              child: const Text('다시 열기'),
            ),
          ],
        ),
        data: (s) {
          final round = vm.rules.activity(s), done = vm.rules.done(s);
          return Scrollbar(
            controller: scroll,
            thumbVisibility: true,
            child: ListView(
              controller: scroll,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final kind in SortingKind.values)
                      ChoiceChip(
                        label: Text(SortingPage.names[kind.index]),
                        selected: round.kind == kind,
                        onSelected: (_) => safe(() => vm.mode(kind)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  round.prompt,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  '${s.round + 1} / ${vm.rules.rounds.length} 놀이 · ${s.placed.length} / ${round.pieces.length} 친구',
                ),
                LinearProgressIndicator(
                  value: s.placed.length / round.pieces.length,
                ),
                Text(s.message),
                IconButton(
                  tooltip: '놀이 안내 듣기',
                  onPressed: () => ref
                      .read(audioProvider)
                      .speak('${round.prompt}. ${s.message}', settings),
                  icon: const Icon(Icons.volume_up),
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text('바구니로 모으기'),
                      selected: !lineMode,
                      onSelected: (_) => setState(() => lineMode = false),
                    ),
                    ChoiceChip(
                      label: const Text('선으로 잇기'),
                      selected: lineMode,
                      onSelected: (_) => setState(() => lineMode = true),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (lineMode)
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: _ConnectionBoard(
                        round: round,
                        state: s,
                        hint: vm.rules.hintTarget(s),
                        onSelect: (i) => safe(() => vm.select(i)),
                        onPlace: (piece, target) =>
                            safe(() => vm.place(piece, target)),
                      ),
                    ),
                  )
                else
                  _SortingBoard(
                    targets: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (
                          var target = 0;
                          target < round.targets.length;
                          target++
                        )
                          DragTarget<int>(
                            onWillAcceptWithDetails: (d) => !done,
                            onAcceptWithDetails: (d) =>
                                safe(() => vm.place(d.data, target)),
                            builder: (context, candidate, rejected) => Semantics(
                              button: true,
                              label:
                                  '${_label(round.kind, round.targets[target], true)} 바구니',
                              child: InkWell(
                                key: ValueKey('sorting-target-$target'),
                                onTap: done || s.selected == null
                                    ? null
                                    : () => safe(
                                        () => vm.place(s.selected!, target),
                                      ),
                                child: Container(
                                  width: round.targets.length == 3 ? 100 : 140,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffedf1e5),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      width: 3,
                                      color:
                                          candidate.isNotEmpty ||
                                              vm.rules.hintTarget(s) == target
                                          ? Colors.amber
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      _Value(
                                        round.kind,
                                        round.targets[target],
                                        true,
                                      ),
                                      const Icon(
                                        Icons.shopping_basket_outlined,
                                      ),
                                      Text(
                                        '${s.placed.values.where((t) => t == target).length}친구',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    pieces: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (
                          var piece = 0;
                          piece < round.pieces.length;
                          piece++
                        )
                          Draggable<int>(
                            data: piece,
                            maxSimultaneousDrags:
                                done || s.placed.containsKey(piece) ? 0 : 1,
                            feedback: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 104,
                                child: _Value(
                                  round.kind,
                                  round.pieces[piece],
                                  false,
                                ),
                              ),
                            ),
                            childWhenDragging: const SizedBox(
                              width: 104,
                              height: 128,
                            ),
                            child: Semantics(
                              selected: s.selected == piece,
                              button: true,
                              label: _label(
                                round.kind,
                                round.pieces[piece],
                                false,
                              ),
                              child: InkWell(
                                key: ValueKey('sorting-piece-$piece'),
                                onTap: s.placed.containsKey(piece)
                                    ? null
                                    : () => safe(() => vm.select(piece)),
                                child: Container(
                                  width: 104,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: s.placed.containsKey(piece)
                                        ? const Color(0xffd7ebd5)
                                        : Colors.white,
                                    border: Border.all(
                                      width: 3,
                                      color: s.selected == piece
                                          ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      _Value(
                                        round.kind,
                                        round.pieces[piece],
                                        false,
                                      ),
                                      if (s.placed.containsKey(piece))
                                        const Icon(Icons.check_circle),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: done ? null : () => safe(vm.hint),
                      child: const Text('함께 보기'),
                    ),
                    if (settings.help &&
                        s.failures >= settings.helpAfter &&
                        !done)
                      FilledButton(
                        onPressed: () => safe(vm.assist),
                        child: const Text('친구와 함께 통과'),
                      ),
                    OutlinedButton(
                      onPressed: () => safe(vm.reset),
                      child: const Text('다시 모으기'),
                    ),
                    if (done)
                      FilledButton(
                        onPressed: () => safe(() async {
                          await vm.next();
                          final expired = await ref
                              .read(usageProvider.notifier)
                              .boundary();
                          if (context.mounted && expired) context.go('/rest');
                        }),
                        child: const Text('다음 놀이'),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConnectionBoard extends StatefulWidget {
  final SortingRound round;
  final SortingState state;
  final int? hint;
  final Future<void> Function(int) onSelect;
  final Future<void> Function(int, int) onPlace;
  const _ConnectionBoard({
    required this.round,
    required this.state,
    required this.hint,
    required this.onSelect,
    required this.onPlace,
  });
  @override
  State<_ConnectionBoard> createState() => _ConnectionBoardState();
}

class _ConnectionBoardState extends State<_ConnectionBoard> {
  int? drawing;
  Offset? pointer;
  bool pending = false;
  static Rect node(Size size, int count, int i, bool target) => Rect.fromLTWH(
    target ? size.width - 112 : 8,
    14 + i * (size.height - 28) / count,
    104,
    (size.height - 28) / count - 12,
  );
  Future<void> place(int piece, int target) async {
    if (pending) return;
    pending = true;
    try {
      await widget.onPlace(piece, target);
    } finally {
      pending = false;
    }
  }

  @override
  void didUpdateWidget(covariant _ConnectionBoard old) {
    super.didUpdateWidget(old);
    if (old.round.id != widget.round.id || old.state != widget.state) {
      drawing = null;
      pointer = null;
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final rows = math.max(
        widget.round.pieces.length,
        widget.round.targets.length,
      );
      final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
      final size = Size(c.maxWidth, rows * (160 + (scale - 1) * 100) + 28);
      final sources = [
        for (var i = 0; i < widget.round.pieces.length; i++)
          node(size, rows, i, false),
      ];
      final targets = [
        for (var i = 0; i < widget.round.targets.length; i++)
          node(size, rows, i, true),
      ];
      return GestureDetector(
        dragStartBehavior: DragStartBehavior.down,
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) {
          if (pending) return;
          final i = sources.indexWhere((r) => r.contains(d.localPosition));
          if (i < 0 || widget.state.placed.containsKey(i)) return;
          setState(() {
            drawing = i;
            pointer = d.localPosition;
          });
        },
        onPanUpdate: (d) {
          if (drawing != null) setState(() => pointer = d.localPosition);
        },
        onPanCancel: () => setState(() {
          drawing = null;
          pointer = null;
        }),
        onPanEnd: (_) {
          final piece = drawing;
          final target = pointer == null
              ? -1
              : targets.indexWhere((r) => r.contains(pointer!));
          setState(() {
            drawing = null;
            pointer = null;
          });
          if (piece != null && target >= 0) place(piece, target);
        },
        child: SizedBox.fromSize(
          size: size,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ConnectionLines(
                      sources,
                      targets,
                      widget.state.placed,
                      drawing,
                      pointer,
                    ),
                  ),
                ),
              ),
              for (final target in [false, true])
                for (var i = 0; i < (target ? targets : sources).length; i++)
                  Positioned.fromRect(
                    rect: (target ? targets : sources)[i],
                    child: Semantics(
                      button: true,
                      label:
                          '${target ? '도착' : '출발'} ${_label(widget.round.kind, (target ? widget.round.targets : widget.round.pieces)[i], target)}',
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          key: ValueKey(
                            'connection-${target ? 'target' : 'piece'}-$i',
                          ),
                          borderRadius: BorderRadius.circular(18),
                          onTap: target
                              ? (widget.state.selected == null
                                    ? null
                                    : () => place(widget.state.selected!, i))
                              : (widget.state.placed.containsKey(i)
                                    ? null
                                    : () => widget.onSelect(i)),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                width: 3,
                                color:
                                    (target
                                        ? widget.hint == i
                                        : widget.state.selected == i ||
                                              widget.state.placed.containsKey(
                                                i,
                                              ))
                                    ? const Color(0xff3b8775)
                                    : const Color(0xffe0dfce),
                              ),
                            ),
                            child: Center(
                              child: _Value(
                                widget.round.kind,
                                (target
                                    ? widget.round.targets
                                    : widget.round.pieces)[i],
                                target,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      );
    },
  );
}

class _ConnectionLines extends CustomPainter {
  final List<Rect> sources, targets;
  final Map<int, int> placed;
  final int? drawing;
  final Offset? pointer;
  _ConnectionLines(
    this.sources,
    this.targets,
    this.placed,
    this.drawing,
    this.pointer,
  );
  @override
  void paint(Canvas c, Size size) {
    void line(int source, Offset end, bool saved) {
      final start = sources[source].centerRight;
      final middle = (start.dx + end.dx) / 2;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(middle, start.dy, middle, end.dy, end.dx, end.dy);
      c.drawPath(
        path,
        Paint()
          ..color = saved ? const Color(0xff4d9982) : const Color(0xffd6a74f)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }

    for (final pair in placed.entries) {
      line(pair.key, targets[pair.value].centerLeft, true);
    }
    if (drawing != null && pointer != null) line(drawing!, pointer!, false);
  }

  @override
  bool shouldRepaint(covariant _ConnectionLines old) => true;
}

class _SortingBoard extends StatelessWidget {
  final Widget pieces, targets;
  const _SortingBoard({required this.pieces, required this.targets});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) => bounds.maxWidth >= 650
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: pieces),
              const SizedBox(width: 16),
              Expanded(child: targets),
            ],
          )
        : Column(children: [targets, const SizedBox(height: 12), pieces]),
  );
}

String _label(SortingKind kind, int value, bool target) => switch (kind) {
  SortingKind.quantity => '${target ? '별' : '사과'} $value개',
  SortingKind.size => ['작은 친구', '중간 친구', '큰 친구'][value],
  SortingKind.color => ['빨강', '노랑', '파랑'][value],
  SortingKind.shape => ['동그라미', '세모', '네모'][value],
};

class _Value extends StatelessWidget {
  final SortingKind kind;
  final int value;
  final bool target;
  const _Value(this.kind, this.value, this.target);
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        _label(kind, value, target),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16),
      ),
      SizedBox(
        width: 88,
        height: 88,
        child: CustomPaint(painter: _PiecesPainter(kind, value, target)),
      ),
    ],
  );
}

class _PiecesPainter extends CustomPainter {
  final SortingKind kind;
  final int value;
  final bool target;
  const _PiecesPainter(this.kind, this.value, this.target);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 88, size.height / 88);
    final paint = Paint()
      ..color = kind == SortingKind.color
          ? [Colors.red, Colors.amber, Colors.blue][value]
          : target
          ? const Color(0xffc48b15)
          : const Color(0xff376e64);
    if (kind == SortingKind.quantity) {
      for (var i = 0; i < value; i++) {
        final center = Offset(14 + (i % 3) * 30, 14 + (i ~/ 3) * 25);
        canvas.save();
        canvas.translate(center.dx - 12, center.dy - 12);
        QuizGlyphPainter(target ? QuizGlyph.star : QuizGlyph.apple)
            .paint(canvas, const Size(24, 24));
        canvas.restore();
      }
      canvas.restore();
      return;
    }
    final radius = kind == SortingKind.size ? [12.0, 23.0, 35.0][value] : 30.0;
    if (kind == SortingKind.shape && value == 1) {
      canvas.drawPath(
        Path()
          ..moveTo(44, 12)
          ..lineTo(78, 74)
          ..lineTo(10, 74)
          ..close(),
        paint,
      );
    } else if (kind == SortingKind.shape && value == 2) {
      canvas.drawRect(const Rect.fromLTWH(14, 14, 60, 60), paint);
    } else {
      canvas.drawCircle(const Offset(44, 44), radius, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PiecesPainter old) =>
      old.kind != kind || old.value != value || old.target != target;
}
