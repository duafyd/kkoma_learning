import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../parent/presentation/usage_vm.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/widgets/activity_scaffold.dart';
import '../../drawing/domain/drawing.dart';
import '../../drawing/presentation/drawing_page.dart';
import '../../drawing/presentation/drawing_vm.dart';
import '../../learning/data/learning_content.dart';
import '../../profile/domain/settings.dart';
import '../../profile/presentation/profile_vm.dart';
import '../../tracing/presentation/trace_canvas.dart';
import '../../tracing/presentation/trace_vm.dart';
import '../domain/story_models.dart';
import 'story_illustration.dart';
import 'story_vm.dart';

class StoryPage extends ConsumerStatefulWidget {
  const StoryPage({super.key});
  @override
  ConsumerState<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends ConsumerState<StoryPage> {
  String? lastRead;
  final traceKey = GlobalKey<TraceCanvasState>();
  Future<void> safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('진도를 저장하지 못했어요. 다시 눌러 주세요.')),
        );
      }
    }
  }

  Future<void> nextScene() async {
    await safe(ref.read(storyProvider.notifier).advance);
    final expired = await ref.read(usageProvider.notifier).boundary();
    if (mounted && expired) context.go('/rest');
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(storyProvider),
        vm = ref.read(storyProvider.notifier);
    final settings =
        ref.watch(settingsProvider).value ?? const ParentSettings();
    return snapshot.when(
      loading: () => const ActivityScaffold(
        title: '별빛 도서관',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => ActivityScaffold(
        title: '별빛 도서관',
        child: Column(
          children: [
            Text('이야기를 열지 못했어요: $e'),
            FilledButton(
              onPressed: () => ref.invalidate(storyProvider),
              child: const Text('다시 열기'),
            ),
          ],
        ),
      ),
      data: (s) {
        final episode = vm.machine.episodes[s.episode],
            scene = vm.machine.scene(s);
        final readKey = '${scene.id}-${s.phase.name}';
        if (lastRead != readKey && settings.autoRead) {
          lastRead = readKey;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref
                  .read(audioProvider)
                  .speak(
                    s.phase == StoryPhase.success ? s.message : scene.text,
                    settings,
                  );
            }
          });
        }
        return ActivityScaffold(
          title: '${episode.id}화 · ${episode.title}',
          actions: [
            IconButton(
              tooltip: '대사 다시 듣기',
              onPressed: () =>
                  ref.read(audioProvider).speak(scene.text, settings),
              icon: const Icon(Icons.volume_up),
            ),
          ],
          child: LayoutBuilder(
            builder: (context, c) {
              if (s.phase == StoryPhase.tracing) {
                final item = learningItems.firstWhere(
                  (i) => i.id == scene.traceId,
                );
                return Column(
                  children: [
                    Text(scene.text),
                    Text(s.message),
                    Expanded(
                      child: TraceCanvas(
                        key: traceKey,
                        strokes: item.strokes,
                        state: TraceState(
                          strokeIndex: s.strokes.length,
                          completed: s.strokes,
                        ),
                        animate: settings.animations,
                        tolerance: AgeStrategy(s.hints >= 3 ? 2 : s.level)
                            .traceTolerance,
                        onStroke: (p) => safe(() => vm.trace(p)),
                      ),
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => traceKey.currentState?.demonstrate(),
                          child: const Text('시범 보기'),
                        ),
                        OutlinedButton(
                          onPressed: () => safe(vm.resetStrokes),
                          child: const Text('다시 그리기'),
                        ),
                        ..._support(vm, s, settings),
                      ],
                    ),
                  ],
                );
              }
              if (s.phase == StoryPhase.drawing) {
                return _drawing(vm, scene.text);
              }
              final picture = StoryIllustration(
                background: scene.background,
                character: scene.character,
                animate: settings.animations,
                companion: s.flags['companion'] ?? '루루',
              );
              final controls = _controls(vm, s, settings);
              if (c.maxWidth >= 850) {
                return Row(
                  children: [
                    Expanded(flex: 5, child: picture),
                    const SizedBox(width: 24),
                    Expanded(flex: 4, child: ListView(children: controls)),
                  ],
                );
              }
              return ListView(
                children: [
                  SizedBox(height: c.maxHeight * .35, child: picture),
                  const SizedBox(height: 18),
                  ...controls,
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _controls(StoryVM vm, StorySnapshot s, ParentSettings settings) {
    final scene = vm.machine.scene(s);
    return [
      Text(scene.character, style: Theme.of(context).textTheme.titleLarge),
      Text(scene.text, style: const TextStyle(fontSize: 26)),
      const SizedBox(height: 18),
      if (s.phase == StoryPhase.choice)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(
            scene.choices.length,
            (i) => FilledButton(
              onPressed: () => safe(() => vm.choose(i)),
              child: Text(scene.choices[i]),
            ),
          ),
        ),
      if (s.phase == StoryPhase.quiz) ...[
        Text(vm.machine.quiz(s).prompt, style: const TextStyle(fontSize: 26)),
        Text(
          vm.machine.quiz(s).visual,
          style: const TextStyle(fontSize: 44),
          textAlign: TextAlign.center,
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: List.generate(
            vm.machine.quiz(s).options.length,
            (i) => FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: s.hints >= 2 && i == vm.machine.quiz(s).answer
                    ? const Color(0xffc69430)
                    : null,
              ),
              onPressed: () => safe(() => vm.answer(i)),
              child: Text(
                vm.machine.quiz(s).options[i],
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
        ),
        Wrap(spacing: 12, runSpacing: 12, children: _support(vm, s, settings)),
      ],
      if (s.message.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Text(s.message),
        ),
      if ([
        StoryPhase.dialogue,
        StoryPhase.success,
        StoryPhase.episodeComplete,
      ].contains(s.phase))
        FilledButton(
          onPressed: nextScene,
          child: Text(
            s.phase == StoryPhase.episodeComplete ? '다음 모험' : '다음 장면',
          ),
        ),
      if (s.phase == StoryPhase.finished)
        const Text(
          '⭐ 12개의 별빛을 모두 모았어요!\n내 작품 · 모험 지도에서 다시 볼 수 있어요.',
          style: TextStyle(fontSize: 26),
        ),
    ];
  }

  List<Widget> _support(StoryVM vm, StorySnapshot s, ParentSettings settings) =>
      [
        OutlinedButton(onPressed: () => safe(vm.hint), child: const Text('힌트')),
        if (s.attempts >= 2)
          OutlinedButton(
            onPressed: () => safe(vm.easier),
            child: const Text('함께 쉬운 길로'),
          ),
        if (settings.help && s.attempts >= settings.helpAfter)
          FilledButton(
            onPressed: () => safe(vm.assist),
            child: const Text('친구와 함께 통과'),
          ),
      ];
  Widget _drawing(StoryVM vm, String text) => ref
      .watch(drawingProvider)
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('그림을 열지 못했어요: $e'),
        data: (h) => Column(
          children: [
            Text(text),
            Expanded(
              child: DrawingCanvas(
                document: h.current,
                color: 0xffe9a845,
                width: .018,
                eraser: false,
                stamp: null,
                onLine: (DrawingLine l) =>
                    safe(() => ref.read(drawingProvider.notifier).add(l)),
              ),
            ),
            FilledButton(
              onPressed: h.current.lines.isEmpty
                  ? null
                  : () => safe(() async {
                      await ref.read(drawingProvider.notifier).save();
                      await ref.read(galleryProvider.notifier).refresh();
                      await vm.drawingComplete();
                    }),
              child: const Text('정원 그림 저장하고 계속'),
            ),
          ],
        ),
      );
}
