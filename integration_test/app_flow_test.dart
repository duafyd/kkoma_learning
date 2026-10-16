import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/features/story/presentation/story_page.dart';
import 'package:flutter_application_1/features/tracing/presentation/trace_canvas.dart';
import 'package:flutter_application_1/features/tracing/presentation/trace_vm.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android SQLite, navigation and story resume', (tester) async {
    // An isolated database prevents this test from altering a child's real progress.
    final fileName =
        'kkoma-integration-${DateTime.now().microsecondsSinceEpoch}.db';
    final store = await SqliteStore.open(fileName: fileName);
    await ProfileRepository(store).save(
      const ParentSettings(
        age: 4,
        level: 3,
        autoRead: false,
        animations: false,
        voiceVolume: 0,
        effectsVolume: 0,
      ),
    );
    final c = ProviderContainer(
      overrides: [storeProvider.overrideWithValue(store)],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const KkomaApp()),
    );
    await tester.pumpAndSettle();
    final openStory = find.text('별빛 이야기 펼치기');
    await tester.ensureVisible(openStory);
    await tester.tap(openStory);
    await tester.pumpAndSettle();
    expect(find.byType(StoryPage), findsOneWidget);
    await tester.tap(find.text('다음 장면'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음 장면'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('토토'));
    await tester.pumpAndSettle();
    final snapshot = await StoryRepository(store).load();
    expect(snapshot!.flags['companion'], '토토');
    c.read(routerProvider).go('/trace/p-dot');
    await tester.pumpAndSettle();
    final canvas = find
        .descendant(
          of: find.byType(TraceCanvas),
          matching: find.byType(CustomPaint),
        )
        .first;
    await tester.tapAt(tester.getCenter(canvas));
    await tester.pumpAndSettle();
    expect(c.read(traceProvider('p-dot')).requireValue.done, isTrue);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await store.db.close();
    final reopened = await SqliteStore.open(fileName: fileName);
    expect((await ProfileRepository(reopened).load()).age, 4);
    expect((await reopened.read('trace-p-dot'))!['done'], isTrue);
    expect(
      (await StoryRepository(reopened).load())!.toJson(),
      snapshot.toJson(),
    );
    await reopened.db.close();
  });
}
