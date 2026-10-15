import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/learning/domain/learning_models.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/story/data/story_content.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/features/story/domain/story_machine.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';

StorySnapshot trainMission(int ep, String suffix, {int level = 5}) {
  final scenes = storyEpisodes[ep].forLevel(level);
  final index = scenes.indexWhere((s) => s.id == 'ep${ep + 1}-$suffix');
  return StorySnapshot(
    episode: ep,
    scene: index,
    level: level,
    phase: scenes[index].interaction,
  );
}

void main() {
  final machine = StoryMachine();
  test(
    'chapters four and five keep legacy positions, trace and all age paths',
    () {
      const suffixes = [
        'start',
        'discover',
        'choice',
        'quiz',
        'clue',
        'trace',
        'review',
        'talk',
        'together',
        'end',
      ];
      for (final ep in [3, 4]) {
        final episode = storyEpisodes[ep];
        expect(
          episode.scenes.map((s) => s.id),
          suffixes.map((s) => 'ep${ep + 1}-$s'),
        );
        expect(episode.scenes[5].traceId, ep == 3 ? 'h-ㄴ' : 'e-A');
        for (var level = 2; level <= 5; level++) {
          final scenes = episode.forLevel(level);
          expect(scenes.length, AgeStrategy(level).sceneCount);
          for (var index = 0; index < scenes.length; index++) {
            final legacy = StorySnapshot.fromJson({
              'episode': ep,
              'scene': index,
              'level': level,
              'phase': scenes[index].interaction.name,
              'flags': {'companion': '토토'},
              'hints': 2,
            });
            final restored = machine.restore(legacy);
            expect(machine.scene(restored).id, scenes[index].id);
            expect(restored.flags['companion'], '토토');
            expect(restored.hints, 2);
          }
        }
      }
      expect(storyEpisodes.length, 12);
      expect(storyEpisodes[5].title, '숫자 다리와 세 개의 돌');
      expect(storyEpisodes[8].scenes[2].flag, 'route');
    },
  );
  test('syllable, order, letter name, case and fruit each have unique exact answer', () {
    const expected = {
      'ep4-ga-car': [QuizGlyph.ga],
      'ep4-na-car': [QuizGlyph.na],
      'ep4-car-order': [QuizGlyph.ga, QuizGlyph.na],
      'ep5-a-name': [QuizGlyph.latinA],
      'ep5-a-case': [QuizGlyph.lowerA],
      'ep5-apple-picture': [QuizGlyph.apple],
    };
    final qs = storyEpisodes
        .skip(3)
        .take(2)
        .expand((e) => e.scenes)
        .map((s) => s.quiz)
        .whereType<QuizDefinition>();
    expect(qs.length, 6);
    for (final q in qs) {
      final art = q.artwork!;
      expect(art.choices[q.answer], expected[q.id], reason: q.id);
      expect(
        art.choices.map((c) => c.map((g) => g.name).join(',')).toSet().length,
        q.options.length,
      );
      expect(q.options.toSet().length, q.options.length);
    }
    expect(QuizGlyph.latinA.label, '에이');
    expect(QuizGlyph.latinA.symbol, 'A');
    expect(QuizGlyph.lowerA.symbol, 'a');
    expect(QuizGlyph.apple.symbol, isNull);
  });
  test(
    'cargo and lighthouse change only after committed success and restore/help',
    () async {
      final repo = StoryRepository(MemoryStore());
      for (final ep in [3, 4]) {
        final s = trainMission(ep, 'quiz');
        final waiting = machine.background(s),
            ready = machine.scene(s).successBackground;
        final wrong = machine.answer(s, 0);
        expect(machine.background(wrong), waiting);
        final solved = machine.answer(wrong, 1);
        expect(machine.background(solved), ready);
        expect(machine.narration(solved), solved.message);
        await repo.save(solved);
        expect(
          machine.background(machine.restore((await repo.load())!)),
          ready,
        );
        final stuck = wrong.change({'attempts': 3});
        expect(
          machine.background(
            machine.assist(stuck, const ParentSettings(help: false)),
          ),
          waiting,
        );
        expect(
          machine.background(machine.assist(stuck, const ParentSettings())),
          ready,
        );
        final easier = machine.easier(wrong);
        expect(machine.quiz(easier).subject, ep == 3 ? 'hangul' : 'english');
        expect(
          machine.background(
            machine.answer(easier, machine.quiz(easier).answer),
          ),
          ready,
        );
      }
    },
  );
  test('age two uses concrete exploration and either choice progresses', () {
    for (final ep in [3, 4]) {
      final s = trainMission(ep, 'quiz', level: 2),
          q = machine.quiz(trainMission(ep, 'quiz', level: 2));
      expect(q.artwork!.objects.every((g) => g.symbol == null), true);
      expect(machine.text(s), machine.scene(s).exploreText);
      for (var i = 0; i < q.options.length; i++) {
        final next = machine.answer(s, i);
        expect(next.phase, StoryPhase.success);
        expect(next.message, machine.scene(s).exploreSuccessText);
      }
    }
  });
  test('English letter-name and word samples are separate utterances and languages', () {
    final scene = machine.scene(trainMission(4, 'quiz'));
    expect(scene.speeches.map((s) => s.id).toSet().length, 2);
    expect(scene.speeches.map((s) => s.text), ['A', 'Apple']);
    expect(scene.speeches.every((s) => s.language == 'en-US'), true);
    expect(scene.speeches[0].label, contains('이름'));
    expect(scene.speeches[1].label, contains('단어'));
    expect(machine.scene(trainMission(4, 'trace')).speeches, scene.speeches);
    expect(
      machine
          .scene(trainMission(3, 'quiz'))
          .speeches
          .map((s) => s.language)
          .toSet(),
      {'ko-KR'},
    );
  });
}
