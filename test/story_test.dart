import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/story/domain/story_machine.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/features/story/data/story_content.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';

void main() {
  test('parent level change keeps the current scene or moves past unsupported activity', () {
    final machine = StoryMachine();
    final trace = StorySnapshot(
      episode: 1,
      scene: 4,
      level: 3,
      phase: StoryPhase.tracing,
      flags: {'companion': '토토'},
    );
    expect(machine.scene(trace).traceId, 'h-ㅏ');
    final next = machine.relevel(trace, 2);
    expect(next.level, 2);
    expect(next.phase, StoryPhase.dialogue);
    expect(machine.scene(next).id, 'ep2-end');
    expect(next.flags['companion'], '토토');
    final expanded = machine.relevel(trace, 5);
    expect(machine.scene(expanded).id, machine.scene(trace).id);
  });
  for (var level = 2; level <= 5; level++) {
    test('all twelve episodes complete at level $level without a dead end', () {
      final machine = StoryMachine();
      var s = machine.begin(level);
      var transitions = 0;
      while (s.phase != StoryPhase.finished && transitions++ < 500) {
        switch (s.phase) {
          case StoryPhase.dialogue:
          case StoryPhase.success:
          case StoryPhase.episodeComplete:
            s = machine.advance(s);
          case StoryPhase.choice:
            s = machine.choose(s, 0);
          case StoryPhase.quiz:
            s = machine.answer(s, machine.quiz(s).answer);
          case StoryPhase.tracing:
            final item = learningItems.firstWhere(
              (i) => i.id == machine.scene(s).traceId,
            );
            s = machine.trace(s, item.strokes[s.strokes.length].samples(80));
          case StoryPhase.drawing:
            s = machine.drawingComplete(s);
          case StoryPhase.finished:
            break;
        }
      }
      expect(s.phase, StoryPhase.finished);
      expect(s.completed, List.generate(12, (i) => i + 1));
      expect(s.flags['room'], isNotNull);
    });
  }
  test('scene count follows 4/6/8/10 and ids are unique', () {
    final ids = <String>{};
    for (final episode in storyEpisodes) {
      for (var level = 2; level <= 5; level++) {
        expect(episode.forLevel(level).length, AgeStrategy(level).sceneCount);
      }
      for (final scene in episode.scenes) {
        expect(ids.add(scene.id), true);
      }
    }
  });
  test(
    'wrong answer, hint, assist and disabled help are explicit transitions',
    () {
      final machine = StoryMachine();
      var s = machine.begin(4);
      while (s.phase != StoryPhase.quiz) {
        s = s.phase == StoryPhase.choice
            ? machine.choose(s, 0)
            : machine.advance(s);
      }
      final unchanged = machine.advance(s);
      expect(unchanged.phase, StoryPhase.quiz);
      final wrong =
          (machine.quiz(s).answer + 1) % machine.quiz(s).options.length;
      s = machine.answer(s, wrong);
      s = machine.hint(s);
      expect(s.hints, greaterThan(0));
      expect(
        machine.assist(s, const ParentSettings(helpAfter: 3)).phase,
        StoryPhase.quiz,
      );
      s = machine.answer(s, wrong);
      s = machine.answer(s, wrong);
      expect(
        machine.assist(s, const ParentSettings(help: false)).phase,
        StoryPhase.quiz,
      );
      expect(
        machine.assist(s, const ParentSettings()).phase,
        StoryPhase.success,
      );
    },
  );
  test(
    'save and restore retains choices attempts scene and stroke progress',
    () async {
      final store = MemoryStore(), machine = StoryMachine();
      var s = machine.begin(5);
      s = machine.advance(s);
      s = machine.advance(s);
      s = machine.choose(s, 1);
      s = machine.advance(s);
      s = machine.answer(s, 1);
      s = machine.hint(s);
      await StoryRepository(store).save(s);
      final restored = machine.restore((await StoryRepository(store).load())!);
      expect(restored.toJson(), s.toJson());
      expect(restored.flags['companion'], '토토');
    },
  );
  test('three routes change the review while preserving central story', () {
    final machine = StoryMachine();
    for (final route in ['한글 길', '영어 길', '숫자 길']) {
      final s = StorySnapshot(
        episode: 8,
        scene: 3,
        level: 5,
        phase: StoryPhase.quiz,
        flags: {'route': route},
      );
      expect(
        machine.quiz(s).subject,
        route == '한글 길'
            ? 'hangul'
            : route == '영어 길'
            ? 'english'
            : 'math',
      );
    }
  });
  test('two year old exploration never requires a correct choice', () {
    final machine = StoryMachine();
    var s = machine.begin(2);
    s = machine.advance(s);
    s = machine.choose(s, 0);
    s = machine.advance(s);
    expect(s.phase, StoryPhase.quiz);
    expect(machine.answer(s, 1).phase, StoryPhase.success);
  });
}
