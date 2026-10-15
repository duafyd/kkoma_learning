import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/audio/audio_service.dart';
import 'package:flutter_application_1/core/audio/recorded_voice.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/presentation/story_vm.dart';

Future<ProviderContainer> speechContainer({double volume = 1}) async {
  final store = MemoryStore();
  await ProfileRepository(store).save(
    ParentSettings(
      age: 5,
      level: 5,
      autoRead: false,
      animations: false,
      voiceVolume: volume,
      effectsVolume: 0,
      repeats: 1,
    ),
  );
  await StoryRepository(store).save(
    const StorySnapshot(episode: 4, scene: 3, level: 5, phase: StoryPhase.quiz),
  );
  return ProviderContainer(overrides: [storeProvider.overrideWithValue(store)]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');
  final calls = <MethodCall>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Object? reply(MethodCall call) {
    calls.add(call);
    if (call.method == 'getVoices') {
      return [
        {'name': 'local-en', 'locale': 'en-US', 'network_required': '0'},
        {'name': 'local-ko', 'locale': 'ko-KR', 'network_required': '0'},
      ];
    }
    return 1;
  }

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(
      RecordedVoice.nativeChannel,
      (call) async => null,
    );
    messenger.setMockMethodCallHandler(channel, (c) async => reply(c));
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(RecordedVoice.nativeChannel, null);
  });
  List<String> spoken() => calls
      .where((c) => c.method == 'speak')
      .map(
        (c) => c.arguments is Map
            ? (c.arguments as Map)['text'] as String
            : c.arguments as String,
      )
      .toList();

  test(
    'story buttons use separate English A and Apple without changing progress',
    () async {
      final c = await speechContainer();
      addTearDown(c.dispose);
      final before = await c.read(storyProvider.future),
          vm = c.read(storyProvider.notifier);
      expect(await vm.listenTo(0), PlaybackResult.played);
      expect(await vm.listenTo(1), PlaybackResult.played);
      expect(spoken(), ['A', 'Apple']);
      expect(
        calls.where((c) => c.method == 'setLanguage').map((c) => c.arguments),
        ['en-US', 'en-US'],
      );
      expect(c.read(storyProvider).requireValue.toJson(), before.toJson());
      expect(
        (await c.read(storyRepositoryProvider).load())!.phase,
        StoryPhase.quiz,
      );
    },
  );
  test('Hangul route review speaks the target vowel O instead of unrelated syllables', () async {
    final c = await speechContainer();
    addTearDown(c.dispose);
    await c
        .read(storyRepositoryProvider)
        .save(
          const StorySnapshot(
            episode: 8,
            scene: 6,
            level: 5,
            phase: StoryPhase.quiz,
            flags: {'route': '한글 길'},
          ),
        );
    c.invalidate(storyProvider);
    await c.read(storyProvider.future);
    expect(
      await c.read(storyProvider.notifier).listenTo(0),
      PlaybackResult.played,
    );
    expect(spoken(), ['오']);
    expect(
      await c.read(storyProvider.notifier).listenTo(1),
      PlaybackResult.cancelled,
    );
    expect(c.read(storyProvider).requireValue.phase, StoryPhase.quiz);
  });
  test(
    'muted and out-of-range samples emit no speech and do not pass a mission',
    () async {
      final c = await speechContainer(volume: 0);
      addTearDown(c.dispose);
      await c.read(storyProvider.future);
      final vm = c.read(storyProvider.notifier);
      expect(await vm.listenTo(0), PlaybackResult.muted);
      final count = calls.length;
      expect(await vm.listenTo(-1), PlaybackResult.cancelled);
      expect(await vm.listenTo(2), PlaybackResult.cancelled);
      expect(calls.length, count);
      expect(spoken(), isEmpty);
      expect(c.read(storyProvider).requireValue.phase, StoryPhase.quiz);
    },
  );
  test('route samples use the saved Korean or English choice and math emits no sample', () async {
    for (final route in ['한글 길', '영어 길', '숫자 길']) {
      calls.clear();
      final c = await speechContainer();
      await c
          .read(storyRepositoryProvider)
          .save(
            StorySnapshot(
              episode: 8,
              scene: 3,
              level: 5,
              phase: StoryPhase.quiz,
              flags: {'route': route},
            ),
          );
      c.invalidate(storyProvider);
      await c.read(storyProvider.future);
      final result = await c.read(storyProvider.notifier).listenTo(0);
      expect(
        result,
        route == '숫자 길' ? PlaybackResult.cancelled : PlaybackResult.played,
      );
      expect(
        spoken(),
        route == '한글 길'
            ? ['가']
            : route == '영어 길'
            ? ['A']
            : <String>[],
      );
      expect(c.read(storyProvider).requireValue.flags['route'], route);
      c.dispose();
    }
  });
  test(
    'missing English voice is diagnosed and the picture mission still works',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return call.method == 'getVoices'
            ? [
                {'name': 'ko', 'locale': 'ko-KR', 'network_required': '0'},
              ]
            : 1;
      });
      final c = await speechContainer();
      addTearDown(c.dispose);
      await c.read(storyProvider.future);
      final vm = c.read(storyProvider.notifier);
      expect(await vm.listenTo(1), PlaybackResult.unavailable);
      expect(c.read(audioStatusProvider).language, 'en-US');
      expect(c.read(audioStatusProvider).issue, AudioIssue.missingVoice);
      expect(spoken(), isEmpty);
      await vm.answer(1);
      expect(c.read(storyProvider).requireValue.phase, StoryPhase.success);
    },
  );
  test(
    'new sample cancels a pending old sample and stop blocks deferred speech',
    () async {
      final c = await speechContainer();
      addTearDown(c.dispose);
      await c.read(storyProvider.future);
      final vm = c.read(storyProvider.notifier);
      final results = await Future.wait([vm.listenTo(0), vm.listenTo(1)]);
      expect(results, [PlaybackResult.cancelled, PlaybackResult.played]);
      expect(spoken(), ['Apple']);
      calls.clear();
      final pending = Completer<Object?>(), started = Completer<void>();
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getVoices') {
          started.complete();
          return pending.future;
        }
        return reply(call);
      });
      final listening = vm.listenTo(0);
      await started.future;
      await c.read(audioProvider).stop();
      pending.complete([
        {'name': 'en', 'locale': 'en-US', 'network_required': '0'},
      ]);
      expect(await listening, PlaybackResult.cancelled);
      expect(spoken(), isEmpty);
    },
  );

  for (final size in [
    const Size(360, 780),
    const Size(780, 360),
    const Size(1280, 800),
  ]) {
    testWidgets(
      'English speech buttons at $size with large text and route cancellation',
      (tester) async {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final c = await speechContainer();
        await tester.pumpWidget(
          UncontrolledProviderScope(container: c, child: const KkomaApp()),
        );
        await tester.pumpAndSettle();
        c.read(routerProvider).go('/story');
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => c.read(audioProvider).recordings.find('A', 'en-US'),
        );
        Future<void> tapSample(String id) async {
          final finder = find.byKey(ValueKey('story-speech-$id'));
          await tester.scrollUntilVisible(
            finder,
            110,
            scrollable: find
                .byWidgetPredicate(
                  (w) =>
                      w is Scrollable && w.axisDirection == AxisDirection.down,
                )
                .last,
          );
          for (var i = 0; i < 2; i++) {
            await Scrollable.ensureVisible(
              tester.element(finder),
              alignment: .5,
            );
            await tester.pumpAndSettle();
          }
          await tester.tap(finder);
          await tester.pumpAndSettle();
        }

        await tapSample('letter-a-name');
        await tapSample('word-apple');
        expect(spoken(), ['A', 'Apple']);
        expect(c.read(storyProvider).requireValue.phase, StoryPhase.quiz);
        final stops = calls.where((c) => c.method == 'stop').length;
        c.read(routerProvider).go('/');
        await tester.pumpAndSettle();
        expect(
          calls.where((c) => c.method == 'stop').length,
          greaterThan(stops),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        c.dispose();
        await tester.pumpAndSettle();
      },
    );
  }
}
