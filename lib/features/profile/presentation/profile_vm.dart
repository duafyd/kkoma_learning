import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/profile_repository.dart';
import '../domain/settings.dart';

final profileRepositoryProvider = Provider(
  (ref) => ProfileRepository(ref.watch(storeProvider)),
);
final settingsProvider = AsyncNotifierProvider<SettingsVM, ParentSettings>(
  SettingsVM.new,
);

class SettingsVM extends AsyncNotifier<ParentSettings> {
  Future<void> writes = Future.value();
  @override
  Future<ParentSettings> build() => ref.read(profileRepositoryProvider).load();
  Future<void> change(String key, Object value) {
    final repo = ref.read(profileRepositoryProvider);
    final write = writes.catchError((Object _) {}).then((_) async {
      final changed = state.requireValue.change(key, value);
      final next = key == 'age' ? changed.change('level', value) : changed;
      await repo.save(next);
      if (ref.mounted) state = AsyncData(next);
    });
    writes = write;
    return write;
  }
}
