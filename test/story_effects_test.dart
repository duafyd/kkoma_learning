import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/audio/sound_effects.dart';
import 'package:flutter_application_1/features/story/domain/story_cues.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SoundEffects.channel, (call) async {
          calls.add(call);
          return call.method == 'play' ? true : null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SoundEffects.channel, null),
  );

  test(
    'only a new committed page, companion choice or success produces a cue',
    () {
      const before = StorySnapshot();
      expect(StoryCues.between(null, before), isNull);
      expect(StoryCues.between(before, before), isNull);
      expect(
        StoryCues.between(before, before.change({'attempts': 1, 'hints': 1})),
        isNull,
      );
      expect(
        StoryCues.between(before, before.change({'scene': 1})),
        StorySound.pageTurn,
      );
      expect(
        StoryCues.between(before, before.change({'phase': 'success'})),
        StorySound.sparkle,
      );
      expect(
        StoryCues.between(
          before,
          before.change({
            'flags': {'companion': '토토'},
          }),
        ),
        StorySound.friend,
      );
      final success = before.change({'phase': 'success'});
      expect(StoryCues.between(null, success), isNull);
      expect(StoryCues.between(success, success), isNull);
      final counted = before.change({
        'observedObjects': [2],
      });
      expect(StoryCues.between(before, counted), StorySound.friend);
      expect(StoryCues.between(counted, counted), isNull);
      expect(StoryCues.between(counted, before), isNull);
    },
  );
  test('effects volume is independent, muted requests emit no play, repeated taps are limited', () async {
    final sounds = SoundEffects();
    expect(await sounds.play(StorySound.friend, 0), EffectPlayback.muted);
    expect(calls.where((c) => c.method == 'play'), isEmpty);
    expect(await sounds.play(StorySound.friend, .25), EffectPlayback.started);
    expect(await sounds.play(StorySound.friend, .25), EffectPlayback.cancelled);
    expect(
      calls.where((c) => c.method == 'play').single.arguments['volume'],
      .25,
    );
  });
  test('background cancels deferred playback; resume does not replay; dispose blocks play', () async {
    final pending = Completer<bool>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SoundEffects.channel, (call) async {
          calls.add(call);
          return call.method == 'play' ? pending.future : null;
        });
    final sounds = SoundEffects();
    final playing = sounds.play(StorySound.sparkle, .3);
    await Future<void>.delayed(Duration.zero);
    sounds.setActive(false);
    pending.complete(true);
    expect(await playing, EffectPlayback.cancelled);
    expect(await sounds.play(StorySound.friend, .3), EffectPlayback.cancelled);
    sounds.setActive(true);
    expect(calls.where((c) => c.method == 'play').length, 1);
    sounds.dispose();
    expect(await sounds.play(StorySound.friend, .3), EffectPlayback.cancelled);
    await Future<void>.delayed(Duration.zero);
  });
  test('native refusal is diagnosable and leaves text/story usable', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SoundEffects.channel, (call) async {
          calls.add(call);
          return call.method == 'play' ? false : null;
        });
    final sounds = SoundEffects();
    expect(
      await sounds.play(StorySound.sparkle, .3),
      EffectPlayback.unavailable,
    );
    expect(sounds.lastError, isNotNull);
    expect(calls.last.method, 'stop');
  });
  test(
    'three bundled effects are non-silent bounded PCM WAVs with short duration',
    () async {
      for (final path in storySoundAssets.values) {
        final bytes = await rootBundle.load(path);
        expect(ascii.decode(bytes.buffer.asUint8List(0, 4)), 'RIFF');
        expect(ascii.decode(bytes.buffer.asUint8List(8, 4)), 'WAVE');
        expect(bytes.getUint16(20, Endian.little), 1);
        expect(bytes.getUint16(22, Endian.little), 1);
        expect(bytes.getUint16(34, Endian.little), 16);
        expect(bytes.getUint32(40, Endian.little), bytes.lengthInBytes - 44);
        final duration =
            (bytes.lengthInBytes - 44) / 2 / bytes.getUint32(24, Endian.little);
        expect(duration, inInclusiveRange(.15, .8));
        var peak = 0;
        for (var i = 44; i < bytes.lengthInBytes; i += 2) {
          final v = bytes.getInt16(i, Endian.little).abs();
          if (v > peak) peak = v;
        }
        expect(peak, inInclusiveRange(100, 11469));
        expect(bytes.getInt16(44, Endian.little).abs(), lessThan(10));
        expect(
          bytes.getInt16(bytes.lengthInBytes - 2, Endian.little).abs(),
          lessThan(100),
        );
      }
    },
  );
}
