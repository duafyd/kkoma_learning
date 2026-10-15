import '../../learning/data/learning_content.dart';
import '../../learning/domain/learning_models.dart';
import '../../profile/domain/settings.dart';
import '../../tracing/domain/trace_engine.dart';
import '../data/story_content.dart';
import 'story_models.dart';

class StoryMachine {
  final List<StoryEpisode> episodes;
  StoryMachine([List<StoryEpisode>? episodes])
    : episodes = episodes ?? storyEpisodes;
  StoryScene scene(StorySnapshot s) =>
      episodes[s.episode].forLevel(s.level)[s.scene];
  StorySnapshot restore(StorySnapshot s) {
    if (s.episode < 0 || s.episode >= episodes.length) {
      return const StorySnapshot();
    }
    if (s.scene < 0 ||
        s.scene >= episodes[s.episode].forLevel(s.level).length) {
      return StorySnapshot(level: s.level);
    }
    return s;
  }

  StorySnapshot relevel(StorySnapshot s, int level) {
    if (s.level == level) return s;
    final episode = episodes[s.episode],
        newScenes = episodes[s.episode].forLevel(level);
    final oldScene = scene(s);
    final oldIndex = episode.scenes.indexWhere(
      (current) => current.id == oldScene.id,
    );
    final exact = newScenes.indexWhere((current) => current.id == oldScene.id);
    final next = exact >= 0
        ? exact
        : newScenes.indexWhere(
            (current) => episode.scenes.indexOf(current) > oldIndex,
          );
    final index = next >= 0 ? next : newScenes.length - 1;
    final phase = exact >= 0 ? s.phase : newScenes[index].interaction;
    return s.change({
      'level': level,
      'scene': index,
      'phase': phase.name,
      'strokes': exact >= 0 ? s.toJson()['strokes'] : [],
    });
  }

  StorySnapshot begin(int level) => StorySnapshot(
    level: level,
    phase: episodes.first.forLevel(level).first.interaction,
  );
  QuizDefinition quiz(StorySnapshot s) {
    if (s.episode == 8) {
      return quizById(
        s.flags['route'] == '영어 길'
            ? 'e-apple'
            : s.flags['route'] == '숫자 길'
            ? 'count2'
            : 'h-bag',
      );
    }
    final q = scene(s).quiz!;
    if (q.minimumLevel > s.level && s.level >= 3) {
      return quizById(
        q.subject == 'hangul'
            ? 'h-bag'
            : q.subject == 'english'
            ? 'e-apple'
            : 'count2',
      );
    }
    return q;
  }

  StorySnapshot advance(StorySnapshot s) {
    if (s.phase == StoryPhase.finished) return s;
    if (s.phase == StoryPhase.episodeComplete) {
      if (s.episode == episodes.length - 1) {
        return s.change({'phase': 'finished', 'message': '모든 별빛을 모았어요!'});
      }
      final next = s.episode + 1;
      return s.change({
        'episode': next,
        'scene': 0,
        'phase': episodes[next].forLevel(s.level).first.interaction.name,
        'attempts': 0,
        'hints': 0,
        'strokes': [],
        'assisted': false,
        'message': '',
      });
    }
    if (s.phase != StoryPhase.dialogue && s.phase != StoryPhase.success) {
      return s;
    }
    final scenes = episodes[s.episode].forLevel(s.level);
    if (s.scene + 1 == scenes.length) {
      return s.change({
        'phase': 'episodeComplete',
        'completed': {...s.completed, s.episode + 1}.toList(),
        'message': '별빛 ${s.episode + 1}을 모았어요!',
      });
    }
    return s.change({
      'scene': s.scene + 1,
      'phase': scenes[s.scene + 1].interaction.name,
      'attempts': 0,
      'hints': 0,
      'strokes': [],
      'assisted': false,
      'message': '',
    });
  }

  StorySnapshot choose(StorySnapshot s, int index) {
    if (s.phase != StoryPhase.choice) return s;
    final current = scene(s);
    if (index < 0 || index >= current.choices.length) return s;
    return s.change({
      'phase': 'success',
      'flags': {...s.flags, current.flag ?? current.id: current.choices[index]},
      'message': '${current.choices[index]}과 함께 가요!',
    });
  }

  StorySnapshot answer(StorySnapshot s, int index) {
    if (s.phase != StoryPhase.quiz) return s;
    if (index < 0 || index >= quiz(s).options.length) return s;
    final accepted = s.level == 2 || quiz(s).accepts(index);
    return s.change({
      'phase': accepted ? 'success' : 'quiz',
      'attempts': s.attempts + 1,
      'hints': accepted ? s.hints : (s.hints + 1).clamp(0, 3),
      'message': accepted ? '함께 찾았어요! 집중한 모습이 멋져요.' : '다른 길도 살펴볼까요?',
    });
  }

  StorySnapshot hint(StorySnapshot s) {
    if (![StoryPhase.quiz, StoryPhase.tracing].contains(s.phase)) return s;
    return s.change({
      'hints': (s.hints + 1).clamp(0, 3),
      'message': s.phase == StoryPhase.quiz
          ? quiz(s).hint
          : '빛나는 점에서 화살표를 따라 천천히 움직여요.',
    });
  }

  StorySnapshot easier(StorySnapshot s) {
    if (s.phase == StoryPhase.quiz) {
      return s.change({'hints': 3, 'message': '빛나는 답을 함께 눌러요.'});
    }
    if (s.phase == StoryPhase.tracing) {
      return s.change({'hints': 3, 'message': '넓어진 길에서 함께 그려요.'});
    }
    return s;
  }

  StorySnapshot assist(StorySnapshot s, ParentSettings settings) {
    if (!settings.help ||
        s.attempts < settings.helpAfter ||
        ![StoryPhase.quiz, StoryPhase.tracing].contains(s.phase)) {
      return s;
    }
    return s.change({
      'phase': 'success',
      'assisted': true,
      'message': '친구와 함께 해냈어요!',
    });
  }

  StorySnapshot trace(StorySnapshot s, List<TracePoint> input) {
    if (s.phase != StoryPhase.tracing) return s;
    final item = learningItems.firstWhere((i) => i.id == scene(s).traceId);
    if (s.strokes.length >= item.strokes.length) return s;
    final level = s.hints >= 3 ? 2 : s.level;
    final result = TraceStrategy(AgeStrategy(level))
        .evaluate(item.strokes[s.strokes.length], input);
    if (!result.accepted) {
      return s.change({
        'attempts': s.attempts + 1,
        'hints': (s.hints + 1).clamp(0, 3),
        'message': '빛나는 점에서 천천히 다시 해 볼까요?',
      });
    }
    final strokes = [...s.strokes, input];
    return s.change({
      'strokes': strokes
          .map((line) => line.map((p) => p.toJson()).toList())
          .toList(),
      'phase': strokes.length == item.strokes.length ? 'success' : 'tracing',
      'message': '길을 잘 따라갔어요!',
    });
  }

  StorySnapshot drawingComplete(StorySnapshot s) =>
      s.phase == StoryPhase.drawing
      ? s.change({'phase': 'success', 'message': '내 그림이 정원의 지도가 되었어요!'})
      : s;
}
