import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../parent/presentation/usage_vm.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/audio/sound_effects.dart';
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
import '../../tracing/domain/trace_engine.dart';
import '../../tracing/domain/trace_coach.dart';
import '../../tracing/presentation/trace_coach_bar.dart';
import '../domain/story_models.dart';
import '../domain/story_cues.dart';
import '../domain/scene_play.dart';
import 'story_illustration.dart';
import '../../../core/widgets/success_feedback.dart';
import 'story_page_turn.dart';
import 'story_picture_quiz.dart';
import 'story_vm.dart';

class StoryPage extends ConsumerStatefulWidget {
  const StoryPage({super.key});
  @override
  ConsumerState<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends ConsumerState<StoryPage>
    with WidgetsBindingObserver {
  String? lastRead;
  bool active = true;
  int gardenColor = 0xffe9a845;
  bool gardenEraser = false;
  final tracePreview = ValueNotifier<TracePreview?>(null);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    tracePreview.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mounted) setState(() => active = state == AppLifecycleState.resumed);
  }

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
    ref.listen(storyProvider, (previous, next) {
      final after = next.asData?.value;
      if (after == null || !active) return;
      final cue = StoryCues.between(previous?.asData?.value, after);
      final before = previous?.asData?.value;
      final parent = ref.read(settingsProvider).asData?.value;
      final play = ScenePlay.forSnapshot(after);
      if (before != null &&
          parent != null &&
          parent.autoRead &&
          parent.voiceVolume > 0 &&
          play != null &&
          StoryCues.pageId(before) == StoryCues.pageId(after) &&
          before.sceneFinds.length < play.count(after.level) &&
          after.sceneFinds.length == play.count(after.level)) {
        ref
            .read(audioProvider)
            .speak(
              play.response,
              parent,
              recordingId: 'voice-scene-play-${after.episode + 1}-response',
            );
      }
      if (before != null &&
          parent != null &&
          parent.voiceVolume > 0 &&
          before.observedObjects.length < after.observedObjects.length) {
        ref
            .read(audioProvider)
            .speak(
              '${after.observedObjects.length}개',
              parent,
              recordingId: 'voice-count-${after.observedObjects.length}',
            );
      }
      if (cue != null) {
        final volume =
            ref.read(settingsProvider).asData?.value.effectsVolume ?? 0;
        ref.read(effectsProvider).play(cue, volume);
      }
    });
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
        final readKey =
            '${scene.id}-${s.phase.name}-${s.supportSceneId}-${vm.machine.quest(s).hasFragment}';
        if (lastRead != readKey && settings.autoRead) {
          lastRead = readKey;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                active &&
                ref.read(storyProvider).asData?.value == s) {
              ref
                  .read(audioProvider)
                  .speak(
                    vm.machine.narration(s),
                    settings,
                    recordingId: vm.machine.narrationId(s),
                  );
            }
          });
        }
        return ActivityScaffold(
          title: '${episode.id}화: ${episode.title}',
          actions: [
            Chip(
              key: const ValueKey('story-fragment-total'),
              avatar: const Icon(Icons.star_rounded, color: Color(0xffb58421)),
              label: Text('별조각 ${vm.machine.quest(s).collected.length} / 12'),
            ),
            IconButton(
              tooltip: '대사 다시 듣기',
              onPressed: () => ref
                  .read(audioProvider)
                  .speak(
                    vm.machine.narration(s),
                    settings,
                    recordingId: vm.machine.narrationId(s),
                  ),
              icon: const Icon(Icons.volume_up),
            ),
          ],
          child: TickerMode(
            enabled: active,
            child: StoryPageTurn(
              pageId: StoryCues.pageId(s),
              animate:
                  settings.animations &&
                  !MediaQuery.disableAnimationsOf(context),
              child: LayoutBuilder(
                builder: (context, c) {
                  if (s.pendingDrawing != null &&
                      s.phase == StoryPhase.drawing) {
                    return Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.save_rounded, size: 64),
                              const SizedBox(height: 16),
                              const Text(
                                '그림을 저장하고 있어요.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 26),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '잠시 기다려요.\n멈췄다면 아래 버튼을 눌러요.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              FilledButton(
                                key: const ValueKey('garden-retry-save'),
                                onPressed: () => safe(vm.saveGardenDrawing),
                                child: const Text('이어서 저장하기'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  final letter = vm.machine.letterMission(s);
                  final book = vm.machine.bookMission(s);
                  if (s.phase == StoryPhase.tracing ||
                      ((letter?.tracing == true || book?.tracing == true) &&
                          s.phase == StoryPhase.success)) {
                    final item = learningItems.firstWhere(
                      (i) => i.id == scene.traceId,
                    );
                    return CanvasWorkspace(
                      tabletSidePanel: true,
                      canvas: TraceCanvas(
                        key: traceKey,
                        strokes: item.strokes,
                        state: TraceState(
                          strokeIndex: s.strokes.length,
                          completed: s.strokes,
                          done: s.phase == StoryPhase.success,
                        ),
                        animate: settings.animations,
                        onPreview: (value) => tracePreview.value = value,
                        strategy: TraceStrategy(
                          AgeStrategy(s.hints >= 3 ? 2 : s.level),
                        ),
                        onStroke: (p) => safe(() => vm.trace(p)),
                      ),
                      controls: Column(
                        children: [
                          Text(
                            s.phase == StoryPhase.success
                                ? vm.machine.text(s)
                                : letter?.purpose ??
                                      book?.purpose ??
                                      scene.text,
                            style: const TextStyle(
                              fontFamily: 'Jua',
                              fontSize: 23,
                            ),
                          ),
                          if (s.phase == StoryPhase.success)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: FilledButton.icon(
                                onPressed: nextScene,
                                icon: const Icon(Icons.auto_stories_rounded),
                                label: const Text('다음 이야기'),
                              ),
                            ),
                          ...[
                            const SizedBox(height: 12),
                            AspectRatio(
                              aspectRatio: 1.65,
                              child: StoryIllustration(
                                key: ValueKey('trace-world-${scene.id}'),
                                background: vm.machine.background(s),
                                character: scene.character,
                                companion: s.flags['companion'] ?? '루루',
                                animate: settings.animations,
                                active: active,
                                reactionId: '${scene.id}-${s.phase}',
                                celebrate: s.phase == StoryPhase.success,
                                letterMission: letter,
                                bookMission: book,
                                quest: vm.machine.quest(s),
                                onCollect: () => safe(vm.collectFragment),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          TraceCoachBar(
                            preview: tracePreview,
                            stroke: s.strokes.length,
                            total: item.strokes.length,
                            done: s.phase == StoryPhase.success,
                          ),
                          ..._speechButtons(vm, s),
                          if (s.phase != StoryPhase.success) Text(s.message),
                          if (s.phase != StoryPhase.success)
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
                    quest: vm.machine.quest(s),
                    onCollect: () => safe(vm.collectFragment),
                    background: vm.machine.background(s),
                    character: scene.character,
                    animate: settings.animations,
                    companion: s.flags['companion'] ?? '루루',
                    reactionId:
                        '${scene.id}-${s.phase.name}-${s.message}-${s.sceneFinds.length}',
                    reaction:
                        s.phase == StoryPhase.success ||
                            s.phase == StoryPhase.episodeComplete
                        ? StoryReaction.celebrate
                        : scene.reaction,
                    celebrate:
                        s.phase == StoryPhase.success ||
                        s.phase == StoryPhase.episodeComplete ||
                        (ScenePlay.forSnapshot(s) != null &&
                            s.sceneFinds.length ==
                                ScenePlay.forSnapshot(s)!.count(s.level)),
                    scenePlay: ScenePlay.forSnapshot(s),
                    playCount: ScenePlay.forSnapshot(s)?.count(s.level) ?? 0,
                    sceneFinds: s.sceneFinds,
                    active: active,
                    letterMission: letter,
                    bookMission: book,
                    gardenMap:
                        episode.id == 7 &&
                            book == null &&
                            ((scene.interaction == StoryPhase.drawing &&
                                    s.phase == StoryPhase.success) ||
                                scene.id == 'ep7-talk' ||
                                scene.id == 'ep7-end')
                        ? ref
                              .watch(storyGardenMapProvider)
                              .asData
                              ?.value
                              ?.document
                        : null,
                    onObserve: (i) => safe(() => vm.observeObject(i)),
                    onChoose: (i) => safe(() => vm.answer(i)),
                    worldMission: vm.machine.worldMission(s),
                    missionPlaced: s.observedObjects,
                    missionSolved: s.phase == StoryPhase.success,
                    onPlace: (piece, slot) =>
                        safe(() => vm.placeObject(piece, slot)),
                    onDiscover: (i) => safe(() => vm.discoverSceneProp(i)),
                    onCharacterTap: () => ref
                        .read(effectsProvider)
                        .play(StorySound.friend, settings.effectsVolume),
                  );
                  final controls = _controls(vm, s, settings);
                  return _StoryBookStage(
                    picture: GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if ((details.primaryVelocity ?? 0) < -350 &&
                            [
                              StoryPhase.dialogue,
                              StoryPhase.success,
                              StoryPhase.episodeComplete,
                            ].contains(s.phase)) {
                          nextScene();
                        }
                      },
                      child: picture,
                    ),
                    controls: controls,
                    chapter: episode.id,
                    scene: s.scene,
                    sceneCount: episode.forLevel(s.level).length,
                    goal: episode.goal,
                    mission:
                        vm.machine.worldMission(s) != null ||
                        letter != null ||
                        book != null,
                  );
                },
              ),
            ),
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
        vm.machine.text(s),
        style: const TextStyle(
          fontSize: 25,
          height: 1.55,
          fontFamily: 'Jua',
          fontWeight: FontWeight.w400,
          color: Color(0xff283b49),
        ),
      ),
      const SizedBox(height: 18),
      if (s.phase == StoryPhase.success)
        SuccessFeedback(
          title: s.assisted ? '함께 해냈어요!' : '해냈어요!',
          message: vm.machine.quest(s).ready && !vm.machine.quest(s).hasFragment
              ? '오른쪽에 나타난 별조각을 눌러 책에 담아 줘요.'
              : '그림 속에서 우리가 바꾼 모습을 찾아봐요.',
        ),
      if (ScenePlay.forSnapshot(s) case final play?) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xffe5f2e9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.sceneFinds.length == play.count(s.level)
                    ? '함께 찾았어! 다음 이야기가 기다려.'
                    : play.invitation,
                style: const TextStyle(
                  fontFamily: 'Jua',
                  fontSize: 21,
                  color: Color(0xff286458),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var i = 0; i < play.count(s.level); i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        s.sceneFinds.contains(i)
                            ? Icons.stars_rounded
                            : Icons.star_outline_rounded,
                        color: const Color(0xff99712d),
                        size: 28,
                      ),
                    ),
                  Text(
                    '${s.sceneFinds.length} / ${play.count(s.level)}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
      ..._speechButtons(vm, s),
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
        if (vm.machine.quiz(s).artwork != null)
          StoryPictureQuiz(
            sceneChoices:
                vm.machine.letterMission(s) != null ||
                vm.machine.bookMission(s) != null,
            sceneInstruction: vm.machine.bookMission(s) != null
                ? '그림 속 소품을 눌러 골라요.'
                : '그림 속 글자를 눌러요.',
            worldPlacement: vm.machine.worldMission(s) != null,
            answerEnabled: vm.machine.canAnswer(s),
            quiz: vm.machine.quiz(s),
            observed: s.observedObjects,
            hints: s.hints,
            animate: settings.animations,
            onAnswer: (i) => safe(() => vm.answer(i)),
            onObserve: (i) => safe(() => vm.observeObject(i)),
            onPlace: (piece, slot) => safe(() => vm.placeObject(piece, slot)),
          )
        else ...[
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
                  backgroundColor: s.hints >= 2 && vm.machine.quiz(s).accepts(i)
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
        ],
        Wrap(spacing: 12, runSpacing: 12, children: _support(vm, s, settings)),
      ],
      if (s.message.isNotEmpty &&
          s.phase != StoryPhase.success &&
          vm.machine.text(s) != s.message)
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
        if (vm.machine.quest(s).ready && !vm.machine.quest(s).hasFragment)
          FilledButton.icon(
            onPressed: () => safe(vm.collectFragment),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('별조각 담기'),
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
          '12칸이 모두 채워졌어요.\n내 작품 · 모험 지도에서 우리가 만든 길을 다시 볼 수 있어요.',
          style: TextStyle(fontSize: 26),
        ),
    ];
  }

  List<Widget> _speechButtons(StoryVM vm, StorySnapshot snapshot) {
    final samples = vm.machine.speeches(snapshot);
    return samples.isEmpty
        ? []
        : [
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                for (var i = 0; i < samples.length; i++)
                  OutlinedButton.icon(
                    key: ValueKey('story-speech-${samples[i].id}'),
                    onPressed: () => vm.listenTo(i),
                    icon: const Icon(Icons.volume_up_rounded),
                    label: Text(samples[i].label),
                  ),
              ],
            ),
            const SizedBox(height: 18),
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
        if (s.attempts >= 2 ||
            (s.phase == StoryPhase.quiz && !vm.machine.canAnswer(s)))
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
      .watch(storyDrawingProvider)
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('그림을 열지 못했어요: $e'),
        data: (h) => CanvasWorkspace(
          canvas: DrawingCanvas(
            document: h.current,
            color: gardenColor,
            width: .018,
            eraser: gardenEraser,
            stamp: null,
            onLine: (DrawingLine l) =>
                safe(() => ref.read(storyDrawingProvider.notifier).add(l)),
          ),
          controls: Column(
            children: [
              Text(text),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in [
                    0xff376e64,
                    0xffe76f51,
                    0xffe9b331,
                    0xff4289b5,
                    0xff8648a6,
                    0xff252d35,
                  ].indexed)
                    IconButton.filledTonal(
                      key: ValueKey('garden-color-${entry.$1}'),
                      tooltip: ['초록', '빨강', '노랑', '파랑', '보라', '검정'][entry.$1],
                      onPressed: () => setState(() {
                        gardenColor = entry.$2;
                        gardenEraser = false;
                      }),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(52, 52),
                      ),
                      icon: Icon(
                        gardenColor == entry.$2 && !gardenEraser
                            ? Icons.check_circle
                            : Icons.circle,
                        color: Color(entry.$2),
                      ),
                    ),
                  OutlinedButton(
                    onPressed: () =>
                        setState(() => gardenEraser = !gardenEraser),
                    child: Text(gardenEraser ? '붓으로' : '지우개'),
                  ),
                  OutlinedButton(
                    key: const ValueKey('garden-undo'),
                    onPressed: h.past.isEmpty
                        ? null
                        : () => safe(
                            ref.read(storyDrawingProvider.notifier).undo,
                          ),
                    child: const Text('되돌리기'),
                  ),
                  OutlinedButton(
                    key: const ValueKey('garden-redo'),
                    onPressed: h.future.isEmpty
                        ? null
                        : () => safe(
                            ref.read(storyDrawingProvider.notifier).redo,
                          ),
                    child: const Text('다시 살리기'),
                  ),
                ],
              ),
              FilledButton(
                key: const ValueKey('garden-save'),
                onPressed: h.current.lines.isEmpty
                    ? null
                    : () => safe(vm.saveGardenDrawing),
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
  final bool mission;
  const _StoryBookStage({
    required this.picture,
    required this.controls,
    required this.chapter,
    required this.scene,
    required this.sceneCount,
    required this.goal,
    this.mission = false,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final wide =
          c.maxWidth >= 700 &&
          c.maxHeight >= 400 &&
          c.maxWidth > c.maxHeight * 1.15;
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
              ? _BookScroll(children: children)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
        );
      }

      final illustrated = picture;
      if (wide) {
        return Column(
          children: [
            heading,
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 8, child: illustrated),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 5,
                    child: Align(
                      alignment: Alignment.center,
                      child: page(scroll: true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }
      return _BookScroll(
        children: [
          heading,
          if (mission)
            SizedBox(height: 300, child: illustrated)
          else if (c.maxHeight < 400)
            SizedBox(height: c.maxHeight * .70, child: illustrated)
          else
            AspectRatio(aspectRatio: 1.45, child: illustrated),
          const SizedBox(height: 14),
          page(scroll: false),
        ],
      );
    },
  );
}

class _BookScroll extends StatefulWidget {
  final List<Widget> children;
  const _BookScroll({required this.children});
  @override
  State<_BookScroll> createState() => _BookScrollState();
}

class _BookScrollState extends State<_BookScroll> {
  final controller = ScrollController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
    controller: controller,
    thumbVisibility: true,
    child: SingleChildScrollView(
      controller: controller,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widget.children,
      ),
    ),
  );
}
