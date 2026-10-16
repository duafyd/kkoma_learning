import '../../learning/domain/learning_models.dart';
import '../../profile/domain/settings.dart';
import '../../story/domain/story_models.dart';
import '../../tracing/domain/prewriting_strategy.dart';
import '../../tracing/domain/trace_engine.dart';

/// The configured starting path, independent of saved adaptive quiz sessions.
class LearningOverview {
  final int level;
  final Map<String, List<LearningItem>> subjects;
  final Map<String, int> quizCounts;
  final Map<String, List<QuizDefinition>> questions;
  final List<LearningItem> prewriting;
  final List<({String title, int sceneCount})> chapters;

  LearningOverview({
    required this.level,
    required List<LearningItem> items,
    required List<QuizDefinition> quizzes,
    required List<LearningItem> readiness,
    required List<StoryEpisode> episodes,
  }) : subjects = Map.unmodifiable({
         for (final subject in ['hangul', 'english', 'math'])
           subject: List<LearningItem>.unmodifiable(
             items.where(
               (item) => item.subject == subject && item.minimumLevel <= level,
             ),
           ),
       }),
       quizCounts = Map.unmodifiable({
         for (final subject in ['hangul', 'english', 'math'])
           subject: quizzes
               .where((q) => q.subject == subject && q.minimumLevel <= level)
               .length,
       }),
       questions = Map.unmodifiable({
         for (final subject in ['hangul', 'english', 'math'])
           subject: List<QuizDefinition>.unmodifiable(
             quizzes.where(
               (q) => q.subject == subject && q.minimumLevel <= level,
             ),
           ),
       }),
       prewriting = List.unmodifiable(
         readiness.where((item) => item.minimumLevel <= level),
       ),
       chapters = List.unmodifiable([
         for (final episode in episodes)
           (title: episode.title, sceneCount: episode.forLevel(level).length),
       ]);

  TraceStrategy strategyFor(LearningItem item) => item.subject == 'prewriting'
      ? PrewritingStrategy(AgeStrategy(level))
      : TraceStrategy(AgeStrategy(level));
}
