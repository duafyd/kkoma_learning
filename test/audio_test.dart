import 'package:flutter/services.dart';

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/audio/audio_service.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'getVoices') {
            return [
              {
                'name': 'offline-ko',
                'locale': 'ko-KR',
                'network_required': '0',
              },
            ];
          }
          return 1;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  test('rapid reading requests cancel earlier utterances', () async {
    final audio = AudioService();
    final results = await Future.wait([
      audio.speak('첫 요청', const ParentSettings()),
      audio.speak('마지막 요청', const ParentSettings()),
    ]);
    expect(results, [PlaybackResult.cancelled, PlaybackResult.played]);
    final speaks = calls.where((c) => c.method == 'speak').toList();
    expect(speaks.length, 1);
    expect(speaks.single.arguments.toString(), contains('마지막 요청'));
    expect(calls.where((c) => c.method == 'stop'), isNotEmpty);
  });
  test('voice volume zero emits no speech', () async {
    await AudioService().speak('아', const ParentSettings(voiceVolume: 0));
    expect(calls.where((c) => c.method == 'speak'), isEmpty);
  });
  test(
    'Android string network flag selects local voice and rejects network voice',
    () async {
      for (final flag in ['0', '1']) {
        calls.clear();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              calls.add(call);
              if (call.method == 'getVoices') {
                return [
                  {
                    'name': 'android-en',
                    'locale': 'en-US',
                    'network_required': flag,
                  },
                ];
              }
              return 1;
            });
        final result = await AudioService().speak(
          'Apple',
          const ParentSettings(),
          language: 'en-US',
        );
        expect(
          result,
          flag == '0' ? PlaybackResult.played : PlaybackResult.unavailable,
        );
        expect(
          calls.where((c) => c.method == 'speak').length,
          flag == '0' ? 1 : 0,
        );
      }
    },
  );
  test('unavailable language remains a text-only activity', () async {
    final audio = AudioService();
    await audio.speak('Apple', const ParentSettings(), language: 'en-US');
    expect(audio.lastError, isNotNull);
    expect(calls.where((c) => c.method == 'speak'), isEmpty);
  });
  test(
    'native playback refusal reports failure instead of completion',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'getVoices') {
              return [
                {'name': 'ko', 'locale': 'ko_KR', 'network_required': false},
              ];
            }
            return call.method == 'speak' ? 0 : 1;
          });
      final audio = AudioService();
      expect(
        await audio.speak('아', const ParentSettings()),
        PlaybackResult.failed,
      );
      expect(audio.status.issue, AudioIssue.playbackFailed);
      expect(calls.where((c) => c.method == 'stop').length, 2);
    },
  );
  test(
    'old playback completion cannot erase newer missing-voice notice',
    () async {
      final started = Completer<void>(), finish = Completer<int>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getVoices') {
              return [
                {'name': 'ko', 'locale': 'ko-KR', 'network_required': false},
              ];
            }
            if (call.method == 'speak') {
              started.complete();
              return finish.future;
            }
            return 1;
          });
      final audio = AudioService();
      final first = audio.speak('아', const ParentSettings());
      await started.future;
      expect(
        await audio.speak('Apple', const ParentSettings(), language: 'en-US'),
        PlaybackResult.unavailable,
      );
      finish.complete(1);
      expect(await first, PlaybackResult.cancelled);
      expect(audio.status.issue, AudioIssue.missingVoice);
      expect(audio.status.language, 'en-US');
    },
  );
  test('timed out utterance is stopped and can be retried', () async {
    var hang = true;
    final finish = Completer<int>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getVoices') {
            return [
              {'name': 'ko', 'locale': 'ko-KR', 'network_required': false},
            ];
          }
          if (call.method == 'speak' && hang) return finish.future;
          return 1;
        });
    final audio = AudioService(
      utteranceTimeout: const Duration(milliseconds: 20),
    );
    expect(
      await audio.speak('아', const ParentSettings()),
      PlaybackResult.failed,
    );
    hang = false;
    finish.complete(1);
    expect(
      await audio.speak('아', const ParentSettings()),
      PlaybackResult.played,
    );
    expect(audio.lastError, isNull);
  });
}
