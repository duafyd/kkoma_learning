import 'dart:typed_data';

import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/learning/domain/learning_models.dart';
import 'package:flutter_application_1/features/learning/domain/learning_speech.dart';
import 'package:flutter_application_1/features/math/data/sorting_content.dart';
import 'package:flutter_application_1/features/story/data/story_content.dart';
import 'package:flutter_application_1/features/story/data/support_quizzes.dart';
import 'package:flutter_application_1/features/story/domain/story_machine.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/domain/scene_play.dart';

class VoiceLine {
  final String id, text, language, category;
  final Set<String> contexts, review;
  VoiceLine(
    this.id,
    this.text,
    this.language,
    this.category,
    String context,
    Iterable<String> notes,
  ) : contexts = {context},
      review = {...notes};
  Iterable<StoryScene> get storyScenes sync* {
    for (final episode in storyEpisodes) {
      for (final scene in episode.scenes) {
        if (contexts.any(
              (c) =>
                  c == 'story:${scene.id}' ||
                  c.startsWith('story:${scene.id}:'),
            ) ||
            contexts.any((c) => c.startsWith('story:episode-${episode.id}:')) &&
                scene == episode.scenes.first) {
          yield scene;
        }
      }
    }
  }

  String get speaker {
    if (['story-sample', 'count'].contains(category)) return '학습 안내';
    final actors = storyScenes.map((s) => s.character).toSet();
    return actors.length == 1 ? actors.single : '학습 안내';
  }

  String get emotion {
    if (['story-success', 'story-choice'].contains(category) ||
        id.endsWith('-response')) {
      return '함께 해낸 기쁨';
    }
    final reactions = storyScenes.map((s) => s.reaction).toSet();
    if (reactions.contains(StoryReaction.search)) return '다정한 호기심';
    if (reactions.contains(StoryReaction.celebrate)) return '안도와 반가움';
    return '따뜻한 초대';
  }

  Map<String, dynamic> get performance => {
    'speaker': speaker,
    'emotion': emotion,
    'delivery': switch (speaker) {
      '루루' => '호기심 많은 친구. 밝고 생동감 있게, 소리 지르거나 아기 말투를 과장하지 않는다.',
      '토토' => '차분하고 든든한 친구. 낱말과 수량을 또렷하게, 느려도 답답하지 않게.',
      '휙휙' => '장난기 있는 바람 친구. 가벼운 리듬, 사과 장면은 진심을 담아 작고 따뜻하게.',
      '모아' => '포근한 이야기 길잡이. 설명을 읽기보다 아이 눈높이에서 말을 건넨다.',
      _ => '그림책의 차분한 안내자. 글자 이름·단어·개수를 정확하게 구분한다.',
    },
    'pacing': '문장 사이 350~550ms, 질문 뒤 600~900ms 여운. 줄바꿈을 말로 읽지 않는다. 기본 속도를 일괄 늘리지 않는다.',
    'recording': '효과음·음악 없는 건조한 원본. 장면마다 동일 캐스팅. 연기 지시문을 음성에 포함하지 않는다.',
    'listeningReview': 'pending',
  };
  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'language': language,
    'category': category,
    'contexts': contexts.toList()..sort(),
    'review': review.toList()..sort(),
    'file': 'assets/audio/$id.wav',
    'listeningReview': 'pending',
    'performance': performance,
  };
}

