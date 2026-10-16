import 'dart:convert';
import 'dart:io';

import 'voice_catalog.dart';

void main(List<String> args) {
  final lines = buildVoiceCatalog(), invalid = <String>[];
  final entries = <Map<String, dynamic>>[];
  for (final line in lines) {
    final file = File('assets/audio/${line.id}.wav');
    final exists = file.existsSync();
    final error = exists ? validateVoiceWav(file.readAsBytesSync()) : null;
    if (error != null) invalid.add('${line.id}: $error');
    entries.add({
      ...line.toJson(),
      'fileStatus': !exists
          ? 'missing'
          : error == null
          ? 'format-valid-unreviewed'
          : 'invalid',
      'formatError': error,
    });
  }
  final missing = entries.where((e) => e['fileStatus'] == 'missing').length;
  final report = {
    'scope': 'Fixed learning/trace names, quiz prompts, scene dialogue and explicit age/success/choice variants, scene play invitations/responses, story samples, sorting prompts, story counts 1–5.',
    'excluded': [
      'Dynamic hint/error/help/completion messages and compound sorting feedback remain TTS; not an exhaustive runtime utterance list.',
      'Listening review is manual; format-valid files are not automatically marked reviewed. Exact transcript/locale playback is connected via assets/audio/recordings.json.',
    ],
    'reviewStatus': 'All scripts and recordings require pronunciation and educational review.',
    'clipCount': lines.length,
    'missingCount': missing,
    'invalidFiles': invalid,
    'entries': entries,
  };
  Directory('docs/audio').createSync(recursive: true);
  File('docs/audio/voice_scripts.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(report)}\n',
  );
  String cell(Object? value) => '"${value.toString().replaceAll('"', '""')}"';
  final rows = [
    [
      'id',
      'language',
      'category',
      'text',
      'contexts',
      'review',
      'file',
      'file_status',
      'listening_review',
      'speaker',
      'emotion',
      'delivery',
      'pacing',
    ],
    for (final e in entries)
      [
        e['id'],
        e['language'],
        e['category'],
        e['text'],
        (e['contexts'] as List).join(' | '),
        (e['review'] as List).join(' | '),
        e['file'],
        e['fileStatus'],
        'pending',
        (e['performance'] as Map)['speaker'],
        (e['performance'] as Map)['emotion'],
        (e['performance'] as Map)['delivery'],
        (e['performance'] as Map)['pacing'],
      ],
  ];
  File('docs/audio/voice_scripts.csv').writeAsStringSync(
    '\ufeff${rows.map((r) => r.map(cell).join(',')).join('\r\n')}\r\n',
  );
  stdout.writeln(
    '${lines.length} fixed voice scripts; $missing missing; ${invalid.length} invalid; listening review pending.',
  );
  if (invalid.isNotEmpty ||
      (args.contains('--require-recordings') && missing > 0)) {
    exitCode = 1;
  }
}
