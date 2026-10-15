import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/learning/domain/learning_models.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/story/data/story_content.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/features/story/domain/story_machine.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';

StorySnapshot mission(int episode, String suffix, {int level = 5}) {
  final scenes = storyEpisodes[episode].forLevel(level);
  final index = scenes.indexWhere((s) => s.id == 'ep${episode + 1}-$suffix');
  return StorySnapshot(
    episode: episode,
    level: level,
    scene: index,
    phase: scenes[index].interaction,
  );
}

void main() {
  final machine = StoryMachine();
  test('garden and tree preserve every legacy scene position and trace ID', () {
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
    for (final ep in [1, 2]) {
      final episode = storyEpisodes[ep];
      expect(
        episode.scenes.map((s) => s.id),
        suffixes.map((s) => 'ep${ep + 1}-$s'),
      );
      expect(
        episode.scenes.firstWhere((s) => s.id.endsWith('-trace')).traceId,
        ep == 1 ? 'h-ㅏ' : 'h-ㄱ',
      );
      for (var level = 2; level <= 5; level++) {
        final scenes = episode.forLevel(level);
        expect(scenes.length, AgeStrategy(level).sceneCount);
        for (var index = 0; index < scenes.length; index++) {
          final legacy = StorySnapshot.fromJson({
            'episode': ep,
            'scene': index,
            'level': level,
            'phase': scenes[index].interaction.name,
            'attempts': 2,
            'flags': {'companion': '토토'},
          });
          final restored = machine.restore(legacy);
          expect(machine.scene(restored).id, scenes[index].id);
          expect(restored.flags['companion'], '토토');
          expect(restored.attempts, 2);
        }
      }
    }
    expect(storyEpisodes.length, 12);
    expect(storyEpisodes[3].scenes.first.id, 'ep4-start');
    expect(storyEpisodes[11].scenes.last.id, 'ep12-end');
  });
  test(
    'vowels, consonant names, pair and syllable have exact structured answers',
    () {
      const correct = {
        'ep2-vowel-a': [QuizGlyph.vowelA],
        'ep2-vowel-o': [QuizGlyph.vowelO],
        'ep2-vowel-pair': [QuizGlyph.vowelA, QuizGlyph.vowelO],
        'ep3-giyeok': [QuizGlyph.giyeok],
        'ep3-ga-seed': [QuizGlyph.ga],
        'ep3-seed-count': [QuizGlyph.seed, QuizGlyph.seed, QuizGlyph.seed],
      };
      final quizzes = storyEpisodes
          .skip(1)
          .take(2)
          .expand((e) => e.scenes)
          .map((s) => s.quiz)
          .whereType<QuizDefinition>();
      expect(quizzes.length, 6);
      for (final q in quizzes) {
        final art = q.artwork!;
        expect(art.choices[q.answer], correct[q.id], reason: q.id);
        expect(
          art.choices.map((c) => c.map((g) => g.name).join(',')).toSet().length,
          q.options.length,
          reason: q.id,
        );
        expect(
          machine
              .answer(
                mission(
                  q.id.startsWith('ep2') ? 1 : 2,
                  q.id.endsWith('pair') || q.id.endsWith('ga-seed')
                      ? 'together'
                      : q.id.endsWith('-o') || q.id.endsWith('count')
                      ? 'review'
                      : 'quiz',
                ),
                q.answer,
              )
              .phase,
          StoryPhase.success,
        );
      }
      expect(QuizGlyph.giyeok.label, '기역');
      expect(QuizGlyph.giyeok.symbol, 'ㄱ');
      expect(QuizGlyph.vowelA.label, '아');
      expect(QuizGlyph.ga.symbol, '가');
    },
  );
  test(
    'event background changes only after success and survives reload/help',
    () async {
      final repo = StoryRepository(MemoryStore());
      for (final ep in [1, 2]) {
        var s = mission(ep, 'quiz');
        final closed = machine.background(s),
            opened = machine.scene(s).successBackground;
        expect(opened, isNotNull);
        s = machine.answer(s, 0);
        expect(machine.background(s), closed);
        expect(machine.background(machine.hint(s)), closed);
        final success = machine.answer(s, 1);
        expect(machine.background(success), opened);
      expect(machine.narration(success), success.message);
      expect(machine.narration(s), machine.quiz(s).prompt);
        await repo.save(success);
        expect(
          machine.background(machine.restore((await repo.load())!)),
          opened,
        );
        final stuck = s.change({'attempts': 3});
        expect(
          machine.background(
            machine.assist(stuck, const ParentSettings(help: false)),
          ),
          closed,
        );
        expect(
          machine.background(machine.assist(stuck, const ParentSettings())),
          opened,
        );
        final easier = machine.easier(s);
        expect(machine.quiz(easier).subject, 'hangul');
        expect(
          machine.background(
            machine.answer(easier, machine.quiz(easier).answer),
          ),
          opened,
        );
        expect(
          machine.quiz(machine.originalMission(easier)).id,
          machine.quiz(s).id,
        );
      }
    },
  );
  test('two year olds explore without a letter gate or misleading praise', () {
    for (final ep in [1, 2]) {
      final s = mission(ep, 'quiz', level: 2);
      final q = machine.quiz(s);
      expect(machine.text(s), isNot(contains('기역')));
      expect(machine.text(s), isNot(contains('아 소리')));
      expect(machine.text(s), machine.scene(s).exploreText);
      expect(q.artwork!.objects.every((g) => g.symbol == null), true);
      for (var i = 0; i < q.options.length; i++) {
        final success = machine.answer(s, i);
        expect(success.phase, StoryPhase.success);
        expect(success.message, machine.scene(s).exploreSuccessText);
        expect(success.message, isNot(contains('기역')));
        expect(machine.background(success), machine.scene(s).successBackground);
      }
    }
  });
  test(
    'seed counting stores order, excludes duplicates and names seeds',
    () async {
      final repo = StoryRepository(MemoryStore());
      var s = mission(2, 'review');
      s = machine.observeObject(s, 1);
      expect(s.message, contains('씨앗'));
      s = machine.observeObject(s, 1);
      s = machine.observeObject(s, 0);
      await repo.save(s);
      s = machine.restore((await repo.load())!);
      expect(s.observedObjects, [1, 0]);
      expect(machine.observeObject(s, 2).message, contains('모두 3개'));
      expect(machine.answer(s, 0).phase, StoryPhase.quiz);
      expect(machine.answer(s, 1).phase, StoryPhase.success);
      expect(machine.advance(machine.answer(s, 1)).observedObjects, isEmpty);
      expect(machine.relevel(s, 2).observedObjects, isEmpty);
    },
  );
}
