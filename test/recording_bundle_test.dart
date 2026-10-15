import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../tool/prepare_recordings.dart';
import '../tool/voice_catalog.dart';

// Format fixture only: never shipped as a recorded voice or marked listening-reviewed.
Uint8List _wav() {
  final data = ByteData(32044);
  void tag(int offset, String value) {
    for (var i = 0; i < 4; i++) {
      data.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  data.setUint32(4, 32036, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, 16000, Endian.little);
  data.setUint32(28, 32000, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  data.setUint32(40, 32000, Endian.little);
  return data.buffer.asUint8List();
}

void main() {
  late Directory directory;
  setUp(
    () =>
        directory = Directory.systemTemp.createTempSync('kkoma-voice-bundle-'),
  );
  tearDown(() => directory.deleteSync(recursive: true));
  test('empty recordings are a valid offline TTS bundle', () {
    final plan = recordingBundlePlan(directory: directory);
    expect(plan.errors, isEmpty);
    expect(plan.index['clips'], isEmpty);
  });
  test('only present valid WAVs receive exact catalog transcript, locale and byte length', () {
    const id = 'voice-story-letter-a-name';
    File('${directory.path}/$id.wav').writeAsBytesSync(_wav());
    final plan = recordingBundlePlan(directory: directory),
        line = buildVoiceCatalog().firstWhere((l) => l.id == id);
    expect(plan.errors, isEmpty);
    expect(plan.index['clips'], [
      {'id': id, 'text': line.text, 'language': 'en-US', 'bytes': 32044},
    ]);
  });
  test(
    'invalid and unknown WAVs block packaging rather than silently shipping',
    () {
      File('${directory.path}/voice-story-letter-a-name.wav')
          .writeAsBytesSync([1, 2]);
      File('${directory.path}/voice-unknown.wav').writeAsBytesSync(_wav());
      final plan = recordingBundlePlan(directory: directory);
      expect(plan.index['clips'], isEmpty);
      expect(plan.errors.length, 2);
      expect(plan.errors.any((e) => e.contains('Unmapped')), true);
    },
  );
  test(
    'existing recorded text or locale changes require a deliberate review',
    () {
      const id = 'voice-story-letter-a-name';
      File('${directory.path}/$id.wav').writeAsBytesSync(_wav());
      for (final old in [
        {'id': id, 'text': 'Apple', 'language': 'en-US'},
        {'id': id, 'text': 'A', 'language': 'ko-KR'},
      ]) {
        File('${directory.path}/recordings.json').writeAsStringSync(
          jsonEncode({
            'version': 1,
            'clips': [old],
          }),
        );
        final plan = recordingBundlePlan(directory: directory);
        expect(plan.errors.single, contains('transcript/locale changed'));
        expect(plan.index['clips'], isEmpty);
      }
    },
  );
  test('malformed existing index is reported and left intact', () {
    final file = File('${directory.path}/recordings.json')
      ..writeAsStringSync('broken');
    expect(
      recordingBundlePlan(directory: directory).errors.single,
      contains('Unreadable'),
    );
    expect(file.readAsStringSync(), 'broken');
  });
}
