import '../../../core/storage/local_store.dart';
import '../domain/settings.dart';

class ProfileRepository {
  final LocalStore store;
  ProfileRepository(this.store);
  Future<ParentSettings> load() async =>
      ParentSettings.fromJson(await store.read('settings') ?? {});
  Future<void> save(ParentSettings settings) =>
      store.write('settings', settings.toJson());
}
