import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/parent/domain/usage.dart';
import 'package:flutter_application_1/features/parent/data/usage_repository.dart';

void main() {
  test('daily usage persists and resets only on another date', () async {
    final store = MemoryStore(), now = DateTime(2026, 10, 14, 10);
    final usage = UsageRecord(UsageRecord.dateKey(now), 295).accrue(now, 5);
    expect(usage.expired(5), true);
    expect(usage.expired(10), false);
    await UsageRepository(store).save(usage);
    expect((await UsageRepository(store).load(now)).seconds, 300);
    expect(
      (await UsageRepository(store).load(DateTime(2026, 10, 15))).seconds,
      0,
    );
  });
}