List<VoiceLine> buildVoiceCatalog() {
  final lines = <String, VoiceLine>{};
  void add(
    String id,
    String text,
    String language,
    String category,
    String context, [
    List<String> notes = const [],
  ]) {
    if (text.trim().isEmpty ||
        !['ko-KR', 'en-US'].contains(language) ||
        id.contains(RegExp(r'[/\\:*?"<>|]'))) {
      throw FormatException('invalid voice line $id');
    }
    final old = lines[id];
    if (old != null) {
      if (old.text != text || old.language != language) {
        throw FormatException('conflicting voice line $id');
      }
      old.contexts.add(context);
      old.review.addAll(notes);
    } else {
      lines[id] = VoiceLine(id, text, language, category, context, notes);
    }
  }

  void quiz(QuizDefinition q, String context) => add(
    'voice-quiz-${q.id}',
    q.prompt,
    'ko-KR',
    'quiz',
    context,
    ['정답을 먼저 말하지 않기', '그림의 수량·모양과 지시 일치'],
  );
  for (final item in learningItems) {
    final notes = item.subject == 'english'
        ? [
            '알파벳 이름과 대표 단어를 구분',
            '첫소리만 분리한 녹음이 아님',
            if (item.symbol.toUpperCase() == 'X')
              'Fox의 x는 끝소리: 첫소리 예시로 안내하지 않기',
          ]
        : item.subject == 'hangul'
        ? ['자음 이름·모음 소리·단어 구분']
        : ['숫자 이름과 사물 개수 읽기를 구분'];
    add(
      'voice-${item.id}',
      learningListeningText(item),
      item.language,
      'learning',
      'learning:${item.id}',
      notes,
    );
    add(
      'voice-${item.id}-name',
      learningLetterName(item),
      item.language,
      'trace-name',
      'trace:${item.id}',
      notes,
    );
  }
  for (final q in learningQuizzes) {
    quiz(q, 'learning-quiz:${q.id}');
  }
  for (final q in storySupportQuizzes.values) {
    quiz(q, 'story-support:${q.id}');
  }
  final machine = StoryMachine();
  for (var ep = 0; ep < storyEpisodes.length; ep++) {
    final episode = storyEpisodes[ep];
    final play = ScenePlay.moments[ep];
    add(
      'voice-scene-play-${ep + 1}-response',
      play.response,
      'ko-KR',
      'scene-play',
      'story:episode-${ep + 1}:found',
    );
    for (final level in [2, 5]) {
      final state = StorySnapshot(episode: ep, level: level);
      add(
        'voice-scene-play-${ep + 1}-level-$level',
        machine.narration(state),
        'ko-KR',
        'scene-play',
        'story:episode-${ep + 1}:level-$level',
      );
      final found = state.change({
        'sceneFinds': List.generate(play.count(level), (i) => i),
      });
      add(
        'voice-scene-play-${ep + 1}-level-$level-restored',
        machine.narration(found),
        'ko-KR',
        'scene-play',
        'story:episode-${ep + 1}:level-$level:restored',
      );
    }
    for (var index = 0; index < episode.scenes.length; index++) {
      final s = episode.scenes[index],
          context = 'story:${episode.scenes[index].id}';
      add('voice-${s.id}', s.text, 'ko-KR', 'story-dialogue', context, [
        '짧은 문장 사이 쉬기',
        '화자의 감정·장면 일치',
      ]);
      if (s.interaction == StoryPhase.quiz) {
        final state = StorySnapshot(
          episode: ep,
          scene: index,
          level: 5,
          phase: StoryPhase.quiz,
        );
        if (machine.worldMission(state) != null) {
          add(
            'voice-${s.id}-world',
            machine.narration(state),
            'ko-KR',
            'world-mission',
            '$context:place-before-count',
          );
        }
      }
      if (s.exploreText != null) {
        add(
          'voice-${s.id}-explore',
          s.exploreText!,
          'ko-KR',
          'story-explore',
          '$context:age2',
          ['만 2세에게 정답을 요구하지 않기'],
        );
      }
      if (s.successText.isNotEmpty) {
        add(
          'voice-${s.id}-success',
          s.successText,
          'ko-KR',
          'story-success',
          '$context:success',
        );
      }
      if (s.exploreQuiz != null) {
        quiz(s.exploreQuiz!, '$context:age2');
        add(
          'voice-${s.id}-explore-success',
          s.exploreSuccessText,
          'ko-KR',
          'story-success',
          '$context:age2:success',
        );
      }
      if (s.quiz != null) quiz(s.quiz!, context);
      for (final entry in s.quizVariants.entries) {
        quiz(entry.value, '$context:${s.variationFlag}=${entry.key}');
      }
      void sample(StorySpeech sample, String location) => add(
        'voice-story-${sample.id}',
        sample.text,
        sample.language,
        'story-sample',
        location,
        ['이름·소리·단어 버튼의 학습 목표 일치'],
      );
      for (final speech in s.speeches) {
        sample(speech, context);
      }
      for (final entry in s.speechVariants.entries) {
        for (final speech in entry.value) {
          sample(speech, '$context:${s.variationFlag}=${entry.key}');
        }
      }
      if (s.interaction == StoryPhase.tracing) {
        final state = StorySnapshot(
          episode: ep,
          scene: index,
          level: 5,
          phase: StoryPhase.tracing,
        );
        quiz(machine.quiz(machine.easier(state)), '$context:trace-support');
      }
      for (var choice = 0; choice < s.choices.length; choice++) {
        final state = StorySnapshot(
          episode: ep,
          scene: index,
          level: 5,
          phase: StoryPhase.choice,
        );
        add(
          'voice-${s.id}-choice-$choice',
          machine.choose(state, choice).message,
          'ko-KR',
          'story-choice',
          '$context:choice=$choice',
        );
      }
    }
  }
  for (var level = 2; level <= 5; level++) {
    for (final round in sortingRounds(level)) {
      add(
        'voice-sorting-${round.id}',
        round.prompt,
        'ko-KR',
        'sorting',
        'sorting:level$level:${round.id}',
      );
    }
  }
  for (var count = 1; count <= 5; count++) {
    add(
      'voice-count-$count',
      '$count개',
      'ko-KR',
      'count',
      'story:count-on-tap',
      ['한 개·두 개·세 개·네 개·다섯 개로 읽기'],
    );
  }
  return lines.values.toList()..sort((a, b) => a.id.compareTo(b.id));
}

