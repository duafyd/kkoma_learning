import '../domain/story_models.dart';
import 'finale_quizzes.dart' as q;
import 'episode_four.dart';
import 'episode_five.dart';

const routeFirstQuizzes = {
  '한글 길': q.routeHangul,
  '영어 길': q.routeEnglish,
  '숫자 길': q.routeMath,
};
const routeReviewQuizzes = {
  '한글 길': q.routeHangulReview,
  '영어 길': q.routeEnglishReview,
  '숫자 길': q.routeMathReview,
};
const routeTogetherQuizzes = {
  '한글 길': q.routeHangulTogether,
  '영어 길': q.routeEnglishTogether,
  '숫자 길': q.routeMathTogether,
};
const routeSounds = {
  '한글 길': trainSyllableSounds,
  '영어 길': lighthouseSounds,
  '숫자 길': <StorySpeech>[],
};
const routeReviewSounds = {
  '한글 길': [StorySpeech(id: 'vowel-o-sound', label: '오 소리 듣기', text: '오')],
  '영어 길': [
    StorySpeech(
      id: 'letter-a-name',
      label: 'A 이름 듣기',
      text: 'A',
      language: 'en-US',
    ),
  ],
  '숫자 길': <StorySpeech>[],
};

const episodeNine = StoryEpisode(
  id: 9,
  title: '세 갈래 이야기 길',
  goal: '내가 고른 길에서 서로 다른 복습 미션을 만나요',
  reward: '별빛 9',
  scenes: [
    StoryScene(
      id: 'ep9-start',
      text: '꽃길, 등대길, 돌길이 나란히 보여요.\n어느 길로 가도 친구와 함께라면 좋아요!',
      background: 'ep9-fork',
      reaction: StoryReaction.point,
    ),
    StoryScene(
      id: 'ep9-discover',
      text: '꽃길엔 한글, 등대길엔 영어, 돌길엔 숫자!\n내가 기억하는 이야기는 어느 길에 있을까?',
      background: 'ep9-fork',
      minimumLevel: 3,
      character: '루루',
    ),
    StoryScene(
      id: 'ep9-choice',
      text: '어느 이야기 길로 먼저 가볼까요?',
      background: 'ep9-fork',
      interaction: StoryPhase.choice,
      choices: ['한글 길', '영어 길', '숫자 길'],
      flag: 'route',
    ),
    StoryScene(
      id: 'ep9-quiz',
      text: '우리가 고른 길의 이야기를 떠올려요.\n그림과 소리를 천천히 살펴봐요.',
      background: 'ep9-fork',
      interaction: StoryPhase.quiz,
      reaction: StoryReaction.point,
      quiz: q.routeHangul,
      variationFlag: 'route',
      quizVariants: routeFirstQuizzes,
      speechVariants: routeSounds,
      successBackground: 'ep9-joined',
      successText: '기억 속의 조각을 찾았어요! 세 길이 반짝이며 종이숲 쪽으로 이어져요.',
      exploreQuiz: q.ep9Explore,
      exploreText: '꽃도 별도 우리를 반겨요.\n좋아하는 그림을 골라 길을 밝혀요.',
      exploreSuccessText: '좋아하는 빛을 찾았어요! 친구들이 함께 길을 밝혀줘요.',
    ),
    StoryScene(
      id: 'ep9-clue',
      text: '다른 길을 골라도 나중에 다시 만날 수 있어요.\n지금은 내 길의 작은 약속을 하나 더 살펴봐요.',
      background: 'ep9-joined',
      minimumLevel: 4,
      character: '토토',
    ),
    StoryScene(
      id: 'ep9-trace',
      text: '세 길이 만나는 곳에 ㅏ 빛줄기를 그려요.\n꽃밭에서 만났던 모음 길을 함께 밝혀요.',
      background: 'ep9-joined',
      minimumLevel: 3,
      interaction: StoryPhase.tracing,
      traceId: 'h-ㅏ',
      reaction: StoryReaction.point,
      successText: 'ㅏ 빛줄기가 세 갈래 길을 하나로 이어주었어요.',
    ),
    StoryScene(
      id: 'ep9-review',
      text: '고른 길의 두 번째 조각이에요.\n앞에서 만난 글자나 수를 다시 살펴요.',
      background: 'ep9-joined',
      minimumLevel: 4,
      interaction: StoryPhase.quiz,
      reaction: StoryReaction.point,
      quiz: q.routeHangulReview,
      variationFlag: 'route',
      quizVariants: routeReviewQuizzes,
      speechVariants: routeReviewSounds,
      successText: '두 번째 기억도 찾았어요! 작은 조각들이 이야기가 되어가요.',
    ),
    StoryScene(
      id: 'ep9-talk',
      text: '네가 고른 길 이야기를 들려줘.\n다음에는 내가 고른 길도 함께 가보자!',
      background: 'ep9-joined',
      minimumLevel: 5,
      character: '루루',
    ),
    StoryScene(
      id: 'ep9-together',
      text: '마지막 조각은 친구와 함께 찾아요.\n순서나 짝의 약속을 떠올려봐요.',
      background: 'ep9-joined',
      minimumLevel: 5,
      interaction: StoryPhase.quiz,
      reaction: StoryReaction.point,
      quiz: q.routeHangulTogether,
      variationFlag: 'route',
      quizVariants: routeTogetherQuizzes,
      speechVariants: routeSounds,
      successText: '세 번째 조각까지 찾았어요! 선택한 길의 이야기를 완성했어요.',
    ),
    StoryScene(
      id: 'ep9-end',
      text: '아홉 번째 별빛을 찾았어요!\n세 길이 만나는 종이숲에서 빗방울 소리가 들려요.',
      background: 'ep9-joined',
      reaction: StoryReaction.celebrate,
    ),
  ],
);
