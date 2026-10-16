import 'story_models.dart';

/// Check authored data before exporting or publishing; not educational approval.
List<String> validateStoryCatalog(
  Iterable<StoryEpisode> episodes, {
  required Set<String> traceIds,
}) {
  final issues = <String>[];
  final episodeIds = <int>{}, sceneIds = <String>{};
  final catalog = episodes.toList();
  if (catalog.isEmpty) issues.add('empty story catalog');
  for (final episode in catalog) {
    final label = 'episode ${episode.id}';
    if (episode.id <= 0 || !episodeIds.add(episode.id)) {
      issues.add('$label: invalid or duplicate episode ID');
    }
    if ([
      episode.title,
      episode.goal,
      episode.reward,
    ].any((s) => s.trim().isEmpty)) {
      issues.add('$label: missing title, goal or reward');
    }
    for (var level = 2; level <= 5; level++) {
      if (episode.forLevel(level).isEmpty) {
        issues.add('$label: no playable scene at level $level');
      }
    }
    for (final scene in episode.scenes) {
      final page = '$label / ${scene.id}';
      if (scene.id.trim().isEmpty ||
          scene.id != scene.id.trim() ||
          !sceneIds.add(scene.id)) {
        issues.add('$page: empty, padded or duplicate scene ID');
      }
      if (scene.minimumLevel < 2 || scene.minimumLevel > 5) {
        issues.add('$page: invalid minimum level');
      }
      if (scene.text.trim().isEmpty) issues.add('$page: missing dialogue');
      switch (scene.interaction) {
        case StoryPhase.dialogue:
        case StoryPhase.drawing:
          break;
        case StoryPhase.quiz:
          if (scene.quiz == null) issues.add('$page: missing quiz');
          if (scene.quizVariants.isNotEmpty &&
              (scene.variationFlag == null ||
                  scene.variationFlag!.trim().isEmpty)) {
            issues.add('$page: quiz variants have no selection flag');
          }
        case StoryPhase.tracing:
          if (!traceIds.contains(scene.traceId)) {
            issues.add('$page: unknown tracing item ${scene.traceId}');
          }
        case StoryPhase.choice:
          final choices = scene.choices.map((s) => s.trim()).toList();
          if (choices.length < 2 ||
              choices.any((s) => s.isEmpty) ||
              choices.toSet().length != choices.length) {
            issues.add('$page: empty or duplicate choices');
          }
        case StoryPhase.success:
        case StoryPhase.episodeComplete:
        case StoryPhase.finished:
          issues.add('$page: runtime phase cannot be an authored interaction');
      }
    }
  }
  return issues;
}
