import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../learning/data/learning_content.dart';
import '../../story/data/story_content.dart';
import '../../tracing/data/prewriting_content.dart';
import '../domain/learning_overview.dart';

final learningOverviewProvider = Provider.family<LearningOverview, int>(
  (ref, level) => LearningOverview(
    level: level,
    items: learningItems,
    quizzes: learningQuizzes,
    readiness: prewritingItems,
    episodes: storyEpisodes,
  ),
);
