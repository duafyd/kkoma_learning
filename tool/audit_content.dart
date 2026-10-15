import 'dart:convert';
import 'dart:io';

import 'voice_catalog.dart';
import 'prepare_recordings.dart';

import 'package:flutter_application_1/core/audio/sound_assets.dart';

import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/story/data/story_content.dart';
import 'package:flutter_application_1/features/story/data/story_art.dart';
import 'package:flutter_application_1/features/story/data/support_quizzes.dart';
import 'package:flutter_application_1/features/math/data/sorting_content.dart';

void main(List<String> args) {
  final errors = <String>[];
  final speechSamples = storyEpisodes
      .expand((e) => e.scenes)
      .expand(
        (s) => [...s.speeches, ...s.speechVariants.values.expand((v) => v)],
      )
      .toList();
  final samplesById = {for (final s in speechSamples) s.id: s};
  for (final sample in speechSamples) {
    final original = samplesById[sample.id]!;
    if (sample.text.isEmpty ||
        sample.label.isEmpty ||
        !['ko-KR', 'en-US'].contains(sample.language) ||
        original.text != sample.text ||
        original.language != sample.language) {
      errors.add('invalid/conflicting story speech ${sample.id}');
    }
  }
  final illustratedQuizzes = {
    for (final quiz in [
      ...storyEpisodes
          .expand((e) => e.scenes)
          .where((s) => s.exploreQuiz != null)
          .map((s) => s.exploreQuiz!),
      ...storyEpisodes
          .expand((e) => e.scenes)
          .where((s) => s.quiz != null)
          .map((s) => s.quiz!),
      ...storyEpisodes
          .expand((e) => e.scenes)
          .expand((s) => s.quizVariants.values),
    ])
      quiz.id: quiz,
  }.values.toList();
  for (final quiz in illustratedQuizzes) {
    if (quiz.answer < 0 ||
        quiz.answer >= quiz.options.length ||
        quiz.options.toSet().length != quiz.options.length) {
      errors.add('invalid story quiz ${quiz.id}');
    }
    final art = quiz.artwork;
    if (art != null &&
        (art.choices.length != quiz.options.length ||
            art.objects.isEmpty ||
            art.choices.any((c) => c.isEmpty))) {
      errors.add('invalid picture choices ${quiz.id}');
    }
  }
  for (final asset in [
    storyCastAsset,
    storySearchCastAsset,
    ...storySoundAssets.values,
  ]) {
    if (!File(asset).existsSync()) errors.add('missing story resource $asset');
  }
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
    for (final key in [
      ...scene.backgroundVariants.values,
      ...scene.successBackgroundVariants.values,
    ]) {
      if (!File(storyArtAssets[key] ?? '').existsSync()) {
        errors.add('missing variant artwork ${scene.id}: $key');
      }
    }
    final art = storyArtAssets[scene.background];
    if (art == null || !File(art).existsSync()) {
      errors.add('missing story artwork ${scene.id}: ${scene.background}');
    }
    if (scene.successBackground != null &&
        !File(storyArtAssets[scene.successBackground] ?? '').existsSync()) {
      errors.add(
        'missing success artwork ${scene.id}: ${scene.successBackground}',
      );
    }
    if (scene.traceId != null &&
        !learningItems.any(
          (i) => i.id == scene.traceId && i.strokes.isNotEmpty,
        )) {
      errors.add('missing trace ${scene.id}');
    }
  }
  for (final q in storySupportQuizzes.values) {
    if (q.options.toSet().length != q.options.length ||
        q.answer < 0 ||
        q.answer >= q.options.length) {
      errors.add('invalid story support ${q.id}');
    }
  }
  for (var age = 2; age <= 5; age++) {
    final rounds = sortingRounds(age);
    if (rounds.map((r) => r.id).toSet().length != rounds.length) {
      errors.add('duplicate sorting round $age');
    }
    for (final r in rounds) {
      if (r.targets.toSet().length != r.targets.length ||
          r.pieces.any((p) => !r.targets.contains(p))) {
        errors.add('invalid sorting round $age ${r.id}');
      }
    }
  }
  final voiceCatalog = buildVoiceCatalog();
  final voices = voiceCatalog.map((line) => line.id).toList();
  for (final line in voiceCatalog) {
    final file = File('assets/audio/${line.id}.wav');
    if (file.existsSync()) {
      final issue = validateVoiceWav(file.readAsBytesSync());
      if (issue != null) errors.add('invalid voice ${line.id}: $issue');
    }
  }
  final missing = voices
      .where((id) => !File('assets/audio/$id.wav').existsSync())
      .toList();
  final bundle = recordingBundlePlan();
  errors.addAll(bundle.errors);
  final indexFile = File('assets/audio/recordings.json');
  final expectedIndex =
      '${const JsonEncoder.withIndent('  ').convert(bundle.index)}\n';
  if (!indexFile.existsSync() ||
      indexFile.readAsStringSync() != expectedIndex) {
    errors.add('stale voice bundle index; run tool/prepare_recordings.dart');
  }
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
    'storyIllustrations': storyArtAssets.values.toSet().toList(),
    'storyCharacterAtlas': storyCastAsset,
    'storySearchCharacterAtlas': storySearchCastAsset,
    'storyEffects': storySoundAssets.values.toList(),
    'storySpeechSamples': {
      for (final entry in samplesById.entries)
        entry.key: {'text': entry.value.text, 'language': entry.value.language},
    },
    'scenes': storyEpisodes.fold(0, (n, e) => n + e.scenes.length),
    'quizCount': learningQuizzes.length,
    'storySupportQuizCount': storySupportQuizzes.length,
    'illustratedStoryQuizCount': illustratedQuizzes
        .where((q) => q.artwork != null)
        .length,
    'sortingRoundsPerLevel': {
      for (var level = 2; level <= 5; level++)
        '$level': sortingRounds(level).length,
    },
    'contentErrors': errors,
    'backgrounds': storyEpisodes
        .expand((e) => e.scenes)
        .map((s) => s.background)
        .toSet()
        .map(
          (id) => {
            'id': id,
            'implementation':
                'Bundled scenery PNG plus transparent animated character atlas',
          },
        )
        .toList(),
    'voiceIds': voices,
    'voiceScriptManifest': 'docs/audio/voice_scripts.json',
    'voiceScriptScope': 'Fixed content including trace names, age/success/choice variants and counts 1–5. Exact transcript/locale recording lookup is connected. Dynamic hint/error/help and compound sorting messages remain TTS.',
    'recordedPlayback': 'Android bundled WAV via MediaPlayer; completion, cancellation, volume, repeats and offline TTS fallback connected. Device listening review pending.',
    'bundledRecordings': (bundle.index['clips'] as List).length,
    'recordingIndex': 'assets/audio/recordings.json',
    'missingRecordings': missing,
    'voiceFallback':
        'Android offline TTS; text remains usable if engine is unavailable',
    'unproduced': ['recorded speech', 'background music'],
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
