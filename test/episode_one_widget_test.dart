import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/story/data/episode_one.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/presentation/story_picture_quiz.dart';
import 'package:flutter_application_1/features/story/presentation/story_vm.dart';

void main() {
  for (final size in [
    const Size(360, 780),
    const Size(780, 360),
    const Size(1280, 800),
  ]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets(
        'chapter one picture counting and answer at $size text $scale',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final store = MemoryStore();
          await ProfileRepository(store).save(
            const ParentSettings(
              age: 5,
              level: 5,
              animations: false,
              autoRead: false,
              voiceVolume: 0,
              effectsVolume: 0,
            ),
          );
          await StoryRepository(store).save(
            StorySnapshot(
              level: 5,
              scene: episodeOne
                  .forLevel(5)
                  .indexWhere((s) => s.id == 'ep1-review'),
              phase: StoryPhase.quiz,
            ),
          );
          final c = ProviderContainer(
            overrides: [storeProvider.overrideWithValue(store)],
          );
          await tester.pumpWidget(
            UncontrolledProviderScope(container: c, child: const KkomaApp()),
          );
          await tester.pumpAndSettle();
          c.read(routerProvider).go('/story');
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.byType(StoryPictureQuiz),
            120,
            scrollable: find
                .byWidgetPredicate(
                  (w) =>
                      w is Scrollable && w.axisDirection == AxisDirection.down,
                )
                .last,
          );
          await tester.pumpAndSettle();
          expect(find.byType(StoryPictureQuiz), findsOneWidget);
          Future<void> bring(Finder finder) async {
            await Scrollable.ensureVisible(
              tester.element(finder),
              alignment: .5,
            );
            await tester.pumpAndSettle();
            await Scrollable.ensureVisible(
              tester.element(finder),
              alignment: .5,
            );
            await tester.pumpAndSettle();
          }

          final object = find.byKey(const ValueKey('quiz-object-2'));
          await bring(object);
          await tester.tap(object);
          await tester.pumpAndSettle();
          await tester.tap(object);
          await tester.pumpAndSettle();
          expect(c.read(storyProvider).requireValue.observedObjects, [2]);
          await bring(find.byKey(const ValueKey('quiz-object-0')));
          await tester.tap(find.byKey(const ValueKey('quiz-object-0')));
          await tester.pumpAndSettle();
          expect(c.read(storyProvider).requireValue.observedObjects, [2, 0]);
          final wrong = find.byKey(const ValueKey('picture-answer-0'));
          await bring(wrong);
          await tester.tap(wrong);
          await tester.pumpAndSettle();
          expect(c.read(storyProvider).requireValue.phase, StoryPhase.quiz);
          expect(c.read(storyProvider).requireValue.observedObjects, [2, 0]);
          final correct = find.byKey(const ValueKey('picture-answer-2'));
          await bring(correct);
          await tester.tap(correct);
          await tester.pumpAndSettle();
          expect(c.read(storyProvider).requireValue.phase, StoryPhase.success);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          c.dispose();
          await tester.pumpAndSettle();
        },
      );
    }
  }
}
