import 'dart:convert';
import 'dart:io';

import 'voice_catalog.dart';

({Map<String, dynamic> index, List<String> errors}) recordingBundlePlan({
  Directory? directory,
}) {
  final root = directory ?? Directory('assets/audio'),
      lines = buildVoiceCatalog();
  final knownIds = lines.map((l) => l.id).toSet(),
      errors = <String>[],
      clips = <Map<String, dynamic>>[];
  final previous = <String, Map>{};
  final indexFile = File('${root.path}/recordings.json');
  if (indexFile.existsSync()) {
    try {
      final index = jsonDecode(indexFile.readAsStringSync());
      if (index is! Map || index['version'] != 1 || index['clips'] is! List) {
        throw const FormatException('unsupported index');
      }
      for (final clip in index['clips'] as List) {
        if (clip is! Map || clip['id'] is! String) {
          throw const FormatException('invalid entry');
        }
        if (previous.containsKey(clip['id'])) {
          throw const FormatException('duplicate ID');
        }
        previous[clip['id'] as String] = clip;
      }
    } catch (error) {
      errors.add('Unreadable recording index: $error');
    }
  }
  for (final line in lines) {
    final file = File('${root.path}/${line.id}.wav');
    if (!file.existsSync()) continue;
    final old = previous[line.id];
    if (old != null &&
        (old['text'] != line.text || old['language'] != line.language)) {
      errors.add(
        '${line.id}: transcript/locale changed; review and replace the recording before updating its index entry',
      );
      continue;
    }
    if (old?['speaker'] != null && old!['speaker'] != line.speaker) {
      errors.add(
        '${line.id}: speaker changed; recast and review this take before updating its index entry',
      );
      continue;
    }
    final bytes = file.readAsBytesSync(), issue = validateVoiceWav(bytes);
    if (issue != null) {
      errors.add('${line.id}: $issue');
      continue;
    }
    clips.add({
      'id': line.id,
      'text': line.text,
      'language': line.language,
      'bytes': bytes.length,
      'speaker': line.speaker,
    });
  }
  if (root.existsSync()) {
    for (final file in root.listSync().whereType<File>()) {
      final name = file.uri.pathSegments.last;
      if (name.toLowerCase().endsWith('.wav') &&
          !knownIds.contains(name.substring(0, name.length - 4))) {
        errors.add('Unmapped voice file $name');
      }
    }
  }
  return (index: {'version': 1, 'clips': clips}, errors: errors);
}

void main(List<String> args) {
  final plan = recordingBundlePlan();
  if (plan.errors.isNotEmpty) {
    for (final error in plan.errors) {
      stderr.writeln(error);
    }
    exitCode = 1;
    return;
  }
  final file = File('assets/audio/recordings.json');
  final expected =
      '${const JsonEncoder.withIndent('  ').convert(plan.index)}\n';
  if (args.contains('--check')) {
    if (!file.existsSync() || file.readAsStringSync() != expected) {
      stderr.writeln(
        'Voice bundle index is stale. Run dart run tool/prepare_recordings.dart.',
      );
      exitCode = 1;
      return;
    }
  } else {
    final temporary = File('${file.path}.tmp');
    temporary.writeAsStringSync(expected, flush: true);
    temporary.renameSync(file.path);
  }
  stdout.writeln(
    '${(plan.index['clips'] as List).length} bundled recordings; missing scripts use offline TTS. Listening review remains separate.',
  );
}