/// File validation only; a valid PCM WAV still requires human listening review.
String? validateVoiceWav(Uint8List bytes) {
  if (bytes.length < 44) return 'WAV header truncated';
  String tag(int at) => String.fromCharCodes(bytes.sublist(at, at + 4));
  final data = ByteData.sublistView(bytes);
  if (tag(0) != 'RIFF' || tag(8) != 'WAVE') return 'not a RIFF WAVE file';
  if (data.getUint32(4, Endian.little) + 8 != bytes.length) {
    return 'RIFF length mismatch';
  }
  int? rate, channels, bits, alignment;
  var pcm = false, samples = 0;
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final size = data.getUint32(offset + 4, Endian.little), start = offset + 8;
    if (start + size > bytes.length) return 'WAV chunk truncated';
    if (tag(offset) == 'fmt ') {
      if (size < 16) return 'WAV format truncated';
      pcm = data.getUint16(start, Endian.little) == 1;
      channels = data.getUint16(start + 2, Endian.little);
      rate = data.getUint32(start + 4, Endian.little);
      alignment = data.getUint16(start + 12, Endian.little);
      bits = data.getUint16(start + 14, Endian.little);
      if (rate * alignment != data.getUint32(start + 8, Endian.little)) {
        return 'WAV byte rate mismatch';
      }
    }
    if (tag(offset) == 'data') samples += size;
    offset = start + size + size % 2;
  }
  if (offset != bytes.length) return 'WAV chunk header or padding truncated';
  if (!pcm ||
      channels != 1 ||
      bits != 16 ||
      alignment != 2 ||
      rate == null ||
      rate < 16000 ||
      rate > 48000) {
    return 'expected mono PCM16, 16000–48000 Hz';
  }
  if (samples == 0 || samples % 2 != 0) return 'missing or incomplete samples';
  if (samples / (rate * 2) > 60) {
    return 'voice clip exceeds 60 seconds; split script';
  }
  return null;
}
