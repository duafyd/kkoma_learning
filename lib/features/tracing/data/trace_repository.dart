import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/storage/local_store.dart';
import '../domain/trace_state.dart';

final traceRepositoryProvider = Provider(
  (ref) => TraceRepository(ref.watch(storeProvider)),
);

class TraceRepository {
  final LocalStore store;
  TraceRepository(this.store);
  Future<Map<String, dynamic>?> load(String id) => store.read('trace-$id');
  Future<void> save(String id, TraceState s) => store.write('trace-$id', {
    ...s.toJson(),
    '_updatedAt': DateTime.now().toUtc().toIso8601String(),
  });
}
