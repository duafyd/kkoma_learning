import 'dart:convert';
import 'dart:io';

import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/story/data/story_content.dart';

void main(List<String> args) {
  final errors = <String>[];
  final knownIds = learningItems.map((i) => i.id).toSet();
  if (knownIds.length != learningItems.length) {
    errors.add('duplicate learning item');
  }
  if (learningQuizzes.map((q) => q.id).toSet().length !=
      learningQuizzes.length) {
    errors.add('duplicate quiz');
  }
  for (final quiz in learningQuizzes) {
    if (quiz.easierId != null &&
        !learningQuizzes.any(
          (q) =>
              q.id == quiz.easierId &&
              q.subject == quiz.subject &&
              q.minimumLevel < quiz.minimumLevel,
        )) {
      errors.add('invalid easier question ${quiz.id}');
    }
    if (quiz.answer < 0 ||
        quiz.answer >= quiz.options.length ||
        quiz.options.toSet().length != quiz.options.length) {
      errors.add('invalid quiz ${quiz.id}');
    }
  }
  for (final scene in storyEpisodes.expand((e) => e.scenes)) {
    if (scene.traceId != null &&
        !learningItems.any(
          (i) => i.id == scene.traceId && i.strokes.isNotEmpty,
        )) {
      errors.add('missing trace ${scene.id}');
    }
  }
  final voices = [
    ...learningItems.map((i) => 'voice-${i.id}'),
    ...storyEpisodes.expand((e) => e.scenes).map((s) => 'voice-${s.id}'),
    ...learningQuizzes.map((q) => 'voice-quiz-${q.id}'),
  ];
  final missing = voices
      .where((id) => !File('assets/audio/$id.wav').existsSync())
      .toList();
  final report = {
    'learningItems': learningItems.length,
    'tracingItems': learningItems.where((i) => i.strokes.isNotEmpty).length,
    'tracingBySubject': {
      for (final subject in ['hangul', 'english', 'math'])
        subject: learningItems
            .where((i) => i.subject == subject && i.strokes.isNotEmpty)
            .length,
    },
    'tracingReview': 'Original centre-line paths; educational stroke-order review pending. Lowercase a/g use single-storey handwriting forms.',
    'episodes': storyEpisodes.length,
    'scenes': storyEpisodes.fold(0, (n, e) => n + e.scenes.length),
    'quizCount': learningQuizzes.length,
    'contentErrors': errors,
    'backgrounds': storyEpisodes
        .expand((e) => e.scenes)
        .map((s) => s.background)
        .toSet()
        .map(
          (id) => {
            'id': id,
            'implementation':
                'Flutter CustomPainter; no external image dependency',
          },
        )
        .toList(),
    'voiceIds': voices,
    'missingRecordings': missing,
    'voiceFallback':
        'Android offline TTS; text remains usable if engine is unavailable',
    'unproduced': ['recorded speech', 'sound effects', 'background music'],
    'expertReview': 'pending',
  };
  File('docs/content_audit.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
  stdout.writeln(
    '${learningItems.length} learning items, ${storyEpisodes.length} episodes, ${errors.length} content errors; ${missing.length} recordings missing (TTS fallback).',
  );
  if (errors.isNotEmpty ||
      (args.contains('--require-recordings') && missing.isNotEmpty)) {
    exitCode = 1;
  }
}
