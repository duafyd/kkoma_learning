import '../../../core/storage/local_store.dart';
import '../domain/story_models.dart';

class StoryRepository {
  final LocalStore store;
  StoryRepository(this.store);
  Future<StorySnapshot?> load() async {
    final j = await store.read('story');
    return j == null ? null : StorySnapshot.fromJson(j);
  }

  Future<void> save(StorySnapshot s) => store.write('story', s.toJson());
}
