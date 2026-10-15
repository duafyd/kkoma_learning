import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/providers.dart';
import 'core/storage/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final store = await SqliteStore.open();
    runApp(
      ProviderScope(
        overrides: [storeProvider.overrideWithValue(store)],
        child: const KkomaApp(),
      ),
    );
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text('저장 공간을 열 수 없어요. 앱을 다시 시작해 주세요.\n$e')),
        ),
      ),
    );
  }
}
