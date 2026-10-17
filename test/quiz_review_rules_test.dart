import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/learning/domain/learning_models.dart';
import 'package:flutter_application_1/features/learning/domain/quiz_validation.dart';
import 'package:flutter_application_1/features/story/data/story_content.dart';
import 'package:flutter_application_1/features/story/domain/story_machine.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/presentation/story_picture_quiz.dart';

import '../tool/export_content_review.dart';

QuizDefinition fixture({
  String id = 'fixture',
  String prompt = '같은 모양을 골라요',
  List<String> options = const ['별', '원'],
  int answer = 0,
  bool exploration = false,
  QuizKind kind = QuizKind.matching,
  QuizArtwork? artwork,
}) => QuizDefinition(
  id: id,
  prompt: prompt,
  visual: '★',
  options: options,
  answer: answer,
  hint: '천천히 살펴봐요',
  isExploration: exploration,
  kind: kind,
  artwork: artwork,
);

Map sceneFor(Map report, int level, int chapter, String id) {
  final path = (report['storyPaths'] as List).cast<Map>().singleWhere(
    (p) => p['level'] == level,
  );
  final ep = (path['chapters'] as List).cast<Map>().singleWhere(
    (c) => c['id'] == chapter,
  );
  return (ep['scenes'] as List).cast<Map>().singleWhere((s) => s['id'] == id);
}

