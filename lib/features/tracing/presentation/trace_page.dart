import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/widgets/activity_scaffold.dart';
import '../../../core/widgets/canvas_workspace.dart';
import '../data/trace_catalog.dart';
import '../data/prewriting_content.dart';
import '../../learning/domain/learning_speech.dart';
import '../../profile/presentation/profile_vm.dart';
import '../../profile/domain/settings.dart';
import '../../parent/presentation/usage_vm.dart';
import 'trace_vm.dart';
import 'trace_canvas.dart';
import 'trace_coach_bar.dart';
import '../domain/trace_coach.dart';
import '../domain/trace_engine.dart';

class TracePage extends ConsumerStatefulWidget {
  final String itemId;
  const TracePage({super.key, required this.itemId});
  @override
  ConsumerState<TracePage> createState() => _TracePageState();
}

class _TracePageState extends ConsumerState<TracePage> {
  final canvasKey = GlobalKey<TraceCanvasState>();
  final preview = ValueNotifier<TracePreview?>(null);
  @override
  void dispose() {
    preview.dispose();
    super.dispose();
  }

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
    final matches = traceItems.where(
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
    final prewriting = item.subject == 'prewriting';
    final listRoute = prewriting ? '/prewriting' : '/learn/${item.subject}';
    final settings =
        ref.watch(settingsProvider).value ?? const ParentSettings();
    if (!announced && settings.autoRead) {
      announced = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(audioProvider)
              .speak(
                learningLetterName(item),
                settings,
                language: item.language,
              );
        }
      });
    }
    return ActivityScaffold(
      title: prewriting ? '${item.name} 놀이' : '${item.symbol} 따라 그리기',
      child: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('길을 열지 못했어요: $e'),
        data: (state) => CanvasWorkspace(
          tabletSidePanel: true,
          canvas: TraceCanvas(
            key: canvasKey,
            strokes: item.strokes,
            state: state,
            strategy: prewriting
                ? PrewritingStrategy(AgeStrategy(settings.level))
                : TraceStrategy(AgeStrategy(settings.level)),
            semanticLabel: prewriting ? item.example : null,
            animate: settings.animations,
            onPreview: (value) => preview.value = value,
            onStroke: (p) => safe(
              () => ref
                  .read(traceProvider(widget.itemId).notifier)
                  .submit(p, settings.level),
            ),
          ),
          controls: Column(
            children: [
              if (prewriting)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    item.example,
                    style: const TextStyle(fontFamily: 'Jua', fontSize: 24),
                  ),
                ),
              if (MediaQuery.sizeOf(context).width >= 1000)
                Text(
                  item.symbol,
                  style: const TextStyle(
                    fontFamily: 'Jua',
                    fontSize: 64,
                    color: Color(0xff286458),
                  ),
                ),
              TraceCoachBar(
                preview: preview,
                stroke: state.strokeIndex,
                total: item.strokes.length,
                done: state.done,
                completionPrompt: prewriting
                    ? '다음 모양도 만나 볼까?'
                    : '다음 글자도 만나 볼까?',
              ),
              if (state.message.isNotEmpty)
                ValueListenableBuilder(
                  valueListenable: preview,
                  builder: (context, value, _) => ExcludeSemantics(
                    excluding: value != null,
                    child: Opacity(
                      opacity: value == null ? 1 : 0,
                      child: Text(state.message),
                    ),
                  ),
                ),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: () => canvasKey.currentState?.demonstrate(),
                    child: const Text('시범 보기'),
                  ),
                  OutlinedButton(
                    onPressed: () => safe(
                      ref.read(traceProvider(widget.itemId).notifier).reset,
                    ),
                    child: const Text('지우고 다시 하기'),
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
                                ? listRoute
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
                            : prewriting
                            ? '다음 모양'
                            : '다음 글자',
                      ),
                    ),
                  OutlinedButton(
                    onPressed: () => context.go(listRoute),
                    child: Text(prewriting ? '모양 목록' : '글자 목록'),
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
