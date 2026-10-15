import '../../../core/storage/local_store.dart';
import '../domain/usage.dart';

class UsageRepository {
  final LocalStore store;
  UsageRepository(this.store);
  Future<UsageRecord> load(DateTime now) async =>
      UsageRecord.fromJson(await store.read('daily-usage') ?? {}, now);
  Future<void> save(UsageRecord record) =>
      store.write('daily-usage', record.toJson());
}
