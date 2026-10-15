import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/story/domain/story_machine.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';

void main() {
  for (var age = 2; age <= 5; age++) {
    test('all stories finish via actual alternate missions at age $age', () {
      final machine = StoryMachine();
      var s = machine.begin(age);
      var steps = 0, supports = 0;
      while (s.phase != StoryPhase.finished && steps++ < 500) {
        switch (s.phase) {
          case StoryPhase.quiz:
          case StoryPhase.tracing:
            final originalScene = machine.scene(s).id;
            s = machine.easier(s);
            expect(s.phase, StoryPhase.quiz);
            expect(s.supportSceneId, originalScene);
            expect(machine.quiz(s).options.length, 2);
            s = machine.answer(s, machine.quiz(s).answer);
            expect(s.phase, StoryPhase.success);
            supports++;
          case StoryPhase.choice:
            s = machine.choose(s, 0);
          case StoryPhase.drawing:
            s = machine.drawingComplete(s);
          default:
            s = machine.advance(s);
        }
        if (s.phase == StoryPhase.dialogue) expect(s.supportSceneId, isNull);
      }
      expect(s.phase, StoryPhase.finished);
      expect(s.completed.length, 12);
      expect(supports, greaterThan(10));
    });
  }
  test('trace alternate question resumes and returns to original without losing scene', () async {
    final machine = StoryMachine(), repo = StoryRepository(MemoryStore());
    var s = const StorySnapshot(
      episode: 1,
      scene: 4,
      level: 3,
      phase: StoryPhase.tracing,
      attempts: 3,
      flags: {'companion': '토토'},
    );
    final id = machine.scene(s).id;
    s = machine.easier(s);
    await repo.save(s);
    s = machine.restore((await repo.load())!);
    expect(machine.quiz(s).visual, 'ㅏ');
    expect(s.flags['companion'], '토토');
    final wrong = machine.quiz(s).answer == 0 ? 1 : 0;
    s = machine.answer(s, wrong);
    expect(s.phase, StoryPhase.quiz);
    final back = machine.originalMission(s);
    expect(back.phase, StoryPhase.tracing);
    expect(machine.scene(back).id, id);
    expect(back.supportSceneId, isNull);
    final success = machine.answer(s, machine.quiz(s).answer);
    final next = machine.advance(success);
    expect(next.supportSceneId, isNull);
    expect(machine.scene(next).id, isNot(id));
  });
  test('all three chapter nine routes support alternates and help settings remain enforced', () {
    final machine = StoryMachine();
    for (final route in ['한글 길', '영어 길', '숫자 길']) {
      final s = StorySnapshot(
        episode: 8,
        scene: 3,
        level: 5,
        phase: StoryPhase.quiz,
        attempts: 3,
        flags: {'route': route},
      );
      final easier = machine.easier(s);
      expect(machine.quiz(easier).subject, machine.quiz(s).subject);
      expect(
        machine.assist(easier, const ParentSettings(help: false)).phase,
        StoryPhase.quiz,
      );
      expect(
        machine.assist(easier, const ParentSettings(help: true)).assisted,
        true,
      );
    }
  });
}
