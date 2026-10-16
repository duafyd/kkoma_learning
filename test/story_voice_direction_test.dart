import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/story/domain/story_machine.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/domain/scene_play.dart';

import '../tool/voice_catalog.dart';
import '../tool/voice_quality.dart';

Uint8List wav(List<int> samples) {
  final data = ByteData(44 + samples.length * 2);
  void tag(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      data.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  tag(36, 'data');
  data.setUint32(4, data.lengthInBytes - 8, Endian.little);
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, 16000, Endian.little);
  data.setUint32(28, 32000, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(44 + i * 2, samples[i], Endian.little);
  }
  return data.buffer.asUint8List();
}

void main() {
  test(
    'all age paths and narration variants request exact catalog transcripts',
    () {
      final m = StoryMachine(),
          catalog = {for (final line in buildVoiceCatalog()) line.id: line};
      var checked = 0;
      void check(StorySnapshot s) {
        final id = m.narrationId(s);
        if (id == null) return;
        expect(catalog.containsKey(id), isTrue, reason: '$id ${s.toJson()}');
        expect(catalog[id]!.text, m.narration(s), reason: id);
        checked++;
      }

      for (var ep = 0; ep < m.episodes.length; ep++) {
        for (var level = 2; level <= 5; level++) {
          final scenes = m.episodes[ep].forLevel(level);
          for (var i = 0; i < scenes.length; i++) {
            final s = StorySnapshot(
              episode: ep,
              level: level,
              scene: i,
              phase: scenes[i].interaction,
            );
            check(s);
            final play = ScenePlay.forSnapshot(s);
            if (play != null) {
              check(
                s.change({
                  'sceneFinds': List.generate(play.count(level), (i) => i),
                }),
              );
            }
            if (s.phase == StoryPhase.quiz) {
              final art = m.quiz(s).artwork;
              final ready = s.change({
                'observedObjects': List.generate(
                  art?.objects.length ?? 0,
                  (i) => i,
                ),
              });
              check(ready);
              check(m.answer(ready, m.quiz(ready).answer));
              check(m.easier(s));
            }
            if (s.phase == StoryPhase.choice) {
              for (var c = 0; c < scenes[i].choices.length; c++) {
                check(m.choose(s, c));
              }
            }
          }
        }
      }
      expect(checked, greaterThan(500));
    },
  );
  test('every story line has casting and delivery directions, with no fabricated review', () {
    final lines = buildVoiceCatalog();
    for (final line in lines.where(
      (l) => l.contexts.any((c) => c.startsWith('story:')),
    )) {
      expect(line.performance['delivery'], isNotEmpty);
      expect(line.performance['listeningReview'], 'pending');
      expect(line.performance['pacing'], contains('질문'));
    }
    expect(lines.firstWhere((l) => l.id == 'voice-ep3-start').speaker, '루루');
    expect(lines.firstWhere((l) => l.id == 'voice-ep4-start').speaker, '모아');
    expect(
      lines.firstWhere((l) => l.id == 'voice-story-letter-a-name').speaker,
      '학습 안내',
    );
  });
  test('PCM checks identify silence and clipping without asserting listening approval', () {
    final silence = inspectVoicePcm(wav(List.filled(32000, 0)));
    expect(silence['warnings'], contains('digital-silence'));
    expect(silence['rmsDbfs'], isNull);
    final loud = inspectVoicePcm(wav(List.filled(16000, 32767)));
    expect(loud['warnings'], contains('possible-clipping'));
    expect(loud['warnings'], contains('peak-headroom-below-1dB'));
    expect(loud['listeningReview'], 'pending');
  });
  test('PCM checks measure normal sample peak/RMS and silence duration', () {
    final samples = [
      ...List.filled(3200, 0),
      ...List.generate(16000, (i) => (4000 * math.sin(i * .1)).round()),
      ...List.filled(4800, 0),
    ];
    final report = inspectVoicePcm(wav(samples));
    expect(report['durationSeconds'], 1.5);
    expect(report['samplePeakDbfs'] as double, closeTo(-18.27, .02));
    expect(report['leadingSilenceSeconds'] as double, closeTo(.2, .002));
    expect(report['trailingSilenceSeconds'] as double, closeTo(.3, .002));
    expect(report['warnings'], isEmpty);
    expect(report['listeningReview'], 'pending');
    expect(inspectVoicePcm(Uint8List(4))['formatError'], isNotNull);
  });
}
