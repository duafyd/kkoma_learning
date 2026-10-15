import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../parent/presentation/usage_vm.dart';

import '../../../core/widgets/activity_scaffold.dart';
import '../../../core/widgets/canvas_workspace.dart';
import '../../profile/presentation/profile_vm.dart';
import '../../tracing/domain/trace_engine.dart';
import '../domain/drawing.dart';
import '../domain/drawing_renderer.dart';
import 'drawing_vm.dart';

class DrawingPage extends ConsumerStatefulWidget {
  const DrawingPage({super.key});
  @override
  ConsumerState<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends ConsumerState<DrawingPage> {
  int color = 0xff376e64;
  double width = .012;
  bool eraser = false, saving = false;
  String? stamp;
  Future<void> perform(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('보관하지 못했어요. 보호자에게 저장 공간 확인을 부탁해 주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(drawingProvider);
    final older = (ref.watch(settingsProvider).value?.level ?? 3) >= 4;
    return ActivityScaffold(
      title: '자유 그림방',
      child: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('그림을 불러오지 못했어요: $e'),
        data: (h) => CanvasWorkspace(
          controlsFirst: true,
          canvas: DrawingCanvas(
            document: h.current,
            color: color,
            width: width,
            eraser: eraser,
            stamp: stamp,
            onLine: (l) =>
                perform(() => ref.read(drawingProvider.notifier).add(l)),
          ),
          controls: Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ...[
                    0xff376e64,
                    0xffe76f51,
                    0xffe9b331,
                    0xff4289b5,
                    0xff8648a6,
                    0xff222222,
                  ].map(
                    (c) => IconButton(
                      tooltip: '색상 $c',
                      style: IconButton.styleFrom(backgroundColor: Color(c)),
                      onPressed: () => setState(() {
                        color = c;
                        eraser = false;
                        stamp = null;
                      }),
                      icon: Icon(
                        color == c && !eraser
                            ? Icons.check
                            : Icons.circle_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '지우개',
                    onPressed: () => setState(() {
                      eraser = !eraser;
                      stamp = null;
                    }),
                    icon: Icon(
                      Icons.auto_fix_normal,
                      color: eraser ? Colors.orange : null,
                    ),
                  ),
                  IconButton(
                    tooltip: '실행 취소',
                    onPressed: h.past.isEmpty
                        ? null
                        : () =>
                              perform(ref.read(drawingProvider.notifier).undo),
                    icon: const Icon(Icons.undo),
                  ),
                  IconButton(
                    tooltip: '다시 실행',
                    onPressed: h.future.isEmpty
                        ? null
                        : () =>
                              perform(ref.read(drawingProvider.notifier).redo),
                    icon: const Icon(Icons.redo),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      if (await confirmAction(context, '그림을 모두 지울까요?')) {
                        await perform(ref.read(drawingProvider.notifier).clear);
                      }
                    },
                    child: const Text('전체 지우기'),
                  ),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            setState(() => saving = true);
                            try {
                              await ref.read(drawingProvider.notifier).save();
                              await ref
                                  .read(galleryProvider.notifier)
                                  .refresh();
                              final expired = await ref
                                  .read(usageProvider.notifier)
                                  .boundary();
                              if (context.mounted && expired) {
                                context.go('/rest');
                                return;
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('내 작품에 저장했어요!')),
                                );
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '저장할 수 없어요. 보호자에게 저장 공간 확인을 부탁해 주세요.',
                                    ),
                                  ),
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                setState(() => saving = false);
                              }
                            }
                          },
                    child: Text(saving ? '저장 중…' : '작품 저장'),
                  ),
                ],
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('굵기'),
                  SizedBox(
                    width: 220,
                    child: Slider(
                      value: width,
                      min: .006,
                      max: .05,
                      divisions: older ? 8 : 2,
                      onChanged: (v) => setState(() => width = v),
                    ),
                  ),
                  if (older)
                    ...['🌼', '🦋', '⭐', '●', '▲'].map(
                      (s) => IconButton(
                        tooltip: '$s 도장',
                        onPressed: () => setState(() {
                          stamp = s;
                          eraser = false;
                        }),
                        icon: Text(s),
                      ),
                    ),
                ],
              ),
              if (older)
                Wrap(
                  spacing: 8,
                  children:
                      [
                            ('종이', 0xfffffdf7),
                            ('하늘', 0xffe0f1fa),
                            ('정원', 0xffe6f1d8),
                          ]
                          .map(
                            (b) => TextButton(
                              onPressed: () => perform(
                                () => ref
                                    .read(drawingProvider.notifier)
                                    .background(b.$2),
                              ),
                              child: Text(b.$1),
                            ),
                          )
                          .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawingCanvas extends StatefulWidget {
  final DrawingDocument document;
  final int color;
  final double width;
  final bool eraser;
  final String? stamp;
  final ValueChanged<DrawingLine> onLine;
  const DrawingCanvas({
    super.key,
    required this.document,
    required this.color,
    required this.width,
    required this.eraser,
    required this.stamp,
    required this.onLine,
  });
  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas>
    with WidgetsBindingObserver {
  List<TracePoint> points = [];
  int? pointer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) finish();
  }

  void finish() {
    if (points.isEmpty) return;
    final line = DrawingLine(
      List.from(points),
      color: widget.color,
      width: widget.width,
      eraser: widget.eraser,
      stamp: widget.stamp,
    );
    setState(() {
      points = [];
      pointer = null;
    });
    widget.onLine(line);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final size = c.biggest;
      TracePoint p(Offset o) => TracePoint(
        (o.dx / size.width).clamp(0, 1),
        (o.dy / size.height).clamp(0, 1),
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Listener(
          onPointerDown: (e) {
            if (pointer != null) return;
            setState(() {
              pointer = e.pointer;
              points = [p(e.localPosition)];
            });
          },
          onPointerMove: (e) {
            if (pointer == e.pointer && widget.stamp == null) {
              setState(() => points.add(p(e.localPosition)));
            }
          },
          onPointerUp: (e) {
            if (pointer == e.pointer) finish();
          },
          onPointerCancel: (e) {
            if (pointer == e.pointer) finish();
          },
          child: RepaintBoundary(
            child: CustomPaint(
              size: size,
              painter: DrawingPainter(
                widget.document,
                current: points.isEmpty
                    ? null
                    : DrawingLine(
                        points,
                        color: widget.color,
                        width: widget.width,
                        eraser: widget.eraser,
                        stamp: widget.stamp,
                      ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
