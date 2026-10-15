import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/parent/domain/parent_gate.dart';

void main() {
  test('settings survive a new repository', () async {
    final store = MemoryStore();
    await ProfileRepository(store)
        .save(const ParentSettings(age: 5, voiceVolume: 0));
    final restored = await ProfileRepository(store).load();
    expect(restored.age, 5);
    expect(restored.voiceVolume, 0);
  });
  test('parent gate checks arithmetic and rejects invalid input', () {
    final gate = ParentGate(a: 13, b: 7);
    expect(gate.accepts('20'), true);
    expect(gate.accepts('7'), false);
    expect(gate.accepts(''), false);
  });
  testWidgets('home and parent gate work at tablet size', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storeProvider.overrideWithValue(MemoryStore())],
        child: const KkomaApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('한글 놀이터'), findsOneWidget);
    await tester.tap(find.byTooltip('보호자 영역'));
    await tester.pumpAndSettle();
    expect(find.text('보호자 확인'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
