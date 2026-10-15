import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/learning/domain/learning_models.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/story/data/story_content.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/features/story/domain/story_machine.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';

StorySnapshot finaleScene(
  int episode,
  String suffix, {
  int level = 5,
  Map<String, String> flags = const {},
}) {
  final scenes = storyEpisodes[episode - 1].forLevel(level);
  final index = scenes.indexWhere((s) => s.id == 'ep$episode-$suffix');
  return StorySnapshot(
    episode: episode - 1,
    scene: index,
    level: level,
    phase: scenes[index].interaction,
    flags: flags,
  );
}

void main() {
  final machine = StoryMachine();
  test('all seven authored chapters preserve legacy scenes and tracing IDs at every age', () {
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
    const traces = ['n-3', 'h-ㅗ', 'e-C', 'h-ㅏ', 'e-A', 'n-2', 'h-ㅜ'];
    for (var ep = 6; ep <= 12; ep++) {
      final episode = storyEpisodes[ep - 1];
      expect(episode.scenes.map((s) => s.id), suffixes.map((s) => 'ep$ep-$s'));
      expect(episode.scenes[5].traceId, traces[ep - 6]);
      for (var level = 2; level <= 5; level++) {
        final scenes = episode.forLevel(level);
        expect(scenes.length, AgeStrategy(level).sceneCount);
        for (var i = 0; i < scenes.length; i++) {
          final old = StorySnapshot(
            episode: ep - 1,
            scene: i,
            level: level,
            phase: scenes[i].interaction,
            flags: {'route': '영어 길', 'room': '꽃 방'},
            hints: 2,
          );
          final restored = machine.restore(
            StorySnapshot.fromJson(old.toJson()),
          );
          expect(machine.scene(restored).id, scenes[i].id);
          expect(restored.flags, old.flags);
          expect(restored.hints, 2);
        }
      }
    }
  });
  test('each normal finale question has an unambiguous independently checked picture answer', () {
    const expected = <String, List<QuizGlyph>>{
      'ep6-bridge-three': [QuizGlyph.stone, QuizGlyph.stone, QuizGlyph.stone],
      'ep6-one-more': [QuizGlyph.stone, QuizGlyph.stone, QuizGlyph.stone],
      'ep6-one-less': [QuizGlyph.stone, QuizGlyph.stone],
      'ep7-red-flowers': [QuizGlyph.redFlower, QuizGlyph.redFlower],
      'ep7-shape-path': [QuizGlyph.triangle],
      'ep7-leaf-pair': [QuizGlyph.leaf, QuizGlyph.leaf],
      'ep8-letter-basket': [QuizGlyph.latinA, QuizGlyph.latinC],
      'ep8-number-basket': [QuizGlyph.one, QuizGlyph.three],
      'ep8-page-pattern': [QuizGlyph.book],
      'ep9-hangul': [QuizGlyph.ga],
      'ep9-english': [QuizGlyph.apple],
      'ep9-math': [QuizGlyph.stone, QuizGlyph.stone, QuizGlyph.stone],
      'ep9-hangul-vowel': [QuizGlyph.vowelO],
      'ep9-english-case': [QuizGlyph.lowerA],
      'ep9-math-more': [QuizGlyph.stone, QuizGlyph.stone, QuizGlyph.stone],
      'ep9-hangul-order': [QuizGlyph.ga, QuizGlyph.na],
      'ep9-english-pair': [QuizGlyph.latinA, QuizGlyph.apple],
      'ep9-math-pattern': [QuizGlyph.seed],
      'ep10-seed-next': [QuizGlyph.sprout],
      'ep10-growth-order': [QuizGlyph.seed, QuizGlyph.sprout, QuizGlyph.tree],
      'ep10-book-pair': [QuizGlyph.book, QuizGlyph.book],
      'ep11-five-stars': [
        QuizGlyph.star,
        QuizGlyph.star,
        QuizGlyph.star,
        QuizGlyph.star,
        QuizGlyph.star,
      ],
      'ep11-star-pattern': [QuizGlyph.circle],
      'ep11-three-memories': [
        QuizGlyph.vowelA,
        QuizGlyph.latinA,
        QuizGlyph.three,
      ],
      'ep12-star-decoration': [QuizGlyph.star, QuizGlyph.star],
      'ep12-flower-decoration': [QuizGlyph.flower, QuizGlyph.flower],
      'ep12-letter-reunion': [QuizGlyph.latinA, QuizGlyph.lowerA],
      'ep12-tidy-books': [QuizGlyph.book, QuizGlyph.book],
    };
    final questions = {
      for (final scene in storyEpisodes.skip(5).expand((e) => e.scenes))
        for (final quiz in [
          if (scene.quiz != null) scene.quiz!,
          ...scene.quizVariants.values,
        ])
          quiz.id: quiz,
    };
    expect(questions.keys.toSet(), expected.keys.toSet());
    for (final quiz in questions.values) {
      expect(
        quiz.artwork!.choices[quiz.answer],
        expected[quiz.id],
        reason: quiz.id,
      );
      expect(
        quiz.artwork!.choices
            .map((g) => g.map((p) => p.name).join(','))
            .toSet()
            .length,
        quiz.options.length,
      );
      expect(quiz.options.toSet().length, quiz.options.length);
    }
  });
  for (final ep in [6, 11]) {
    test(
      'chapter $ep requires unique placements, rejects wrong slots and restores the arrangement',
      () async {
        var s = finaleScene(ep, 'quiz');
        final count = ep == 6 ? 3 : 5;
        expect(machine.canAnswer(s), false);
        expect(machine.answer(s, 1).phase, StoryPhase.quiz);
        expect(machine.placeObject(s, 0, 1).observedObjects, isEmpty);
        expect(machine.placeObject(s, -1, 0).observedObjects, isEmpty);
        expect(machine.placeObject(s, count, 0).observedObjects, isEmpty);
        s = machine.placeObject(s, count - 1, 0);
        s = machine.placeObject(s, count - 1, 1);
        expect(s.observedObjects, [count - 1]);
        final repo = StoryRepository(MemoryStore());
        await repo.save(s);
        s = machine.restore((await repo.load())!);
        expect(s.observedObjects, [count - 1]);
        for (var i = 0; i < count - 1; i++) {
          s = machine.placeObject(s, i, i + 1);
        }
        expect(s.observedObjects.toSet().length, count);
        expect(machine.canAnswer(s), true);
        expect(machine.answer(s, 0).phase, StoryPhase.quiz);
        s = machine.answer(s, 1);
        expect(machine.background(s), ep == 6 ? 'ep6-built' : 'ep11-lit');
        expect(machine.placeObject(s, 0, count).toJson(), s.toJson());
        expect(machine.advance(s).observedObjects, isEmpty);
      },
    );
  }
  test('placement fallback and parent relevel clear incompatible pieces while restoring route counts correctly', () {
    final s = finaleScene(11, 'quiz').change({
      'observedObjects': [4, 2, 0, 99],
    });
    expect(machine.restore(s).observedObjects, [4, 2, 0]);
    final small = machine.relevel(s, 2);
    expect(small.observedObjects, isEmpty);
    expect(machine.canAnswer(small), true);
    expect(machine.easier(s).observedObjects, isEmpty);
    final route = finaleScene(9, 'quiz', flags: {'route': '숫자 길'}).change({
      'observedObjects': [2, 0, 9],
    });
    expect(machine.restore(route).observedObjects, [2, 0]);
    expect(
      machine
          .restore(
            route.change({
              'flags': {'route': '영어 길'},
            }),
          )
          .observedObjects,
      isEmpty,
    );
  });
  test(
    'nine route quizzes and route speech stay selected after save/reopen',
    () async {
      final repo = StoryRepository(MemoryStore());
      for (final route in ['한글 길', '영어 길', '숫자 길']) {
        final ids = <String>{};
        for (final stage in ['quiz', 'review', 'together']) {
          final s = finaleScene(9, stage, flags: {'route': route});
          await repo.save(s);
          final reopened = machine.restore((await repo.load())!);
          final quiz = machine.quiz(reopened);
          ids.add(quiz.id);
          expect(
            quiz.subject,
            route == '한글 길'
                ? 'hangul'
                : route == '영어 길'
                ? 'english'
                : 'math',
          );
          expect(
            machine.speeches(reopened).map((s) => s.language).toSet(),
            route == '한글 길'
                ? {'ko-KR'}
                : route == '영어 길'
                ? {'en-US'}
                : <String>{},
          );
        }
        expect(ids.length, 3);
      }
    },
  );
  test('both library endings follow room choice only after successful decoration and survive help/reopen', () async {
    final repo = StoryRepository(MemoryStore());
    for (final room in ['꽃 방', '별 방']) {
      final s = finaleScene(12, 'quiz', flags: {'room': room});
      expect(machine.background(s), 'ep12-return');
      expect(machine.background(machine.answer(s, 0)), 'ep12-return');
      final solved = machine.answer(s, 1);
      final expected = room == '꽃 방' ? 'ep12-flowers' : 'ep12-stars';
      expect(machine.background(solved), expected);
      await repo.save(solved);
      expect(
        machine.background(machine.restore((await repo.load())!)),
        expected,
      );
      expect(
        machine.background(
          machine.assist(s.change({'attempts': 3}), const ParentSettings()),
        ),
        expected,
      );
      expect(
        machine.background(finaleScene(12, 'end', flags: {'room': room})),
        expected,
      );
    }
  });
  test('all remaining age two explorations accept either concrete picture', () {
    for (var ep = 6; ep <= 12; ep++) {
      final s = finaleScene(ep, 'quiz', level: 2);
      final q = machine.quiz(s);
      expect(q.artwork!.objects.every((g) => g.symbol == null), true);
      for (var i = 0; i < q.options.length; i++) {
        expect(machine.answer(s, i).phase, StoryPhase.success);
      }
    }
  });
  test('growth fallback reduces three stages to two without changing the learning objective', () {
    final original = finaleScene(10, 'review');
    final easier = machine.easier(original);
    final quiz = machine.quiz(easier);
    expect(quiz.kind, QuizKind.order);
    expect(quiz.artwork!.choices[quiz.answer], [
      QuizGlyph.seed,
      QuizGlyph.sprout,
    ]);
    expect(machine.answer(easier, 0).phase, StoryPhase.quiz);
    expect(machine.answer(easier, 1).phase, StoryPhase.success);
      final restored = machine.originalMission(easier);
      expect(restored.phase, StoryPhase.quiz);
      expect(restored.supportSceneId, isNull);
      expect(machine.quiz(restored).id, machine.quiz(original).id);
  });
  for (var level = 2; level <= 5; level++) {
    for (final assisted in [false, true]) {
      test(
        'all routes and rooms complete chapters 6–12 age $level assisted $assisted',
        () async {
          for (var route = 0; route < 3; route++) {
            for (var room = 0; room < 2; room++) {
              var s = finaleScene(6, 'start', level: level).change({
                'completed': [1, 2, 3, 4, 5],
              });
              var steps = 0;
              final repo = StoryRepository(MemoryStore());
              while (s.phase != StoryPhase.finished && steps++ < 250) {
                switch (s.phase) {
                  case StoryPhase.dialogue:
                  case StoryPhase.success:
                  case StoryPhase.episodeComplete:
                    s = machine.advance(s);
                  case StoryPhase.choice:
                    s = machine.choose(
                      s,
                      s.episode == 8
                          ? route
                          : s.episode == 11
                          ? room
                          : 0,
                    );
                  case StoryPhase.quiz:
                    if (assisted && level > 2) {
                      s = machine.easier(s);
                    } else if (!machine.canAnswer(s)) {
                      final count = machine.quiz(s).artwork!.objects.length;
                      for (var i = 0; i < count; i++) {
                        s = machine.placeObject(s, i, i);
                      }
                    }
                    s = machine.answer(
                      s,
                      level == 2 ? 1 : machine.quiz(s).answer,
                    );
                  case StoryPhase.tracing:
                    if (assisted) {
                      s = machine.assist(
                        s.change({'attempts': 3}),
                        const ParentSettings(),
                      );
                    } else {
                      final item = learningItems.firstWhere(
                        (i) => i.id == machine.scene(s).traceId,
                      );
                      s = machine.trace(
                        s,
                        item.strokes[s.strokes.length].samples(80),
                      );
                    }
                  case StoryPhase.drawing:
                    s = machine.drawingComplete(s);
                  case StoryPhase.finished:
                    break;
                }
                await repo.save(s);
                s = machine.restore((await repo.load())!);
              }
              expect(s.phase, StoryPhase.finished);
              expect(s.completed, List.generate(12, (i) => i + 1));
              expect(s.flags['route'], ['한글 길', '영어 길', '숫자 길'][route]);
              expect(s.flags['room'], ['꽃 방', '별 방'][room]);
            }
          }
        },
      );
    }
  }
}
