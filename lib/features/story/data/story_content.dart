import '../../learning/data/learning_content.dart';
import '../../learning/domain/learning_models.dart';
import 'episode_one.dart';
import 'episode_two.dart';
import 'episode_three.dart';
import 'episode_four.dart';
import 'episode_five.dart';
import 'episode_six.dart';
import 'episode_seven.dart';
import 'episode_eight.dart';
import 'episode_nine.dart';
import 'episode_ten.dart';
import 'episode_eleven.dart';
import 'episode_twelve.dart';

QuizDefinition quizById(String id) =>
    learningQuizzes.firstWhere((q) => q.id == id);

const storyEpisodes = [
  episodeOne,
  episodeTwo,
  episodeThree,
  episodeFour,
  episodeFive,
  episodeSix,
  episodeSeven,
  episodeEight,
  episodeNine,
  episodeTen,
  episodeEleven,
  episodeTwelve,
];
