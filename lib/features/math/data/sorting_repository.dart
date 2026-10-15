import '../../../core/storage/local_store.dart';
import '../domain/sorting.dart';

class SortingRepository {
  final LocalStore store;
  const SortingRepository(this.store);
  Future<SortingState> load(int level) async {
    try {
      return SortingState.fromJson(
        await store.read('math-sorting-$level') ?? {},
      );
    } on FormatException {
      return const SortingState();
    } on TypeError {
      return const SortingState();
    }
  }

  Future<void> save(int level, SortingState s) =>
      store.write('math-sorting-$level', s.toJson());
}
