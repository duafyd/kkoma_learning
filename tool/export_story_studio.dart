import 'dart:convert';
import 'dart:io';

import 'voice_catalog.dart';
import 'voice_quality.dart';

void main(List<String> args) {
  final lines = buildVoiceCatalog()
      .where((l) => l.contexts.any((c) => c.startsWith('story:')))
      .toList();
  final takes = <Map<String, dynamic>>[];
  for (final line in lines) {
    final file = File('assets/audio/${line.id}.wav');
    takes.add({
      ...line.toJson(),
      'productionStatus': file.existsSync()
          ? 'recorded-unreviewed'
          : 'not-produced',
      'quality': file.existsSync()
          ? inspectVoicePcm(file.readAsBytesSync())
          : null,
    });
  }
  final report = {
    'purpose': 'Offline story performances: human actor or expressive AI takes, never a claim that system TTS is a finished performance.',
    'takes': takes,
    'casting': {
      for (final speaker
          in takes.map((t) => (t['performance'] as Map)['speaker']).toSet())
        speaker: {
          'takeCount': takes
              .where((t) => (t['performance'] as Map)['speaker'] == speaker)
              .length,
          'voiceAssigned': false,
          'auditionIds': takes
              .where((t) => (t['performance'] as Map)['speaker'] == speaker)
              .take(3)
              .map((t) => t['id'])
              .toList(),
        },
    },
    'reviewChecklist': [
      'Same character uses the same approved actor/voice throughout all 12 episodes.',
      'Emotion follows the scene; directions are never spoken aloud.',
      'Check Hangul names/sounds and English names/words separately.',
      'Check transcript, pauses, question intent and avoid answer leakage.',
      'Listen on a tablet at comfortable volume; no shouting, distortion or background music in stems.',
      'PCM metrics are advisory, not acting/pronunciation/listening approval; RMS is not LUFS.',
    ],
  };
  final output = File('docs/audio/story_studio.json');
  output.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(report)}\n',
  );
  final recorded = takes.where((t) => t['quality'] != null).length;
  final warned = takes
      .where(
        (t) =>
            t['quality'] != null &&
            ((t['quality'] as Map)['warnings'] as List).isNotEmpty,
      )
      .length;
  stdout.writeln(
    '${takes.length} story takes; $recorded recorded; $warned with PCM warnings; auditions and listening review pending.',
  );
  if (args.contains('--require-recordings') &&
      (recorded != takes.length || warned > 0)) {
    exitCode = 1;
  }
}
