import '../../learning/data/learning_content.dart';
import '../../learning/domain/learning_models.dart';
import '../../profile/domain/settings.dart';
import '../../tracing/domain/trace_engine.dart';
import '../../tracing/domain/trace_state.dart';
import '../data/story_content.dart';
import '../data/chapter_direction.dart';
import '../data/support_quizzes.dart';
import 'story_models.dart';
import 'scene_play.dart';
import 'world_mission.dart';
import 'letter_mission.dart';
import 'book_mission.dart';
import 'story_quest.dart';

class StoryMachine {
  final List<StoryEpisode> episodes;
  StoryMachine([List<StoryEpisode>? episodes])
    : episodes = episodes ?? storyEpisodes;
  StoryScene scene(StorySnapshot s) =>
      episodes[s.episode].forLevel(s.level)[s.scene];
  StoryQuest quest(StorySnapshot s) => StoryQuest.from(s, episodes[s.episode]);
  StorySnapshot collectFragment(StorySnapshot s) {
    final progress = quest(s);
    if (!progress.ready || progress.hasFragment) return s;
    return s.change({
      'flags': {...s.flags, StoryQuest.flag(progress.chapter): 'collected'},
      'message':
          '${progress.chapter}번째 별조각을 책의 빈칸에 담았어요! ${progress.collected.length + 1}/12칸이 채워졌어요.',
    });
  }

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
    if (s.phase == StoryPhase.finished) {
      return '열두 조각이 책등의 빈칸에 꼭 맞았어!\n도서관 책이 열렸어. 이제 우리 이야기를 함께 읽자.';
    }
    if (s.phase == StoryPhase.success && s.message.isNotEmpty) {
      if (quest(s).ready &&
          !quest(s).hasFragment &&
          episodes[s.episode].id <= chapterDirections.length) {
        return '${chapterDirections[episodes[s.episode].id - 1].result}\n오른쪽 별조각을 눌러 수집책에 담아 줘.';
      }
      return s.message;
    }
    if (scene(s).id.endsWith('-end') && quest(s).hasFragment) {
      if (s.message.isNotEmpty) return s.message;
      final id = episodes[s.episode].id;
      return '$id번째 조각이 책에 담겼어요.\n${id >= 1 && id <= chapterDirections.length ? chapterDirections[id - 1].next : '다음 장소'}에서 다음 이야기를 만나자.';
    }
    final play = ScenePlay.forSnapshot(s);
    if (play != null && s.sceneFinds.length == play.count(s.level)) {
      return play.response;
    }
    return s.level == 2 && s.supportSceneId == null
        ? scene(s).exploreText ?? scene(s).text
        : scene(s).text;
  }

  String narration(StorySnapshot s) {
    if (s.phase == StoryPhase.success) return text(s);
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
    if (s.phase == StoryPhase.finished ||
        s.phase == StoryPhase.episodeComplete ||
        (current.id.endsWith('-end') && quest(s).hasFragment)) {
      return null;
    }
    if (s.phase == StoryPhase.success) {
      if (text(s) != s.message) return null;
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
          ? 'voice-scene-play-${episodes[s.episode].id}-response'
          : 'voice-scene-play-${episodes[s.episode].id}-level-${s.level == 2 ? 2 : 5}';
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
    final episodeIndex = s.episodeId == null
        ? s.episode
        : episodes.indexWhere((e) => e.id == s.episodeId);
    if (episodeIndex < 0 || episodeIndex >= episodes.length) {
      return _enter(s, 0, 0);
    }
    final episode = episodes[episodeIndex];
    final scenes = episode.forLevel(s.level);
    var index = s.sceneId == null
        ? s.scene
        : scenes.indexWhere((current) => current.id == s.sceneId);
    if (index < 0 || index >= scenes.length) {
      // A known but now ineligible scene moves to the next eligible page.
      // A removed/unknown page restarts this chapter, retaining season choices.
      final authored = episode.scenes.indexWhere((p) => p.id == s.sceneId);
      index = authored < 0
          ? 0
          : scenes.indexWhere((p) => episode.scenes.indexOf(p) > authored);
      return _enter(s, episodeIndex, index < 0 ? scenes.length - 1 : index);
    }
    s = s.change({
      'episode': episodeIndex,
      'episodeId': episode.id,
      'scene': index,
      'sceneId': scenes[index].id,
      'attempts': s.attempts.clamp(0, 1000000000),
      'hints': s.hints.clamp(0, 3),
    });
    final current = scene(s);
    final support =
        s.supportSceneId == current.id &&
        [StoryPhase.quiz, StoryPhase.tracing].contains(current.interaction);
    final terminal =
        index == scenes.length - 1 &&
        (s.phase == StoryPhase.episodeComplete ||
            (s.phase == StoryPhase.finished &&
                episodeIndex == episodes.length - 1));
    if ((s.supportSceneId != null && !support) ||
        !(s.phase == current.interaction ||
            s.phase == StoryPhase.success ||
            terminal ||
            (support && s.phase == StoryPhase.quiz))) {
      return _enter(s, episodeIndex, index);
    }
    if (current.interaction == StoryPhase.tracing && !support && !terminal) {
      final item = learningItems.firstWhere((i) => i.id == current.traceId);
      final ink = TraceState.restore({
        'strokeIndex': s.strokes.length,
        'completed': s.toJson()['strokes'],
      }, item.strokes.length);
      if (ink.completed.length != s.strokes.length ||
          (s.phase == StoryPhase.success && !s.assisted && !ink.done)) {
        return _enter(s, episodeIndex, index);
      }
      s = s.change({
        'strokes': ink.toJson()['completed'],
        if (s.phase == StoryPhase.tracing && ink.done) ...{
          'phase': 'success',
          'message': current.successText.isNotEmpty
              ? current.successText
              : '길을 잘 따라갔어요!',
        },
      });
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

  StorySnapshot _enter(StorySnapshot s, int episode, int index) {
    final current = episodes[episode].forLevel(s.level)[index];
    return s.change({
      'episode': episode,
      'episodeId': episodes[episode].id,
      'scene': index,
      'sceneId': current.id,
      'phase': current.interaction.name,
      'attempts': 0,
      'hints': 0,
      'strokes': [],
      'assisted': false,
      'message': '',
      'supportSceneId': null,
      'observedObjects': [],
      'sceneFinds': [],
      'pendingDrawing': null,
    });
  }

  StorySnapshot relevel(StorySnapshot s, int level) {
    s = restore(s);
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
    if (exact < 0) return _enter(s.change({'level': level}), s.episode, index);
    return restore(
      s.change({
        'level': level,
        'scene': index,
        'sceneId': newScenes[index].id,
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
    episodeId: episodes.first.id,
    sceneId: episodes.first.forLevel(level).first.id,
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
    // The next-page button is an explicit alternative to tapping the fragment.
    s = collectFragment(s);
    if (s.phase == StoryPhase.episodeComplete) {
      if (s.episode == episodes.length - 1) {
        return s.change({
          'phase': 'finished',
          'message': '별조각 12개로 책등의 빈칸을 모두 채웠어요!',
        });
      }
      final next = s.episode + 1;
      return _enter(s, next, 0);
    }
    if (s.phase != StoryPhase.dialogue && s.phase != StoryPhase.success) {
      return s;
    }
    final scenes = episodes[s.episode].forLevel(s.level);
    if (s.scene + 1 == scenes.length) {
      return s.change({
        'phase': 'episodeComplete',
        'completed': {...s.completed, episodes[s.episode].id}.toList(),
        'message': '${episodes[s.episode].id}번째 별조각을 책에 담았어요. 빈칸이 하나 채워졌어요!',
      });
    }
    return _enter(s, s.episode, s.scene + 1);
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
