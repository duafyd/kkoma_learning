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
      ),
    );
    final c = ProviderContainer(
      overrides: [storeProvider.overrideWithValue(store)],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const KkomaApp()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('오늘의 모험'));
    await tester.pumpAndSettle();
    expect(find.text('1화 · 빛을 잃은 도서관'), findsOneWidget);
    await tester.tap(find.text('다음 장면'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음 장면'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('토토'));
    await tester.pumpAndSettle();
    final snapshot = await StoryRepository(store).load();
    expect(snapshot!.flags['companion'], '토토');
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await store.db.close();
    final reopened = await SqliteStore.open(fileName: fileName);
    expect((await ProfileRepository(reopened).load()).age, 4);
    expect(
      (await StoryRepository(reopened).load())!.toJson(),
      snapshot.toJson(),
    );
    await reopened.db.close();
  });
}
