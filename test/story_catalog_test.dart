import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/story/data/story_content.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/domain/story_validation.dart';

StoryEpisode _chapter(
  List<StoryScene> pages, {
  int id = 1,
  String title = '이야기',
}) => StoryEpisode(
  id: id,
  title: title,
  goal: '별빛 찾기',
  reward: '별빛',
  scenes: pages,
);
const _page = StoryScene(id: 'page', text: '함께 찾아요.');
List<String> _check(
  List<StoryEpisode> episodes, {
  Set<String> traceIds = const {},
}) => validateStoryCatalog(episodes, traceIds: traceIds);

void main() {
  test('all twelve authored chapters have unambiguous identities and playable age paths', () {
    expect(
      validateStoryCatalog(
        storyEpisodes,
        traceIds: learningItems
            .where((i) => i.strokes.isNotEmpty)
            .map((i) => i.id)
            .toSet(),
      ),
      isEmpty,
    );
  });
  test(
    'empty catalogs and inaccessible age paths fail before scene traversal',
    () {
      expect(_check([]), contains('empty story catalog'));
      expect(_check([_chapter([])]).length, 4);
      final issues = _check([
        _chapter([const StoryScene(id: 'late', text: '함께', minimumLevel: 5)]),
      ]);
      expect(issues.length, 3);
      expect(issues.any((s) => s.contains('level 2')), isTrue);
    },
  );
  test(
    'episode IDs must be positive and unique, independent of list order',
    () {
      expect(
        _check([
          _chapter([_page], id: 0),
        ]).single,
        contains('episode ID'),
      );
      final issues = _check([
        _chapter([_page]),
        _chapter([const StoryScene(id: 'other', text: '함께')]),
      ]);
      expect(issues.single, contains('duplicate episode ID'));
    },
  );
  test('scene identity collisions are rejected inside and across chapters', () {
    for (final chapters in [
      [
        _chapter([_page, _page]),
      ],
      [
        _chapter([_page]),
        _chapter([_page], id: 2),
      ],
    ]) {
      expect(_check(chapters).single, contains('duplicate scene ID'));
    }
  });
  test('blank or padded identity, missing text and missing chapter metadata are rejected', () {
    for (final id in ['', ' page ']) {
      expect(
        _check([
          _chapter([StoryScene(id: id, text: '함께')]),
        ]).single,
        contains('scene ID'),
      );
    }
    expect(
      _check([
        _chapter([const StoryScene(id: 'empty', text: ' ')]),
      ]).single,
      contains('dialogue'),
    );
    expect(
      _check([
        _chapter([_page], title: ' '),
      ]).single,
      contains('title'),
    );
  });
  test(
    'runtime phases and out-of-range levels cannot be authored missions',
    () {
      for (final phase in [
        StoryPhase.success,
        StoryPhase.episodeComplete,
        StoryPhase.finished,
      ]) {
        expect(
          _check([
            _chapter([StoryScene(id: 'bad', text: '함께', interaction: phase)]),
          ]).single,
          contains('runtime phase'),
        );
      }
      expect(
        _check([
          _chapter([const StoryScene(id: 'bad', text: '함께', minimumLevel: 1)]),
        ]).single,
        contains('minimum level'),
      );
    },
  );
  test(
    'choice labels must be visible, distinct and have at least two options',
    () {
      for (final choices in [
        <String>[],
        ['친구'],
        ['', '별'],
        ['별', ' 별 '],
      ]) {
        expect(
          _check([
            _chapter([
              StoryScene(
                id: 'choice',
                text: '함께',
                interaction: StoryPhase.choice,
                choices: choices,
              ),
            ]),
          ]).single,
          contains('choices'),
        );
      }
      expect(
        _check([
          _chapter([
            const StoryScene(
              id: 'choice',
              text: '함께',
              interaction: StoryPhase.choice,
              choices: ['별', '꽃'],
            ),
          ]),
        ]),
        isEmpty,
      );
    },
  );
  test('tracing must reference a supplied playable item and quiz missions need a quiz', () {
    const trace = StoryScene(
      id: 'trace',
      text: '따라 그려요.',
      interaction: StoryPhase.tracing,
      traceId: 'h-ㅏ',
    );
    expect(
      _check([
        _chapter([trace]),
      ]).single,
      contains('unknown tracing item'),
    );
    expect(
      _check(
        [
          _chapter([trace]),
        ],
        traceIds: {'h-ㅏ'},
      ),
      isEmpty,
    );
    expect(
      _check([
        _chapter([
          const StoryScene(
            id: 'quiz',
            text: '함께',
            interaction: StoryPhase.quiz,
          ),
        ]),
      ]).single,
      contains('missing quiz'),
    );
  });
  test('variant quizzes require the flag used by the story machine', () {
    final q = learningQuizzes.first;
    StoryScene scene(String? flag) => StoryScene(
      id: 'variant',
      text: '함께',
      interaction: StoryPhase.quiz,
      quiz: q,
      variationFlag: flag,
      quizVariants: {'길': q},
    );
    expect(
      _check([
        _chapter([scene(null)]),
      ]).single,
      contains('selection flag'),
    );
    expect(
      _check([
        _chapter([scene('route')]),
      ]),
      isEmpty,
    );
  });
}
