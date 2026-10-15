import 'dart:convert';

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

  /// A late drawing save must never resurrect a reset or overwrite another scene.
  Future<bool> replaceIfCurrent(
    StorySnapshot expected,
    StorySnapshot next,
  ) async {
    final raw = await store.read('story');
    if (raw == null ||
        jsonEncode(StorySnapshot.fromJson(raw).toJson()) !=
            jsonEncode(expected.toJson())) {
      return false;
    }
    return store.writeIfUnchanged('story', raw, next.toJson());
  }
}
