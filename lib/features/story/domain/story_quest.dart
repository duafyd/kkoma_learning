import 'story_models.dart';

/// A projection of saved linear story progress, not a second progress store.
class StoryQuest {
  final int chapter, done, total;
  final Set<int> collected;
  final bool ready;
  const StoryQuest({
    required this.chapter,
    required this.done,
    required this.total,
    required this.collected,
    required this.ready,
  });
  bool get hasFragment => collected.contains(chapter);
  static String flag(int chapter) => 'book-fragment-$chapter';

  /// The book and map share one projection, including pre-fragment saves.
  static Set<int> collectedFrom(StorySnapshot s) => {
    ...s.completed.where((i) => i >= 1 && i <= 12),
    for (var i = 1; i <= 12; i++)
      if (s.flags[flag(i)] == 'collected') i,
  };
  factory StoryQuest.from(StorySnapshot s, StoryEpisode episode) {
    final pages = episode.forLevel(s.level);
    final tasks = [
      for (var i = 0; i < pages.length; i++)
        if ([
          StoryPhase.quiz,
          StoryPhase.tracing,
          StoryPhase.drawing,
        ].contains(pages[i].interaction))
          i,
    ];
    final done = tasks
        .where(
          (i) => i < s.scene || (i == s.scene && s.phase == StoryPhase.success),
        )
        .length;
    return StoryQuest(
      chapter: episode.id,
      done: done,
      total: tasks.length,
      collected: collectedFrom(s),
      ready: tasks.isNotEmpty && done == tasks.length,
    );
  }
}
