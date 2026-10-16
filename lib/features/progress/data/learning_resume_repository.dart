import '../../../core/storage/local_store.dart';
import '../../learning/data/learning_content.dart';
import '../../learning/domain/learning_session.dart';
import '../../profile/domain/settings.dart';
import '../../tracing/data/trace_catalog.dart';
import '../../tracing/domain/trace_state.dart';
import '../domain/learning_resume.dart';

/// Read-only; timestamps share the primary session/ink write, with no bookmark
/// document that could survive a reset or get ahead of a failed checkpoint.
class LearningResumeRepository {
  final LocalStore store;
  const LearningResumeRepository(this.store);
  Future<List<LearningResumeTarget>> load(ParentSettings settings) async {
    final docs = await store.readMany([
      for (final item in traceItems) 'trace-${item.id}',
      for (final subject in ['hangul', 'english', 'math']) 'session-$subject',
    ]);
    DateTime timestamp(Map<String, dynamic> doc) =>
        (doc['_updatedAt'] is String
            ? DateTime.tryParse(doc['_updatedAt'] as String)
            : null) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    LearningResumeTarget? tracing, quiz;
    for (final item in traceItems) {
      if (item.minimumLevel > settings.level) continue;
      final raw = docs['trace-${item.id}'];
      if (raw == null) continue;
      final saved = TraceState.restore(raw, item.strokes.length);
      if (saved.done || saved.strokeIndex == 0) {
        continue;
      }
      final target = LearningResumeTarget(
        kind: LearningResumeKind.tracing,
        title: '${item.symbol} 이어 그리기',
        detail: '${saved.strokeIndex + 1}번째 획부터 함께 해요',
        location: Uri(pathSegments: ['', 'trace', item.id]).toString(),
        updatedAt: timestamp(raw),
      );
      if (tracing == null || target.updatedAt.isAfter(tracing.updatedAt)) {
        tracing = target;
      }
    }
    for (final subject in ['hangul', 'english', 'math']) {
      final raw = docs['session-$subject'];
      if (raw == null || raw['baseLevel'] != settings.level) continue;
      try {
        final old = LearningSession.fromJson(raw);
        final capped = settings.autoAdvanceLearning
            ? old
            : old.cappedAt(settings.level);
        final available = learningQuizzes
            .where(
              (q) => q.subject == subject && q.minimumLevel <= capped.level,
            )
            .toList();
        if (available.isEmpty) continue;
        final saved = capped.restoredFor(available);
        if (capped.quizId != null && capped.quizId != saved.quizId) {
          continue;
        }
        final question = saved.question(available);
        final name = {'hangul': '한글', 'english': '영어', 'math': '숫자'}[subject]!;
        final target = LearningResumeTarget(
          kind: LearningResumeKind.quiz,
          title: '$name 함께 찾기 이어하기',
          detail: saved.answered ? '함께 해냈어요! 다음 놀이가 기다려요' : question.prompt,
          location: '/learn/$subject?mode=quiz',
          updatedAt: timestamp(raw),
        );
        if (quiz == null || target.updatedAt.isAfter(quiz.updatedAt)) {
          quiz = target;
        }
      } on TypeError {
        continue;
      }
    }
    final result = [?tracing, ?quiz]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(result);
  }
}
