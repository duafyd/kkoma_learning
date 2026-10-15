import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';

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
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });
  }
}
