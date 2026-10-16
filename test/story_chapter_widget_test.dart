import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/story/data/story_content.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/presentation/story_illustration.dart';
import 'package:flutter_application_1/features/story/presentation/story_picture_quiz.dart';
import 'package:flutter_application_1/features/story/presentation/story_vm.dart';

class _StoryStore extends MemoryStore {
  bool reject = false;
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (reject && key == 'story') throw StateError('disk full');
    await super.write(key, value);
  }
}

void main() {
  for (final ep in List.generate(11, (i) => i + 1)) {
    for (final size in [
      const Size(360, 780),
      const Size(780, 360),
      const Size(1280, 800),
    ]) {
      for (final scale in [1.0, 1.5]) {
        testWidgets(
          'chapter ${ep + 1} letter mission, save and event at $size scale $scale',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            final store = _StoryStore();
            await ProfileRepository(store).save(
              const ParentSettings(
                age: 5,
                level: 5,
                autoRead: false,
                animations: false,
                voiceVolume: 0,
                effectsVolume: 0,
              ),
            );
            final scenes = storyEpisodes[ep].forLevel(5);
            final index = scenes.indexWhere((s) => s.id.endsWith('-quiz'));
            await StoryRepository(store).save(
              StorySnapshot(
                episode: ep,
                scene: index,
                level: 5,
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
            Finder scroll() => find
                .byWidgetPredicate(
                  (w) =>
                      w is Scrollable && w.axisDirection == AxisDirection.down,
                )
                .last;
            Future<void> reveal(Finder finder, double delta) async {
              await tester.scrollUntilVisible(
                finder,
                delta,
                scrollable: scroll(),
              );
              await tester.pumpAndSettle();
              for (var i = 0; i < 2; i++) {
                await Scrollable.ensureVisible(
                  tester.element(finder),
                  alignment: .5,
                );
                await tester.pumpAndSettle();
              }
            }

            String background() => tester
                .widget<StoryIllustration>(find.byType(StoryIllustration))
                .background;
            expect(background(), scenes[index].background);
            await reveal(find.byType(StoryPictureQuiz).first, 120);
            if ([1, 2, 3, 4, 6, 7, 8, 9, 11].contains(ep)) {
              final alternative = find.byKey(
                const ValueKey('letter-choice-alternative'),
              );
              await reveal(alternative, 100);
              await tester.tap(find.text('버튼으로 고르기'));
              await tester.pumpAndSettle();
            }
            if (ep == 5 || ep == 10) {
              final alternative = find.byKey(
                const ValueKey('placement-alternative'),
              );
              await reveal(alternative, 100);
              await tester.tap(find.text('버튼으로 놓기'));
              await tester.pumpAndSettle();
            }
            final vm = c.read(storyProvider.notifier);
            if (!vm.machine.canAnswer(c.read(storyProvider).requireValue)) {
              final objects = vm.machine
                  .quiz(c.read(storyProvider).requireValue)
                  .artwork!
                  .objects;
              for (var i = 0; i < objects.length; i++) {
                final piece = find.byKey(ValueKey('quiz-object-$i'));
                await reveal(piece, 100);
                await tester.tap(piece);
                await tester.pumpAndSettle();
              }
              expect(
                c.read(storyProvider).requireValue.observedObjects.length,
                objects.length,
              );
            }
            final wrong = find.byKey(const ValueKey('picture-answer-0'));
            await reveal(wrong, 100);
            await tester.tap(wrong);
            await tester.pumpAndSettle();
            expect(c.read(storyProvider).requireValue.phase, StoryPhase.quiz);
            final correct = find.byKey(const ValueKey('picture-answer-1'));
            await reveal(correct, 100);
            if (size.width == 1280 && scale == 1) {
              store.reject = true;
              await tester.tap(correct);
              await tester.pumpAndSettle();
              expect(c.read(storyProvider).requireValue.phase, StoryPhase.quiz);
              await reveal(find.byType(StoryIllustration), -160);
              expect(background(), scenes[index].background);
              store.reject = false;
              await reveal(correct, 120);
            }
            await tester.tap(correct);
            await tester.pumpAndSettle();
            expect(
              c.read(storyProvider).requireValue.phase,
              StoryPhase.success,
            );
            await reveal(find.byType(StoryIllustration), -160);
            expect(background(), scenes[index].successBackground);
            c.invalidate(storyProvider);
            await tester.pumpAndSettle();
            expect(
              c.read(storyProvider).requireValue.phase,
              StoryPhase.success,
            );
            expect(background(), scenes[index].successBackground);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
            c.dispose();
            await tester.pumpAndSettle();
          },
        );
      }
    }
  }
}
