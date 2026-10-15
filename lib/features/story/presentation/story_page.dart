import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../parent/presentation/usage_vm.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/widgets/activity_scaffold.dart';
import '../../../core/widgets/canvas_workspace.dart';
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
        final readKey = '${scene.id}-${s.phase.name}-${s.supportSceneId}';
        if (lastRead != readKey && settings.autoRead) {
          lastRead = readKey;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref
                  .read(audioProvider)
                  .speak(
                    s.phase == StoryPhase.success
                        ? s.message
                        : s.phase == StoryPhase.quiz
                        ? vm.machine.quiz(s).prompt
                        : scene.text,
                    settings,
                  );
            }
          });
        }
        return ActivityScaffold(
          title: '${episode.id}화: ${episode.title}',
          actions: [
            IconButton(
              tooltip: '대사 다시 듣기',
              onPressed: () => ref
                  .read(audioProvider)
                  .speak(
                    s.phase == StoryPhase.quiz
                        ? vm.machine.quiz(s).prompt
                        : scene.text,
                    settings,
                  ),
              icon: const Icon(Icons.volume_up),
            ),
          ],
          child: LayoutBuilder(
            builder: (context, c) {
              if (s.phase == StoryPhase.tracing) {
                final item = learningItems.firstWhere(
                  (i) => i.id == scene.traceId,
                );
                return CanvasWorkspace(
                  canvas: TraceCanvas(
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
                  controls: Column(
                    children: [
                      Text(scene.text),
                      Text(s.message),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () =>
                                traceKey.currentState?.demonstrate(),
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
                  ),
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
              return _StoryBookStage(
                picture: picture,
                controls: controls,
                chapter: episode.id,
                scene: s.scene,
                sceneCount: episode.forLevel(s.level).length,
                goal: episode.goal,
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
      Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xfff5dfac),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            scene.character,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xff61452f),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        scene.text,
        style: const TextStyle(
          fontSize: 25,
          height: 1.55,
          fontWeight: FontWeight.w600,
          color: Color(0xff3d493d),
        ),
      ),
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
        Semantics(
          liveRegion: true,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 18),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xffffedbe),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  s.phase == StoryPhase.success ||
                          s.phase == StoryPhase.episodeComplete
                      ? Icons.stars_rounded
                      : Icons.lightbulb_rounded,
                  color: const Color(0xffaa7829),
                  size: 30,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(s.message)),
              ],
            ),
          ),
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
        if (s.supportSceneId == vm.machine.scene(s).id)
          OutlinedButton(
            onPressed: () => safe(vm.originalMission),
            child: const Text('원래 미션'),
          ),
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
        data: (h) => CanvasWorkspace(
          canvas: DrawingCanvas(
            document: h.current,
            color: 0xffe9a845,
            width: .018,
            eraser: false,
            stamp: null,
            onLine: (DrawingLine l) =>
                safe(() => ref.read(drawingProvider.notifier).add(l)),
          ),
          controls: Column(
            children: [
              Text(text),
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
        ),
      );
}

class _StoryBookStage extends StatelessWidget {
  final Widget picture;
  final List<Widget> controls;
  final int chapter, scene, sceneCount;
  final String goal;
  const _StoryBookStage({
    required this.picture,
    required this.controls,
    required this.chapter,
    required this.scene,
    required this.sceneCount,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final wide = c.maxWidth >= 700 && c.maxWidth > c.maxHeight * 1.15;
      final heading = Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 14),
        child: Row(
          children: [
            const Icon(Icons.auto_stories_rounded, color: Color(0xffbc8b36)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '별빛 모험 $chapter / 12',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
            ),
            Text(
              '${scene + 1} / $sceneCount',
              style: const TextStyle(fontSize: 17),
            ),
          ],
        ),
      );
      Widget page({required bool scroll}) {
        final children = [
          Text(
            goal,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xff797e68),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ...controls,
          const SizedBox(height: 8),
        ];
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xfffffcf2),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xffeadfc4), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x153e3424),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: scroll
              ? ListView(children: children)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
        );
      }

      final illustrated = Stack(
        fit: StackFit.expand,
        children: [
          picture,
          Positioned(
            left: 16,
            top: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xeefdf6df),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(
                  '별빛 도서관과 사라진 이야기',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff634b33),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
      if (wide) {
        return Column(
          children: [
            heading,
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 7, child: illustrated),
                  const SizedBox(width: 18),
                  Expanded(flex: 5, child: page(scroll: true)),
                ],
              ),
            ),
          ],
        );
      }
      return ListView(
        children: [
          heading,
          AspectRatio(aspectRatio: 1.45, child: illustrated),
          const SizedBox(height: 14),
          page(scroll: false),
        ],
      );
    },
  );
}
