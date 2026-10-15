import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/widgets/activity_scaffold.dart';
import '../../../core/widgets/canvas_workspace.dart';
import '../../learning/data/learning_content.dart';
import '../../profile/presentation/profile_vm.dart';
import '../../profile/domain/settings.dart';
import '../../parent/presentation/usage_vm.dart';
import 'trace_vm.dart';
import 'trace_canvas.dart';

class TracePage extends ConsumerStatefulWidget {
  final String itemId;
  const TracePage({super.key, required this.itemId});
  @override
  ConsumerState<TracePage> createState() => _TracePageState();
}

class _TracePageState extends ConsumerState<TracePage> {
  final canvasKey = GlobalKey<TraceCanvasState>();
  bool announced = false;
  @override
  void didUpdateWidget(covariant TracePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemId != widget.itemId) announced = false;
  }

  Future<void> safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('진도를 저장하지 못했어요. 다시 시도해 주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final matches = learningItems.where(
      (i) => i.id == widget.itemId && i.strokes.isNotEmpty,
    );
    if (matches.isEmpty) {
      return const ActivityScaffold(
        title: '따라 그리기',
        child: Center(child: Text('이 글자의 길은 아직 준비 중이에요.')),
      );
    }
    final item = matches.first,
        asyncState = ref.watch(traceProvider(widget.itemId));
    final settings =
        ref.watch(settingsProvider).value ?? const ParentSettings();
    if (!announced && settings.autoRead) {
      announced = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(audioProvider)
              .speak(item.name, settings, language: item.language);
        }
      });
    }
    return ActivityScaffold(
      title: '${item.symbol} 따라 그리기',
      child: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('길을 열지 못했어요: $e'),
        data: (state) => CanvasWorkspace(
          canvas: TraceCanvas(
            key: canvasKey,
            strokes: item.strokes,
            state: state,
            tolerance: AgeStrategy(settings.level).traceTolerance,
            animate: settings.animations,
            onStroke: (p) => safe(
              () => ref
                  .read(traceProvider(widget.itemId).notifier)
                  .submit(p, settings.level),
            ),
          ),
          controls: Column(
            children: [
              Text(state.message),
              Text(
                state.done
                    ? '${item.strokes.length}획을 모두 그렸어요!'
                    : '${state.strokeIndex + 1} / ${item.strokes.length}획 · 빛나는 시작점에서 출발해요',
              ),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => safe(
                      ref.read(traceProvider(widget.itemId).notifier).reset,
                    ),
                    child: const Text('지우고 다시 하기'),
                  ),
                  FilledButton(
                    onPressed: () => canvasKey.currentState?.demonstrate(),
                    child: const Text('시범 보기'),
                  ),
                  if (state.done)
                    FilledButton(
                      onPressed: () async {
                        final expired = await ref
                            .read(usageProvider.notifier)
                            .boundary();
                        if (context.mounted) {
                          final next = ref
                              .read(traceProvider(widget.itemId).notifier)
                              .nextItemId(settings.level);
                          context.go(
                            expired
                                ? '/rest'
                                : next == null
                                ? '/learn/${item.subject}'
                                : '/trace/$next',
                          );
                        }
                      },
                      child: Text(
                        ref
                                    .read(traceProvider(widget.itemId).notifier)
                                    .nextItemId(settings.level) ==
                                null
                            ? '목록으로'
                            : '다음 글자',
                      ),
                    ),
                  OutlinedButton(
                    onPressed: () => context.go('/learn/${item.subject}'),
                    child: const Text('글자 목록'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