void main() {
  test('single and exploration rules both reject invalid indices', () {
    for (final q in [fixture(), fixture(exploration: true)]) {
      expect(q.accepts(-1), isFalse);
      expect(q.accepts(2), isFalse);
      expect(q.accepts(0), isTrue);
      expect(q.accepts(1), q.isExploration);
    }
  });

  test('malformed text, choices and answer are rejected before export', () {
    expect(
      validateQuiz(fixture(prompt: ' ', options: ['별', ' 별 '], answer: 4)),
      containsAll([
        'missing identity, prompt or hint',
        'empty or duplicate options',
        'answer outside options',
      ]),
    );
    expect(
      validateQuiz(fixture(options: ['별', ''])),
      contains('empty or duplicate options'),
    );
  });

  test('different labels cannot hide identical picture choices', () {
    expect(
      validateQuiz(
        fixture(
          artwork: const QuizArtwork(
            objects: [QuizGlyph.star],
            choices: [
              [QuizGlyph.star],
              [QuizGlyph.star],
            ],
          ),
        ),
      ),
      contains('visually identical choices'),
    );
  });

  test('count pictures must identify the recorded answer uniquely', () {
    final wrong = fixture(
      kind: QuizKind.count,
      answer: 1,
      artwork: const QuizArtwork(
        objects: [QuizGlyph.star],
        choices: [
          [QuizGlyph.star],
          [QuizGlyph.star, QuizGlyph.star],
        ],
      ),
    );
    final ambiguous = fixture(
      kind: QuizKind.count,
      artwork: const QuizArtwork(
        objects: [QuizGlyph.star],
        choices: [
          [QuizGlyph.star],
          [QuizGlyph.circle],
        ],
      ),
    );
    for (final q in [wrong, ambiguous]) {
      expect(
        validateQuiz(q),
        contains('picture count does not identify the answer uniquely'),
      );
    }
  });

  test(
    'all twelve exploration scenes allow every valid choice without failure',
    () {
      final machine = StoryMachine();
      var count = 0;
      for (final (ep, chapter) in storyEpisodes.indexed) {
        final scenes = chapter.forLevel(2);
        for (final (index, scene) in scenes.indexed) {
          if (scene.interaction != StoryPhase.quiz) continue;
          final state = StorySnapshot(
            episode: ep,
            scene: index,
            level: 2,
            phase: StoryPhase.quiz,
          );
          final q = machine.quiz(state);
          expect(q.isExploration, isTrue, reason: q.id);
          expect(validateQuiz(q), isEmpty);
          for (var i = 0; i < q.options.length; i++) {
            expect(q.accepts(i), isTrue);
            expect(machine.answer(state, i).phase, StoryPhase.success);
          }
          expect(identical(machine.answer(state, -1), state), isTrue);
          count++;
        }
      }
      expect(count, 12);
    },
  );

  test('exploration reports never invent a single correct option', () {
    final report = buildContentReview();
    final entries = (report['quizzes'] as List).cast<Map>();
    expect(entries.length, 127);
    final explores = entries
        .where((q) => q['answerMode'] == 'exploration')
        .toList();
    expect(explores.length, 12);
    for (final q in explores) {
      expect(q['answer'], isNull);
      expect(q['answerIndex'], isNull);
      expect(q['acceptedIndices'], [0, 1]);
    }
    expect(report['educatorApproval'], 'pending');
    expect(report['listeningApproval'], 'pending');
  });

  test('age paths use actual quiz selection and exploration narration', () {
    final report = buildContentReview();
    final toddler = sceneFor(report, 2, 1, 'ep1-quiz');
    final older = sceneFor(report, 3, 1, 'ep1-quiz');
    expect((toddler['primary'] as Map)['quizId'], 'ep1-explore-shapes');
    expect((toddler['primary'] as Map)['acceptedIndices'], [0, 1]);
    expect((older['primary'] as Map)['quizId'], 'ep1-star-shape');
    expect((older['primary'] as Map)['acceptedIndices'], [0]);
    expect(sceneFor(report, 2, 9, 'ep9-quiz')['text'], contains('마음에 드는 그림'));
    expect(report['storyPaths'], hasLength(4));
  });

  test('branch selections and generated tracing help remain reviewable', () {
    final report = buildContentReview();
    final branches = (sceneFor(report, 4, 9, 'ep9-quiz')['branches'] as List)
        .cast<Map>();
    expect(branches.map((b) => (b['primary'] as Map)['quizId']).toSet(), {
      'ep9-hangul',
      'ep9-english',
      'ep9-math',
    });
    final english = branches.singleWhere(
      (b) => (b['flags'] as Map)['route'] == '영어 길',
    );
    expect((english['support'] as Map)['quizId'], 'story-support-english');
    final trace = sceneFor(report, 3, 1, 'ep1-trace');
    expect(trace['primary'], isNull);
    expect((trace['support'] as Map)['quizId'], 'story-support-n-1');
    final ids = (report['quizzes'] as List)
        .cast<Map>()
        .map((q) => q['id'])
        .toSet();
    for (final path in (report['storyPaths'] as List).cast<Map>()) {
      for (final chapter in (path['chapters'] as List).cast<Map>()) {
        for (final scene in (chapter['scenes'] as List).cast<Map>()) {
          for (final use in [
            scene,
            ...(scene['branches'] as List).cast<Map>(),
          ]) {
            for (final key in ['primary', 'support']) {
              if (use[key] case final Map selection) {
                expect(ids, contains(selection['quizId']));
              }
            }
          }
        }
      }
    }
  });

  test(
    'conflicting reused quiz IDs stop export rather than silently overwrite',
    () {
      expect(
        () => buildContentReview(
          learning: [
            fixture(),
            fixture(prompt: '다른 문제'),
          ],
          episodes: [],
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Conflicting quiz ID'),
          ),
        ),
      );
    },
  );

  test('identical shared definitions can be referenced more than once', () {
    final report = buildContentReview(
      learning: [fixture(), fixture()],
      episodes: [],
    );
    expect(
      (report['quizzes'] as List).cast<Map>().where(
        (q) => q['id'] == 'fixture',
      ),
      hasLength(1),
    );
  });

  testWidgets('exploration hints treat both picture options equally', (
    tester,
  ) async {
    final q = storyEpisodes.first.scenes
        .firstWhere((s) => s.exploreQuiz != null)
        .exploreQuiz!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryPictureQuiz(
            quiz: q,
            observed: const [],
            hints: 2,
            animate: false,
            onAnswer: (_) {},
            onObserve: (_) {},
          ),
        ),
      ),
    );
    final first = tester.widget<FilledButton>(
      find.byKey(const ValueKey('picture-answer-0')),
    );
    final second = tester.widget<FilledButton>(
      find.byKey(const ValueKey('picture-answer-1')),
    );
    expect(
      first.style!.backgroundColor!.resolve({}),
      second.style!.backgroundColor!.resolve({}),
    );
    expect(tester.takeException(), isNull);
  });

  test(
    'consonant questions distinguish an initial consonant from a syllable',
    () {
      for (final id in ['h-bag', 'h-tree']) {
        final q = learningQuizzes.singleWhere((q) => q.id == id);
        expect(q.prompt, contains('첫 자음'));
        expect(q.options[q.answer].runes.length, 1);
      }
    },
  );
}
