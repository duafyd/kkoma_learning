import '../../../core/audio/sound_assets.dart';
import 'story_models.dart';

/// Presentation cues are derived from committed state, never from a button tap.
class StoryCues {
  static String pageId(StorySnapshot s) => '${s.episode}:${s.scene}';

  static StorySound? between(StorySnapshot? before, StorySnapshot after) {
    if (before == null) {
      return null; // Restore is silent; rewards are not replayed.
    }
    if (pageId(before) != pageId(after)) return StorySound.pageTurn;
    if (before.observedObjects.length < after.observedObjects.length) {
      return StorySound.friend;
    }
    if (before.phase != after.phase &&
        [
          StoryPhase.success,
          StoryPhase.episodeComplete,
          StoryPhase.finished,
        ].contains(after.phase)) {
      return StorySound.sparkle;
    }
    if (before.flags['companion'] != after.flags['companion']) {
      return StorySound.friend;
    }
    return null;
  }
}
