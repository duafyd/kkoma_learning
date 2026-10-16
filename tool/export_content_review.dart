import 'dart:convert';
import 'dart:io';

import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/learning/domain/learning_models.dart';
import 'package:flutter_application_1/features/learning/domain/quiz_validation.dart';
import 'package:flutter_application_1/features/story/data/story_content.dart';
import 'package:flutter_application_1/features/story/data/support_quizzes.dart';
import 'package:flutter_application_1/features/story/domain/story_machine.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';

Map<String, Object?> reviewQuiz(QuizDefinition q) => {
  'id': q.id,
  'subject': q.subject,
  'minimumLevel': q.minimumLevel,
  'kind': q.kind.name,
  'answerMode': q.isExploration ? 'exploration' : 'single',
  'prompt': q.prompt,
  'options': q.options,
  'answerIndex': q.isExploration ? null : q.answer,
  'answer': q.isExploration ? null : q.options[q.answer],
  'acceptedIndices': [
    for (var i = 0; i < q.options.length; i++)
      if (q.accepts(i)) i,
  ],
  'hint': q.hint,
  'visual': q.visual,
  'resultVisual': q.resultVisual,
  'easierId': q.easierId,
  'approval': 'pending',
  if (q.artwork case final art?)
    'pictures': {
      'objects': art.objects.map((g) => g.label).toList(),
      'choices': art.choices
          .map((c) => c.map((g) => g.label).toList())
          .toList(),
      'objectIds': art.objects.map((g) => g.name).toList(),
      'choiceIds': art.choices
          .map((c) => c.map((g) => g.name).toList())
          .toList(),
      'countOnTap': art.countOnTap,
      'arrangement': art.arrangement.name,
      'objectName': art.objectName,
    },
};

/// Uses runtime selection rules; it never marks educational approval as passed.
Map<String, Object?> buildContentReview({
  List<QuizDefinition>? learning,
  List<StoryEpisode>? episodes,
}) {
  final chapters = episodes ?? storyEpisodes;
  final machine = StoryMachine(chapters);
  final quizzes = <String, Map<String, Object?>>{};
  final uses = <String, Set<String>>{};
  void add(QuizDefinition q, [String? sceneId]) {
    final issues = validateQuiz(q);
    if (issues.isNotEmpty) throw StateError('${q.id}: ${issues.join('; ')}');
    final record = reviewQuiz(q);
    final existing = quizzes[q.id];
    if (existing != null && jsonEncode(existing) != jsonEncode(record)) {
      throw StateError('Conflicting quiz ID: ${q.id}');
    }
    quizzes[q.id] = record;
    if (sceneId != null) (uses[q.id] ??= {}).add(sceneId);
  }

  for (final q in [
    ...(learning ?? learningQuizzes),
    ...storySupportQuizzes.values,
  ]) {
    add(q);
  }
  for (final ep in chapters) {
    for (final scene in ep.scenes) {
      for (final q in [
        ?scene.quiz,
        ?scene.exploreQuiz,
        ...scene.quizVariants.values,
      ]) {
        add(q, scene.id);
      }
    }
  }

  Map<String, Object?> selection(StorySnapshot snapshot) {
    final current = machine.scene(snapshot);
    Map<String, Object?> take(QuizDefinition q) {
      add(q, current.id);
      return {
        'quizId': q.id,
        'acceptedIndices': [
          for (var i = 0; i < q.options.length; i++)
            if (snapshot.level == 2 || q.accepts(i)) i,
        ],
      };
    }

    return {
      if (current.interaction == StoryPhase.quiz)
        'primary': take(machine.quiz(snapshot)),
      if ([StoryPhase.quiz, StoryPhase.tracing].contains(current.interaction))
        'support': take(machine.quiz(machine.easier(snapshot))),
    };
  }

  final paths = [
    for (var level = 2; level <= 5; level++)
      {
        'level': level,
        'observedPlayTime': null,
        'childObservation': 'pending',
        'chapters': [
          for (final (episodeIndex, ep) in chapters.indexed)
            {
              'id': ep.id,
              'title': ep.title,
              'goal': ep.goal,
              'scenes': [
                for (final (sceneIndex, scene) in ep.forLevel(level).indexed)
                  (() {
                    final snapshot = StorySnapshot(
                      episode: episodeIndex,
                      scene: sceneIndex,
                      level: level,
                      phase: scene.interaction,
                    );
                    final selected = selection(snapshot);
                    final branches = [
                      if (scene.interaction == StoryPhase.quiz &&
                          scene.variationFlag != null)
                        for (final value in scene.quizVariants.keys)
                          {
                            'flags': {scene.variationFlag!: value},
                            ...selection(
                              snapshot.change({
                                'flags': {scene.variationFlag!: value},
                              }),
                            ),
                          },
                    ];
                    return {
                      'id': scene.id,
                      'action': scene.interaction.name,
                      'text': machine.text(snapshot),
                      'choices': scene.choices,
                      'traceId': scene.traceId,
                      ...selected,
                      'branches': branches,
                    };
                  })(),
              ],
            },
        ],
      },
  ];
  final ids = quizzes.keys.toList()..sort();
  return {
    'schemaVersion': 2,
    'educatorApproval': 'pending',
    'listeningApproval': 'pending',
    'note': 'Structural checks only. Paths use StoryMachine, including level fallbacks, choice flags and generated tracing support. Exploration has no single answer. Expert/child/listening review remains pending.',
    'quizzes': [
      for (final id in ids)
        {...quizzes[id]!, 'sceneIds': uses[id]?.toList() ?? []},
    ],
    'storyPaths': paths,
  };
}

void main() {
  final report = buildContentReview();
  final entries = report['quizzes'] as List;
  final dir = Directory('docs/review')..createSync(recursive: true);
  File('${dir.path}/content_review.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
  String cell(Object? value) => '"${'${value ?? ''}'.replaceAll('"', '""')}"';
  final csv = StringBuffer(
    'id,subject,level,prompt,options,answer_mode,answer,accepted_options,hint,educator_approval\n',
  );
  for (final q in entries.cast<Map<String, Object?>>()) {
    final options = q['options'] as List<String>;
    final accepted = q['acceptedIndices'] as List<int>;
    csv.writeln(
      [
        q['id'],
        q['subject'],
        q['minimumLevel'],
        q['prompt'],
        options.join(' | '),
        q['answerMode'],
        q['answer'],
        accepted.map((i) => options[i]).join(' | '),
        q['hint'],
        q['approval'],
      ].map(cell).join(','),
    );
  }
  File('${dir.path}/quiz_review.csv').writeAsStringSync('\uFEFF$csv');
  stdout.writeln(
    '${entries.length} unique quiz review entries, ${(report['storyPaths'] as List).length * storyEpisodes.length} age/chapter paths; educator/listening approvals pending.',
  );
}
