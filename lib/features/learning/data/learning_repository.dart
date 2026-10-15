import '../../../core/storage/local_store.dart';
import '../domain/learning_session.dart';

class LearningRepository {
  final LocalStore store;
  LearningRepository(this.store);
  Future<LearningSession> load(String subject, int level) async {
    final saved = await store.read('session-$subject');
    if (saved == null || saved['baseLevel'] != level) {
      return LearningSession(level: level, baseLevel: level);
    }
    return LearningSession.fromJson(saved);
  }

  Future<void> save(String subject, LearningSession s) =>
      store.write('session-$subject', s.toJson());
}
