import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/parent/domain/usage.dart';

void main() {
  testWidgets(
    'expired day blocks new activity but parent gate remains accessible',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = MemoryStore();
      await ProfileRepository(
        store,
      ).save(const ParentSettings(minutes: 5, autoRead: false, voiceVolume: 0));
      await store.write(
        'daily-usage',
        UsageRecord(UsageRecord.dateKey(DateTime.now()), 301).toJson(),
      );
      final c = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(store)],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const KkomaApp()),
      );
      await tester.pumpAndSettle();
      c.read(routerProvider).go('/math/play');
      await tester.pumpAndSettle();
      expect(find.text('잠깐 쉬어요'), findsOneWidget);
      c.read(routerProvider).go('/parent');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '0');
      await tester.tap(find.text('설정 열기'));
      await tester.pumpAndSettle();
      expect(find.text('다시 계산해 주세요.'), findsOneWidget);
      final prompt = tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data ?? '')
          .firstWhere((s) => RegExp(r'^\d+ \+ \d+ = \?$').hasMatch(s));
      final numbers = RegExp(r'\d+')
          .allMatches(prompt)
          .map((m) => int.parse(m.group(0)!))
          .toList();
      await tester.enterText(
        find.byType(TextField),
        '${numbers[0] + numbers[1]}',
      );
      await tester.tap(find.text('설정 열기'));
      await tester.pumpAndSettle();
      expect(find.text('보호자 설정'), findsOneWidget);
      expect(find.text('만 나이'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
