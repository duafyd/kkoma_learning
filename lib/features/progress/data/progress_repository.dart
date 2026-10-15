import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/storage/local_store.dart';
import '../../learning/data/learning_content.dart';

final progressRepositoryProvider = Provider(
  (ref) => ProgressRepository(ref.watch(storeProvider)),
);

class ProgressRepository {
  final LocalStore store;
  Future<void> _writes = Future.value();
  ProgressRepository(this.store);
  Future<Map<String, dynamic>> load() async =>
      await store.read('learning-progress') ?? {};
  Future<void> record(String id, bool success, {bool assisted = false}) {
    final write = _writes.catchError((Object _) {}).then((_) async {
      final progress = await load();
      final old = Map<String, dynamic>.from(progress[id] as Map? ?? {});
      progress[id] = {
        'attempts': (old['attempts'] as int? ?? 0) + 1,
        'successes': (old['successes'] as int? ?? 0) + (success ? 1 : 0),
        'completed': success || old['completed'] == true,
        'assisted': assisted || old['assisted'] == true,
        'last': DateTime.now().toIso8601String(),
      };
      await store.write('learning-progress', progress);
    });
    _writes = write;
    return write;
  }

  Future<void> reset() async {
    await _writes;
    await store.remove('learning-progress');
    await store.remove('story');
    for (var level = 2; level <= 5; level++) {
      await store.remove('math-sorting-$level');
    }
    for (final subject in ['hangul', 'english', 'math']) {
      await store.remove('session-$subject');
    }
    for (final item in learningItems) {
      await store.remove('trace-${item.id}');
    }
  }

  // Activity badges are idempotent across retries if saving the next round fails.
  Future<void> completeOnce(
    String id, {
    bool assisted = false,
    int attempts = 1,
  }) {
    final write = _writes.catchError((Object _) {}).then((_) async {
      final progress = await load();
      final old = Map<String, dynamic>.from(progress[id] as Map? ?? {});
      if (old['completed'] == true) return;
      progress[id] = {
        'attempts': attempts,
        'successes': 1,
        'completed': true,
        'assisted': assisted,
        'last': DateTime.now().toIso8601String(),
      };
      await store.write('learning-progress', progress);
    });
    _writes = write;
    return write;
  }
}
