import 'dart:convert';
import 'dart:io';

import 'voice_catalog.dart';
import 'prepare_recordings.dart';
import 'export_content_review.dart' show buildContentReview;

import 'package:flutter_application_1/core/audio/sound_assets.dart';

import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/story/data/story_content.dart';
import 'package:flutter_application_1/features/story/data/story_art.dart';
import 'package:flutter_application_1/features/story/data/support_quizzes.dart';
import 'package:flutter_application_1/features/story/domain/scene_play.dart';
import 'package:flutter_application_1/features/story/domain/story_machine.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/domain/story_validation.dart';
import 'package:flutter_application_1/features/math/data/sorting_content.dart';
import 'package:flutter_application_1/features/tracing/data/prewriting_content.dart';

void main(List<String> args) {
  final errors = <String>[];
  errors.addAll(
    validateStoryCatalog(
      storyEpisodes,
      traceIds: learningItems
          .where((i) => i.strokes.isNotEmpty)
          .map((i) => i.id)
          .toSet(),
    ),
  );
  // Stop before traversing malformed pages with the story machine/exporters.
  if (errors.isNotEmpty) {
    stderr.writeln('Story catalog validation failed:\n${errors.join('\n')}');
    exitCode = 1;
    return;
  }
  var reviewQuizCount = 0;
  var explorationQuizCount = 0;
  try {
    final review = buildContentReview();
    final entries = review['quizzes'] as List;
    reviewQuizCount = entries.length;
    explorationQuizCount = entries
        .where((q) => q['answerMode'] == 'exploration')
        .length;
  } on StateError catch (error) {
    errors.add('quiz review: ${error.message}');
  }
  if (ScenePlay.moments.length != storyEpisodes.length ||
      ScenePlay.moments.map((p) => p.kind).toSet().length !=
          storyEpisodes.length ||
      ScenePlay.moments.any(
        (p) => p.object.isEmpty || p.invitation.isEmpty || p.response.isEmpty,
      )) {
    errors.add('invalid scene play coverage');
  }
  final speechSamples = storyEpisodes
      .expand((e) => e.scenes)
      .expand(
        (s) => [...s.speeches, ...s.speechVariants.values.expand((v) => v)],
      )
      .toList();
  final machine = StoryMachine();
  final letterScenes = <String>{};
  final bookScenes = <String>{};
  for (var episode = 0; episode < storyEpisodes.length; episode++) {
    for (var level = 2; level <= 5; level++) {
      final scenes = storyEpisodes[episode].forLevel(level);
      for (var i = 0; i < scenes.length; i++) {
        final scene = scenes[i];
        final book = machine.bookMission(
          StorySnapshot(
            episode: episode,
            scene: i,
            level: level,
            phase: scene.interaction,
          ),
        );
        if (book != null) {
          bookScenes.add(scene.id);
          if (book.tracing) {
            final item = learningItems.firstWhere(
              (item) => item.id == scene.traceId,
            );
            if (book.total != item.strokes.length ||
                book.symbol != item.symbol) {
              errors.add('book world guide mismatch ${scene.id}');
            }
          } else if (book.quiz?.artwork == null ||
              book.quiz!.artwork!.choices.length != book.quiz!.options.length) {
            errors.add('book world choice mismatch ${scene.id}');
          }
        }
        final mission = machine.letterMission(
          StorySnapshot(
            episode: episode,
            scene: i,
            level: level,
            phase: scene.interaction,
          ),
        );
        if (mission == null) continue;
        letterScenes.add(scene.id);
        if (mission.tracing) {
          final item = learningItems.firstWhere(
            (item) => item.id == scene.traceId,
          );
          if (mission.total != item.strokes.length) {
            errors.add('letter world stroke mismatch ${scene.id}');
          }
        } else if (mission.choices.length != scene.quiz!.options.length) {
          errors.add('letter world choice mismatch ${scene.id}');
        }
      }
    }
  }
  if (letterScenes.length != 8) errors.add('incomplete letter world coverage');
  if (bookScenes.length != 22) {
    errors.add('incomplete later book world coverage');
  }
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
    storyMotionCastAsset,
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
    'prewritingItems': prewritingItems.map((i) => i.id).toList(),
    'scenePlayMoments': ScenePlay.moments.length,
    'worldMissionScenes': ['ep6-quiz', 'ep11-quiz'],
    'letterMissionScenes': letterScenes.toList()..sort(),
    'bookMissionScenes': bookScenes.toList()..sort(),
    'bookMissionScope': 'Chapters 7-12: 17 picture quiz scenes and five tracing scenes use Flame props, saved counts/ink and finite theme reactions. Route/room variants are resolved by StoryMachine; age-two/support and chapter-eleven star placement remain on existing paths. Chapter-seven saved map is resolved by artwork ID, no new raster or walking/lip-sync frames.',
    'letterMissionScope': 'Chapters 2/3/4/5 main letter choices use Flame taps. Tracing retains the picture and reacts only to saved strokes; finite flower-path/beacon-light/seed-parcel/train-signal direction. Age-two and support choices remain unchanged; existing bitmaps crossfade, no new door or train sprite frames.',
    'worldMissionScope': 'Flame drag/tap world placements, original persisted order, button alternative, finite committed-success journey. Age-two/support paths retain Flutter picture choices.',
    'scenePlayScope': 'Optional Flame prop discovery on each chapter opening, 1/2/3 props by age; committed saves, finite light/transfer reactions. Other scenes retain Flutter picture-book rendering.',
    'storyIllustrations': storyArtAssets.values.toSet().toList(),
    'storyCharacterAtlas': storyCastAsset,
    'storySearchCharacterAtlas': storySearchCastAsset,
    'storyMotionCharacterAtlas': storyMotionCastAsset,
    'storyCharacterMotionScope': 'Four characters with idle/open expression and two travel poses (16 frames); explicit unequal row crops, finite entry/journey animation, no phoneme-synced lip animation.',
    'storyEffects': storySoundAssets.values.toList(),
    'storySpeechSamples': {
      for (final entry in samplesById.entries)
        entry.key: {'text': entry.value.text, 'language': entry.value.language},
    },
    'scenes': storyEpisodes.fold(0, (n, e) => n + e.scenes.length),
    'quizCount': learningQuizzes.length,
    'reviewQuizCount': reviewQuizCount,
    'explorationQuizCount': explorationQuizCount,
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
