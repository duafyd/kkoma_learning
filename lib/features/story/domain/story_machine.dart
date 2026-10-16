import '../../learning/data/learning_content.dart';
import '../../learning/domain/learning_models.dart';
import '../../profile/domain/settings.dart';
import '../../tracing/domain/trace_engine.dart';
import '../data/story_content.dart';
import '../data/support_quizzes.dart';
import 'story_models.dart';
import 'scene_play.dart';
import 'world_mission.dart';
import 'letter_mission.dart';
import 'book_mission.dart';

class StoryMachine {
  final List<StoryEpisode> episodes;
  StoryMachine([List<StoryEpisode>? episodes])
    : episodes = episodes ?? storyEpisodes;
  StoryScene scene(StorySnapshot s) =>
      episodes[s.episode].forLevel(s.level)[s.scene];
  LetterMission? letterMission(StorySnapshot s) =>
      LetterMission.forScene(s, scene(s));
  BookMission? bookMission(StorySnapshot s) {
    final current = scene(s);
    final world = BookMission.worldFor(s, current);
    if (world == null) return null;
    final tracing = current.interaction == StoryPhase.tracing;
    final item = tracing
        ? learningItems.firstWhere((i) => i.id == current.traceId)
        : null;
    return BookMission(
      sceneId: current.id,
      world: world,
      solved: s.phase == StoryPhase.success,
      completed: s.strokes.length,
      total: item?.strokes.length ?? 0,
      observed: s.observedObjects,
      hints: s.hints,
      quiz: tracing ? null : quiz(s),
      symbol: item?.symbol ?? '',
      variation:
          s.flags[current.variationFlag] ??
          s.flags['route'] ??
          s.flags['room'] ??
          '',
    );
  }

  WorldMission? worldMission(StorySnapshot s) =>
      s.supportSceneId == null &&
          [StoryPhase.quiz, StoryPhase.success].contains(s.phase) &&
          scene(s).quiz != null
      ? WorldMission.forQuiz(quiz(s))
      : null;
  String text(StorySnapshot s) {
    if (s.phase == StoryPhase.success && s.message.isNotEmpty) return s.message;
    final play = ScenePlay.forSnapshot(s);
    if (play != null && s.sceneFinds.length == play.count(s.level)) {
      return play.response;
    }
    return s.level == 2 && s.supportSceneId == null
        ? scene(s).exploreText ?? scene(s).text
        : scene(s).text;
  }

  String narration(StorySnapshot s) {
    if (s.phase == StoryPhase.success) return s.message;
    if (s.phase == StoryPhase.quiz) {
      final mission = worldMission(s);
      return mission != null && !canAnswer(s)
          ? '${text(s)} ${mission.instruction}'
          : quiz(s).prompt;
    }
    final play = ScenePlay.forSnapshot(s);
    if (play == null) return text(s);
    return s.sceneFinds.length == play.count(s.level)
        ? play.response
        : '${text(s)} ${play.invitation}';
  }

  /// Exact take identity keeps the same words in different scenes/characters
  /// from borrowing another actor's recording. Dynamic assistance stays TTS.
  String? narrationId(StorySnapshot s) {
    final current = scene(s);
    if (s.phase == StoryPhase.success) {
      if (s.level == 2 && s.message == current.exploreSuccessText) {
        return 'voice-${current.id}-explore-success';
      }
      if (current.successText.isNotEmpty && s.message == current.successText) {
        return 'voice-${current.id}-success';
      }
      if (current.flag != null &&
          current.choices.contains(s.flags[current.flag])) {
        final index = current.choices.indexOf(s.flags[current.flag]!);
        return 'voice-${current.id}-choice-$index';
      }
      return null;
    }
    if (s.phase == StoryPhase.quiz) {
      if (worldMission(s) != null && !canAnswer(s)) {
        return 'voice-${current.id}-world';
      }
      return 'voice-quiz-${quiz(s).id}';
    }
    final play = ScenePlay.forSnapshot(s);
    if (play != null) {
      return s.sceneFinds.length == play.count(s.level)
          ? 'voice-scene-play-${s.episode + 1}-response'
          : 'voice-scene-play-${s.episode + 1}-level-${s.level == 2 ? 2 : 5}';
    }
    return 'voice-${current.id}${s.level == 2 && current.exploreText != null ? '-explore' : ''}';
  }

