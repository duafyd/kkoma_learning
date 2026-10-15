import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/tracing/presentation/trace_vm.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';

void main() {
  for (final size in [
    const Size(1280, 800),
    const Size(800, 1280),
    const Size(600, 960),
  ]) {
    testWidgets('all screens fit ${size.width} by ${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
      expect(tester.takeException(), isNull, reason: 'initial home');
      for (final path in [
        '/learn/hangul',
        '/learn/english',
        '/learn/math',
        '/trace/h-ㅏ',
        '/trace/h-모',
        '/trace/e-g',
        '/trace/n-20',
        '/drawing',
        '/story',
        '/gallery',
        '/parent',
        '/rest',
        '/',
      ]) {
        container.read(routerProvider).go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: path);
      }
      container.read(routerProvider).go('/trace/e-A');
      await tester.pumpAndSettle();
      for (final path in tracePaths['A']!) {
        await container
            .read(traceProvider('e-A').notifier)
            .submit(path.samples(80), 5);
      }
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'completed tracing layout',
      );
      await tester.tap(find.text('다음 글자'));
      await tester.pumpAndSettle();
      expect(find.text('a 따라 그리기'), findsOneWidget);
      expect(container.read(traceProvider('e-a')).requireValue.strokeIndex, 0);
      expect(tester.takeException(), isNull, reason: 'next lowercase tracing');
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });
  }
}
