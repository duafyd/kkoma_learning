import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/audio/audio_service.dart';
import 'package:flutter_application_1/core/audio/recorded_voice.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/learning/domain/learning_speech.dart';
import 'package:flutter_application_1/features/learning/presentation/learning_vm.dart';
import 'package:flutter_application_1/features/profile/presentation/profile_vm.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/progress/data/progress_repository.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/presentation/story_vm.dart';

class _Bundle extends CachingAssetBundle {
  final Future<String> value;
  int loads = 0;
  _Bundle(String text) : value = Future.value(text);
  _Bundle.pending(this.value);
  @override
  Future<String> loadString(String key, {bool cache = true}) {
    expect(key, RecordedVoice.indexAsset);
    loads++;
    return value;
  }

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
}

String _manifest({
  String text = 'A',
  String language = 'en-US',
  String id = 'voice-test-a',
}) => jsonEncode({
  'version': 1,
  'clips': [
    {'id': id, 'text': text, 'language': language, 'bytes': 32044},
  ],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const ttsChannel = MethodChannel('flutter_tts');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final events = <String>[], plays = <Map>[], ttsCalls = <MethodCall>[];
  Future<Object?> Function(MethodCall)? nativeReply;
  var voicesAvailable = true;
  var ttsResult = 1;
  AudioService service({String? manifest, Duration? timeout, _Bundle? bundle}) {
    final audio = AudioService(
      recordings: RecordedVoice(
        bundle: bundle ?? _Bundle(manifest ?? _manifest()),
      ),
      recordingTimeout: timeout ?? const Duration(seconds: 1),
    );
    addTearDown(audio.dispose);
    return audio;
  }

  Future<PlaybackResult> speak(
    AudioService audio, {
    ParentSettings settings = const ParentSettings(),
  }) => audio.speak('A', settings, language: 'en-US');
  setUp(() {
    events.clear();
    plays.clear();
    ttsCalls.clear();
    nativeReply = null;
    voicesAvailable = true;
    ttsResult = 1;
    messenger.setMockMethodCallHandler(RecordedVoice.nativeChannel, (
      call,
    ) async {
      events.add('recording:${call.method}');
      if (call.method == 'play') plays.add(Map.from(call.arguments as Map));
      if (nativeReply != null) return nativeReply!(call);
      return call.method == 'play' ? 'completed' : null;
    });
    messenger.setMockMethodCallHandler(ttsChannel, (call) async {
      events.add('tts:${call.method}');
      ttsCalls.add(call);
      if (call.method == 'getVoices') {
        return voicesAvailable
            ? [
                {'name': 'en', 'locale': 'en-US', 'network_required': '0'},
                {'name': 'ko', 'locale': 'ko-KR', 'network_required': false},
              ]
            : [];
      }
      return call.method == 'speak' ? ttsResult : 1;
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(RecordedVoice.nativeChannel, null);
    messenger.setMockMethodCallHandler(ttsChannel, null);
  });

  test('recording works without TTS language packs and waits for native completion', () async {
    voicesAvailable = false;
    final started = Completer<void>(), finish = Completer<String>();
    nativeReply = (call) async {
      if (call.method != 'play') return null;
      started.complete();
      return finish.future;
    };
    final audio = service();
    var returned = false;
    final result = speak(audio).then((value) {
      returned = true;
      return value;
    });
    await started.future;
    expect(returned, false);
    expect(audio.lastSource, isNull);
    finish.complete('completed');
    expect(await result, PlaybackResult.played);
    expect(audio.lastSource, VoiceSource.recording);
    expect(
      ttsCalls.where((c) => c.method == 'getVoices' || c.method == 'speak'),
      isEmpty,
    );
  });

  test('exact text and locale matching caches the index and rejects unrelated clips', () async {
    final bundle = _Bundle(_manifest());
    final recordings = RecordedVoice(bundle: bundle);
    expect(await recordings.find('A', 'ko-KR'), isNull);
    expect(await recordings.find('Apple', 'en-US'), isNull);
    expect(await recordings.find('a', 'en-US'), isNull);
    expect((await recordings.find('A', 'en-US'))!.id, 'voice-test-a');
    expect(bundle.loads, 1);
  });
  test('duplicate IDs invalidate the whole index rather than choose ambiguous audio', () async {
    final value = jsonDecode(_manifest()) as Map;
    (value['clips'] as List).add((value['clips'] as List).first);
    final audio = service(manifest: jsonEncode(value));
    expect(await speak(audio), PlaybackResult.played);
    expect(plays, isEmpty);
    expect(audio.recordings.lastError, contains('duplicate'));
  });
  test('unsupported native platform still uses TTS', () async {
    messenger.setMockMethodCallHandler(RecordedVoice.nativeChannel, null);
    final audio = service();
    expect(await speak(audio), PlaybackResult.played);
    expect(audio.lastSource, VoiceSource.tts);
  });
  test(
    'story sample uses the recording without passing or changing the mission',
    () async {
      final store = MemoryStore(), audio = service();
      await ProfileRepository(store)
          .save(const ParentSettings(age: 5, level: 5, autoRead: false));
      const snapshot = StorySnapshot(
        episode: 4,
        scene: 3,
        level: 5,
        phase: StoryPhase.quiz,
      );
      await StoryRepository(store).save(snapshot);
      final c = ProviderContainer(
        overrides: [
          storeProvider.overrideWithValue(store),
          audioProvider.overrideWithValue(audio),
        ],
      );
      addTearDown(c.dispose);
      await c.read(storyProvider.future);
      expect(
        await c.read(storyProvider.notifier).listenTo(0),
        PlaybackResult.played,
      );
      expect(audio.lastSource, VoiceSource.recording);
      expect(plays.single['id'], 'voice-test-a');
      expect(
        (await StoryRepository(store).load())!.toJson(),
        snapshot.toJson(),
      );
    },
  );

  for (final (label, manifest) in [
    ('missing', '{"version":1,"clips":[]}'),
    ('corrupt', 'bad json'),
    ('unsafe path', _manifest(id: 'voice-../private')),
    ('different language', _manifest(language: 'ko-KR')),
    ('different text', _manifest(text: 'Apple')),
  ]) {
    test('$label index falls back to offline TTS', () async {
      final audio = service(manifest: manifest);
      expect(await speak(audio), PlaybackResult.played);
      expect(plays, isEmpty);
      expect(audio.lastSource, VoiceSource.tts);
      expect(ttsCalls.where((c) => c.method == 'speak').length, 1);
    });
  }
  for (final failure in ['missing', 'failed', 'unknown', 'exception']) {
    test('native $failure stops the recording before TTS fallback', () async {
      nativeReply = (call) async {
        if (call.method != 'play') return null;
        if (failure == 'exception') throw PlatformException(code: 'decoder');
        return failure;
      };
      final audio = service();
      expect(await speak(audio), PlaybackResult.played);
      final play = events.indexOf('recording:play'),
          tts = events.indexOf('tts:speak');
      expect(events.sublist(play + 1, tts), contains('recording:stop'));
      expect(audio.lastSource, VoiceSource.tts);
    });
  }
  test('recorded repetitions use only voice volume and preserve completed repeats on fallback', () async {
    final audio = service();
    const settings = ParentSettings(
      repeats: 3,
      voiceVolume: .4,
      effectsVolume: 0,
      musicVolume: 0,
    );
    expect(await speak(audio, settings: settings), PlaybackResult.played);
    expect(plays.length, 3);
    expect(plays.every((p) => p['volume'] == .4), true);
    expect(plays.map((p) => p['token']).toSet().length, 1);
    plays.clear();
    nativeReply = (call) async => call.method == 'play'
        ? (plays.length == 1 ? 'completed' : 'failed')
        : null;
    expect(await speak(audio, settings: settings), PlaybackResult.played);
    expect(plays.length, 2);
    expect(ttsCalls.where((c) => c.method == 'speak').length, 2);
    expect(ttsCalls.singleWhere((c) => c.method == 'setVolume').arguments, .4);
  });
  test(
    'focus loss or native cancellation never starts fallback speech',
    () async {
      nativeReply = (call) async => call.method == 'play' ? 'cancelled' : null;
      expect(await speak(service()), PlaybackResult.cancelled);
      expect(ttsCalls.where((c) => c.method == 'speak'), isEmpty);
    },
  );
  test('timed out recording is stopped before fallback and late result is harmless', () async {
    final finish = Completer<String>();
    nativeReply = (call) async => call.method == 'play' ? finish.future : null;
    final audio = service(timeout: const Duration(milliseconds: 20));
    expect(await speak(audio), PlaybackResult.played);
    expect(audio.lastSource, VoiceSource.tts);
    finish.complete('completed');
    await Future<void>.delayed(Duration.zero);
    expect(audio.lastSource, VoiceSource.tts);
    expect(
      events.sublist(events.indexOf('recording:play') + 1),
      contains('recording:stop'),
    );
  });
  test('failed native stop prevents overlapping fallback', () async {
    nativeReply = (call) async {
      if (call.method == 'play') return 'failed';
      if (call.arguments != null) throw PlatformException(code: 'stop-failed');
      return null;
    };
    final audio = service();
    expect(await speak(audio), PlaybackResult.failed);
    expect(audio.status.issue, AudioIssue.playbackFailed);
    expect(ttsCalls.where((c) => c.method == 'speak'), isEmpty);
  });
  test('failed recording and missing TTS do not falsely complete', () async {
    voicesAvailable = false;
    nativeReply = (call) async => call.method == 'play' ? 'missing' : null;
    final audio = service();
    expect(await speak(audio), PlaybackResult.unavailable);
    expect(audio.status.issue, AudioIssue.missingVoice);
    expect(audio.lastSource, isNull);
  });
  test(
    'failed fallback reports failure rather than a played recording',
    () async {
      ttsResult = 0;
      nativeReply = (call) async => call.method == 'play' ? 'failed' : null;
      expect(await speak(service()), PlaybackResult.failed);
    },
  );
  for (final action in ['stop', 'replace', 'dispose', 'background', 'mute']) {
    test(
      '$action cancels pending recording and stale completion cannot overwrite status',
      () async {
        final started = Completer<void>(), finish = Completer<String>();
        nativeReply = (call) async {
          if (call.method != 'play') return null;
          started.complete();
          return finish.future;
        };
        final audio = service();
        final first = speak(audio);
        await started.future;
        switch (action) {
          case 'stop':
            await audio.stop();
          case 'replace':
            voicesAvailable = false;
            expect(
              await audio.speak('new', const ParentSettings()),
              PlaybackResult.unavailable,
            );
          case 'dispose':
            audio.dispose();
          case 'background':
            audio.setActive(false);
            expect(await speak(audio), PlaybackResult.cancelled);
          case 'mute':
            expect(
              await speak(
                audio,
                settings: const ParentSettings(voiceVolume: 0),
              ),
              PlaybackResult.muted,
            );
        }
        finish.complete('completed');
        expect(await first, PlaybackResult.cancelled);
        expect(plays.length, 1);
        expect(audio.lastSource, isNull);
        expect(ttsCalls.where((c) => c.method == 'speak'), isEmpty);
        if (action == 'replace') {
          expect(audio.status.issue, AudioIssue.missingVoice);
        }
        if (action == 'background') {
          nativeReply = null;
          audio.setActive(true);
          expect(await speak(audio), PlaybackResult.played);
        }
      },
    );
  }
  test('stop during index load blocks delayed playback', () async {
    final index = Completer<String>();
    // A separate bundle exposes the pending I/O without a native player.
    final pendingAudio = service(bundle: _Bundle.pending(index.future));
    final result = speak(pendingAudio);
    await Future<void>.delayed(Duration.zero);
    await pendingAudio.stop();
    index.complete(_manifest());
    expect(await result, PlaybackResult.cancelled);
    expect(plays, isEmpty);
  });
  test('learning completion waits for audio and cancellation does not add an attempt', () async {
    final store = MemoryStore(),
        started = Completer<void>(),
        finish = Completer<String>();
    final item = learningItems.first;
    final audio = service(
      manifest: _manifest(
        text: learningListeningText(item),
        language: item.language,
      ),
    );
    // Use the same helper as the production learning VM for this language.
    final c = ProviderContainer(
      overrides: [
        storeProvider.overrideWithValue(store),
        audioProvider.overrideWithValue(audio),
      ],
    );
    addTearDown(c.dispose);
    final sub = c.listen(learningProvider('hangul'), (_, _) {});
    addTearDown(sub.close);
    await c.read(learningProvider('hangul').future);
    nativeReply = (call) async {
      if (call.method != 'play') return null;
      started.complete();
      return finish.future;
    };
    final listening = c.read(learningProvider('hangul').notifier).listen(item);
    await started.future;
    expect(
      (await ProgressRepository(store).load())['listen-${item.id}'],
      isNull,
    );
    finish.complete('completed');
    await listening;
    expect(
      (await ProgressRepository(store)
          .load())['listen-${item.id}']['successes'],
      1,
    );
    nativeReply = (call) async => call.method == 'play' ? 'cancelled' : null;
    await c.read(learningProvider('hangul').notifier).listen(item);
    expect(
      (await ProgressRepository(store).load())['listen-${item.id}']['attempts'],
      1,
    );
  });
  test('parent voice mute cancels speech and sends native stop', () async {
    final started = Completer<void>(), finish = Completer<int>();
    final c = ProviderContainer(
      overrides: [storeProvider.overrideWithValue(MemoryStore())],
    );
    addTearDown(c.dispose);
    await c.read(settingsProvider.future);
    final audio = c.read(audioProvider);
    // Production provider listener and real empty bundle: use TTS completion gate.
    messenger.setMockMethodCallHandler(ttsChannel, (call) async {
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
    final result = audio.speak('부모 음소거', const ParentSettings());
    await started.future;
    final stops = events.where((e) => e == 'recording:stop').length;
    await c.read(settingsProvider.notifier).change('voiceVolume', 0.0);
    finish.complete(1);
    expect(await result, PlaybackResult.cancelled);
    expect(
      events.where((e) => e == 'recording:stop').length,
      greaterThan(stops),
    );
  });
  testWidgets(
    'app lifecycle stops pending voice and blocks queued speech until resume',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final audio = service();
      expect(
        (await audio.recordings.find('A', 'en-US'))?.id,
        'voice-test-a',
        reason: audio.recordings.lastError,
      );
      final c = ProviderContainer(
        overrides: [
          storeProvider.overrideWithValue(MemoryStore()),
          audioProvider.overrideWithValue(audio),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const KkomaApp()),
      );
      await tester.pumpAndSettle();
      final finish = Completer<String>();
      nativeReply = (call) async =>
          call.method == 'play' ? finish.future : null;
      final result = speak(audio);
      await tester.pump();
      expect(
        plays.length,
        1,
        reason:
            '$events; lifecycle=${tester.binding.lifecycleState}; index=${audio.recordings.lastError}; status=${audio.lastError}',
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(await speak(audio), PlaybackResult.cancelled);
      finish.complete('completed');
      await tester.pump();
      expect(await result, PlaybackResult.cancelled);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      nativeReply = null;
      final resumed = speak(audio);
      await tester.pump();
      expect(await resumed, PlaybackResult.played);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