  String background(StorySnapshot s) {
    final current = scene(s);
    return s.phase == StoryPhase.success
        ? current.successBackgroundVariants[s.flags[current.variationFlag]] ??
              current.successBackground ??
              current.backgroundVariants[s.flags[current.variationFlag]] ??
              current.background
        : current.backgroundVariants[s.flags[current.variationFlag]] ??
              current.background;
  }

  List<StorySpeech> speeches(StorySnapshot s) =>
      scene(s).speechVariants[s.flags[scene(s).variationFlag]] ??
      scene(s).speeches;

  StorySnapshot restore(StorySnapshot s) {
    if (s.episode < 0 || s.episode >= episodes.length) {
      return const StorySnapshot();
    }
    if (s.scene < 0 ||
        s.scene >= episodes[s.episode].forLevel(s.level).length) {
      return StorySnapshot(level: s.level);
    }
    if (s.pendingDrawing != null &&
        (s.phase != StoryPhase.drawing ||
            scene(s).interaction != StoryPhase.drawing)) {
      return restore(s.change({'pendingDrawing': null}));
    }
    final play = ScenePlay.forSnapshot(s);
    s = s.change({
      'sceneFinds': s.sceneFinds
          .where((i) => play != null && i >= 0 && i < play.count(s.level))
          .toList(),
    });
    if (s.observedObjects.isNotEmpty) {
      final art = scene(s).quiz != null ? quiz(s).artwork : null;
      final valid = art != null && art.countOnTap && s.supportSceneId == null
          ? s.observedObjects
                .where((i) => i >= 0 && i < art.objects.length)
                .toList()
          : <int>[];
      return s.change({'observedObjects': valid});
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
    return restore(
      s.change({
        'level': level,
        'scene': index,
        'phase': phase.name,
        'strokes': exact >= 0 ? s.toJson()['strokes'] : [],
        'supportSceneId': exact >= 0 ? s.supportSceneId : null,
        'observedObjects': exact >= 0 ? s.observedObjects : [],
        'sceneFinds': exact >= 0 ? s.sceneFinds : [],
      }),
    );
  }

  StorySnapshot begin(int level) => StorySnapshot(
    level: level,
    phase: episodes.first.forLevel(level).first.interaction,
  );
  QuizDefinition quiz(StorySnapshot s) {
    if (s.supportSceneId == scene(s).id) {
      if (scene(s).interaction == StoryPhase.tracing) {
        final item = learningItems.firstWhere((i) => i.id == scene(s).traceId);
        final alternative = item.subject == 'hangul'
            ? (item.symbol == 'ㄱ' ? 'ㄴ' : 'ㄱ')
            : item.subject == 'english'
            ? (item.symbol == 'A' ? 'B' : 'A')
            : (item.symbol == '1' ? '2' : '1');
        return QuizDefinition(
          id: 'story-support-${item.id}',
          subject: item.subject,
          prompt: '빛나는 글자와 같은 모양을 찾아요',
          visual: item.symbol,
          options: [alternative, item.symbol],
          answer: 1,
          hint: '${item.symbol} 모양을 함께 찾아요.',
        );
      }
      final original = _originalQuiz(s);
      return storySupportQuizzes[original.subject == 'math'
          ? original.kind == QuizKind.order
                ? 'order'
                : original.kind == QuizKind.pattern
                ? 'pattern'
                : original.kind == QuizKind.classify
                ? 'shape'
                : 'math'
          : original.subject]!;
    }
    return _originalQuiz(s);
  }

  QuizDefinition _originalQuiz(StorySnapshot s) {
    if (s.level == 2 && scene(s).exploreQuiz != null) {
      return scene(s).exploreQuiz!;
    }
    final current = scene(s);
    final q =
        current.quizVariants[s.flags[current.variationFlag]] ?? current.quiz!;
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
        'supportSceneId': null,
        'observedObjects': [],
        'sceneFinds': [],
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
      'supportSceneId': null,
      'observedObjects': [],
      'sceneFinds': [],
    });
  }

  StorySnapshot discoverSceneProp(StorySnapshot s, int index) {
    final play = ScenePlay.forSnapshot(s);
    if (play == null ||
        index < 0 ||
        index >= play.count(s.level) ||
        s.sceneFinds.contains(index)) {
      return s;
    }
    return s.change({
      'sceneFinds': [...s.sceneFinds, index],
    });
  }

  StorySnapshot choose(StorySnapshot s, int index) {
    if (s.phase != StoryPhase.choice) return s;
    final current = scene(s);
    if (index < 0 || index >= current.choices.length) return s;
    return s.change({
      'phase': 'success',
      'flags': {...s.flags, current.flag ?? current.id: current.choices[index]},
      'message': current.flag == 'room'
          ? '${current.choices[index]}을 함께 꾸며요!'
          : current.flag == 'route'
          ? '${current.choices[index]}로 함께 가요!'
          : '${current.choices[index]}와 함께 가요!',
    });
  }

  bool canAnswer(StorySnapshot s) {
    if (s.phase != StoryPhase.quiz) return false;
    final art = quiz(s).artwork;
    return art == null ||
        art.arrangement == QuizArrangement.tray ||
        s.observedObjects.length == art.objects.length;
  }

  StorySnapshot answer(StorySnapshot s, int index) {
    if (s.phase != StoryPhase.quiz) return s;
    if (index < 0 || index >= quiz(s).options.length) return s;
    if (!canAnswer(s)) {
      return s.change({'message': '그림 조각을 빈자리에 먼저 놓아봐요. 친구의 도움을 받아도 좋아요.'});
    }
    final accepted = s.level == 2 || quiz(s).accepts(index);
    return s.change({
      'phase': accepted ? 'success' : 'quiz',
      'attempts': s.attempts + 1,
      'hints': accepted ? s.hints : (s.hints + 1).clamp(0, 3),
      'message': accepted
          ? s.level == 2 &&
                    scene(s).exploreQuiz != null &&
                    s.supportSceneId == null
                ? scene(s).exploreSuccessText
                : s.supportSceneId == null && scene(s).successText.isNotEmpty
                ? scene(s).successText
                : '함께 찾았어요! 집중한 모습이 멋져요.'
          : '다른 길도 살펴볼까요?',
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
    if ([StoryPhase.quiz, StoryPhase.tracing].contains(s.phase)) {
      return s.change({
        'phase': 'quiz',
        'supportSceneId': scene(s).id,
        'strokes': [],
        'hints': 0,
        'message': '친구와 작은 미션부터 함께 해요.',
        'observedObjects': [],
      });
    }
    return s;
  }

  StorySnapshot originalMission(StorySnapshot s) =>
      s.phase == StoryPhase.quiz && s.supportSceneId == scene(s).id
      ? s.change({
          'phase': scene(s).interaction.name,
          'supportSceneId': null,
          'strokes': [],
          'hints': 0,
          'message': '원래 미션에 다시 도전해요.',
          'observedObjects': [],
        })
      : s;

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
      'message':
          strokes.length == item.strokes.length &&
              scene(s).successText.isNotEmpty
          ? scene(s).successText
          : '길을 잘 따라갔어요!',
    });
  }

  StorySnapshot drawingComplete(StorySnapshot s) =>
      s.phase == StoryPhase.drawing
      ? s.change({'phase': 'success', 'message': '내 그림이 정원의 지도가 되었어요!'})
      : s;

  StorySnapshot observeObject(StorySnapshot s, int index) {
    if (s.phase != StoryPhase.quiz) return s;
    final artwork = quiz(s).artwork;
    if (artwork == null ||
        !artwork.countOnTap ||
        index < 0 ||
        index >= artwork.objects.length ||
        s.observedObjects.contains(index)) {
      return s;
    }
    final observed = [...s.observedObjects, index];
    return s.change({
      'observedObjects': observed,
      'message': observed.length == artwork.objects.length
          ? '모두 ${observed.length}개예요. 아래 그림에서 골라볼까요?'
          : '${observed.length}개를 함께 세었어요. 다른 ${artwork.objectName}도 눌러봐요.',
    });
  }

  StorySnapshot placeObject(StorySnapshot s, int piece, int slot) {
    if (s.phase != StoryPhase.quiz) return s;
    final art = quiz(s).artwork;
    if (art == null ||
        art.arrangement == QuizArrangement.tray ||
        slot != s.observedObjects.length) {
      return s;
    }
    return observeObject(s, piece);
  }
}
