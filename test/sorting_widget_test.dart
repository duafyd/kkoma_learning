import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/math/domain/sorting.dart';
import 'package:flutter_application_1/features/math/presentation/sorting_vm.dart';
import 'package:flutter_application_1/features/math/presentation/sorting_page.dart';

void main() {
  Future<void> bring(WidgetTester tester, Finder finder, double delta) async {
    final scroll = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .last;
    for (var i = 0; i < 35 && finder.hitTestable().evaluate().isEmpty; i++) {
      final rect = tester.getRect(scroll);
      await tester.dragFrom(
        Offset(rect.right - 2, rect.center.dy),
        Offset(0, -delta),
      );
      await tester.pumpAndSettle();
    }
    expect(finder.hitTestable(), findsOneWidget);
  }

  for (final size in [
    const Size(360, 780),
    const Size(780, 360),
    const Size(1280, 800),
  ]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('real drag and tap sorting at $size text $scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final store = MemoryStore();
        await ProfileRepository(store).save(
          const ParentSettings(
            age: 5,
            level: 5,
            autoRead: false,
            voiceVolume: 0,
            animations: false,
          ),
        );
        final c = ProviderContainer(
          overrides: [storeProvider.overrideWithValue(store)],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(container: c, child: const KkomaApp()),
        );
        await tester.pumpAndSettle();
        c.read(routerProvider).go('/math/match');
        await tester.pumpAndSettle();
        for (final kind in SortingKind.values) {
          final chip = find.widgetWithText(
            ChoiceChip,
            SortingPage.names[kind.index],
          );
          await bring(tester, chip, -250);
          await tester.tap(chip);
          await tester.pumpAndSettle();
          final vm = c.read(sortingProvider(5).notifier),
              round = vm.rules.activity(
                c.read(sortingProvider(5)).requireValue,
              );
          final source = find.byKey(const ValueKey('sorting-piece-0'));
          await bring(tester, source, 160);
          await Scrollable.ensureVisible(
            tester.element(source),
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
          await tester.pumpAndSettle();
          final targetIndex = round.targets.indexOf(round.pieces[0]);
          final target = find.byKey(ValueKey('sorting-target-$targetIndex'));
          final start = tester.getCenter(source),
              end = tester.getCenter(target);
          expect(source.hitTestable(), findsOneWidget);
          expect(target.hitTestable(), findsOneWidget);
          final gesture = await tester.startGesture(start);
          for (var step = 1; step <= 15; step++) {
            await gesture.moveTo(Offset.lerp(start, end, step / 15)!);
            await tester.pump(const Duration(milliseconds: 16));
          }
          await gesture.up();
          await tester.pumpAndSettle();
          expect(
            c.read(sortingProvider(5)).requireValue.placed[0],
            targetIndex,
            reason: kind.name,
          );
          final second = find.byKey(const ValueKey('sorting-piece-1'));
          await tester.ensureVisible(second);
          await tester.tap(second);
          await tester.pumpAndSettle();
          expect(c.read(sortingProvider(5)).requireValue.selected, 1);
          final secondTarget = find.byKey(
            ValueKey(
              'sorting-target-${round.targets.indexOf(round.pieces[1])}',
            ),
          );
          await tester.ensureVisible(secondTarget);
          await tester.tap(secondTarget);
          await tester.pumpAndSettle();
          expect(c.read(sortingProvider(5)).requireValue.placed.length, 2);
          for (var piece = 2; piece < round.pieces.length; piece++) {
            await vm.place(piece, round.targets.indexOf(round.pieces[piece]));
          }
          await tester.pumpAndSettle();
          expect(vm.rules.done(c.read(sortingProvider(5)).requireValue), true);
          expect(tester.takeException(), isNull, reason: kind.name);
          await bring(tester, find.text('다음 놀이'), 200);
          await tester.tap(find.text('다음 놀이'));
          await tester.pumpAndSettle();
        }
        await tester.pumpWidget(const SizedBox());
        c.dispose();
      });
    }
  }
}
