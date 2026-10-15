import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/audio/sound_effects.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/presentation/story_vm.dart';
import 'package:flutter_application_1/features/story/presentation/story_illustration.dart';
import 'package:flutter_application_1/features/story/presentation/story_character.dart';
import 'package:flutter_application_1/features/story/presentation/story_page_turn.dart';

class _StoryStore extends MemoryStore {
  bool reject = false;
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (reject && key == 'story') throw StateError('disk full');
    await super.write(key, value);
  }
}

void main() {
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

  for (final size in [const Size(1280, 800), const Size(360, 780)]) {
    testWidgets(
      'animated book, tap greeting, page cues and mission swipe guard at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = _StoryStore();
        await ProfileRepository(store).save(
          const ParentSettings(
            age: 5,
            level: 5,
            autoRead: false,
            voiceVolume: 0,
          ),
        );
        final container = ProviderContainer(
          overrides: [storeProvider.overrideWithValue(store)],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const KkomaApp(),
          ),
        );
        await tester.pumpAndSettle();
        container.read(routerProvider).go('/story');
        await tester.pumpAndSettle();
        expect(find.byType(StoryCharacter), findsNWidgets(2));
        expect(
          calls.where((c) => c.method == 'play'),
          isEmpty,
          reason: 'Restore/open is silent',
        );
        await tester.tap(
          find.byWidgetPredicate(
            (w) => w is StoryCharacter && w.character == '모아',
          ),
        );
        await tester.pumpAndSettle();
        expect(
          calls.where((c) => c.method == 'play').single.arguments['sound'],
          'friend',
        );

        calls.clear();
        store.reject = true;
        await tester.ensureVisible(find.text('다음 장면'));
        await tester.tap(find.text('다음 장면'));
        await tester.pumpAndSettle();
        expect(container.read(storyProvider).requireValue.scene, 0);
        expect(
          calls.where((c) => c.method == 'play'),
          isEmpty,
          reason: 'Failed save must not turn a page or play',
        );
        store.reject = false;
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('다음 장면'));
        await tester.tap(find.text('다음 장면'));
        await tester.pumpAndSettle();
        expect(container.read(storyProvider).requireValue.scene, 1);
        expect(
          calls.where((c) => c.method == 'play').single.arguments['sound'],
          'pageTurn',
        );
        await tester.ensureVisible(find.text('다음 장면'));
        await tester.tap(find.text('다음 장면'));
        await tester.pumpAndSettle();
        expect(
          container.read(storyProvider).requireValue.phase,
          StoryPhase.choice,
        );
        final before = container.read(storyProvider).requireValue.scene;
        await tester.ensureVisible(find.byType(StoryIllustration));
        await tester.fling(
          find.byType(StoryIllustration),
          const Offset(-240, 0),
          900,
        );
        await tester.pumpAndSettle();
        expect(container.read(storyProvider).requireValue.scene, before);
        await tester.ensureVisible(find.text('토토'));
        await tester.tap(find.text('토토'));
        await tester.pumpAndSettle();
        expect(
          container.read(storyProvider).requireValue.flags['companion'],
          '토토',
        );
        expect(
          calls.where((c) => c.method == 'play').last.arguments['sound'],
          'sparkle',
        );
        await tester.ensureVisible(find.text('다음 장면'));
        await tester.pumpAndSettle();
        await Scrollable.ensureVisible(
          tester.element(find.text('다음 장면')),
          alignment: .5,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('다음 장면'));
        await tester.pumpAndSettle();
        expect(
          container.read(storyProvider).requireValue.phase,
          StoryPhase.quiz,
        );
        final quizScene = container.read(storyProvider).requireValue.scene;
        await tester.ensureVisible(find.byType(StoryIllustration));
        await tester.fling(
          find.byType(StoryIllustration),
          const Offset(-240, 0),
          900,
        );
        await tester.pumpAndSettle();
        expect(container.read(storyProvider).requireValue.scene, quizScene);
        expect(
          container.read(storyProvider).requireValue.phase,
          StoryPhase.quiz,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        container.dispose();
        await tester.pumpAndSettle();
      },
    );
  }
  testWidgets(
    'turn blocks old/new actions and reduced motion cancels an active turn',
    (tester) async {
      var taps = 0;
      Widget book(String id, bool animate) => MaterialApp(
        home: Scaffold(
          body: StoryPageTurn(
            pageId: id,
            animate: animate,
            child: Center(
              child: FilledButton(
                onPressed: () => taps++,
                child: Text('Page $id'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(book('1', true));
      await tester.pumpWidget(book('2', true));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Page 2'), warnIfMissed: false);
      expect(taps, 0);
      await tester.pumpWidget(book('2', false));
      await tester.pumpAndSettle();
      expect(find.text('Page 1'), findsNothing);
      await tester.tap(find.text('Page 2'));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
