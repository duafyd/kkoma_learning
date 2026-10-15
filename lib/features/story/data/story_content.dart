import '../../learning/data/learning_content.dart';
import '../../learning/domain/learning_models.dart';
import '../domain/story_models.dart';

QuizDefinition quizById(String id) =>
    learningQuizzes.firstWhere((q) => q.id == id);

class _Chapter {
  final String title,
      background,
      intro,
      discovery,
      clue,
      ending,
      quizId,
      traceId,
      goal;
  const _Chapter(
    this.title,
    this.background,
    this.intro,
    this.discovery,
    this.clue,
    this.ending,
    this.quizId,
    this.traceId,
    this.goal,
  );
}

const _chapters = [
  _Chapter(
    '빛을 잃은 도서관',
    'library',
    '모아예요. 우리 도서관의 별빛이 사라졌어요.',
    '루루와 토토도 조각을 찾고 있어요.',
    '휙휙이 흔든 책장에서 조각이 날아갔대요.',
    '별빛 하나가 켜졌어요! 꽃밭으로 가는 지도가 나타났어요.',
    'same',
    'n-1',
    '같은 모양과 1~3개 세기',
  ),
  _Chapter(
    '모음 꽃밭의 길',
    'garden',
    '지도 속 꽃밭에 도착했어요. 꽃 문에 글자가 있어요.',
    'ㅏ, ㅓ, ㅗ, ㅜ의 문이 섞였어요.',
    '아 소리를 듣고 오른쪽 작은 획을 찾아요.',
    '모음 문이 열렸어요! 다음 조각은 자음 나무에 있어요.',
    'h-vowel',
    'h-ㅏ',
    '모음 소리와 모양',
  ),
  _Chapter(
    '자음 나무의 열매',
    'forest',
    '루루가 열매를 담을 바구니를 찾고 있어요.',
    '나무에 글자 열매가 달렸어요. 가방도 보이네요.',
    '꽃밭에서 만난 ㅏ와 ㄱ이 친구가 될 수 있어요.',
    '열매가 글자 씨앗이 되었어요. 씨앗을 기차에 실어요.',
    'h-bag',
    'h-ㄱ',
    '자음과 대표 낱말',
  ),
  _Chapter(
    '뒤죽박죽 소리 기차',
    'train',
    '기차의 소리와 표지가 섞였어요. 알맞은 표지를 찾아요.',
    '가방을 싣는 칸은 가 소리가 나요.',
    'ㄱ과 꽃밭의 ㅏ가 만나면 가가 되어요.',
    '소리 기차가 별빛 역에 도착했어요. 꺼진 등대를 발견했어요.',
    'h-combine',
    'h-ㄴ',
    '소리·글자 연결과 음절 조합',
  ),
  _Chapter(
    '알파벳 등대',
    'lighthouse',
    '등대에 영어 글자 빛을 켜 볼까요?',
    'A는 알파벳 이름이에요. Apple은 사과의 이름이에요.',
    'A의 이름과 Apple의 첫소리를 따로 들어요.',
    'A의 빛이 켜졌어요! 빛이 숫자 다리를 비춰요.',
    'e-apple',
    'e-A',
    '알파벳 이름과 대표 단어',
  ),
  _Chapter(
    '숫자 다리와 세 개의 돌',
    'bridge',
    '다리에 돌을 놓아 친구들과 건너요.',
    '토토가 돌을 하나씩 세고 있어요.',
    '하나, 둘, 셋. 하나 더 놓으면 길이 이어져요.',
    '돌다리를 완성했어요! 저 아래 정원의 색이 흐려졌어요.',
    'count2',
    'n-3',
    '수량과 숫자·하나 더',
  ),
  _Chapter(
    '색깔을 잃은 정원',
    'garden',
    '정원의 색과 모양이 섞였어요. 함께 꾸며요.',
    '동그라미와 세모가 번갈아 길을 만들어요.',
    '꽃과 나비를 그려 새로운 지도를 만들어요.',
    '우리 그림이 지도가 되었어요! 바람 친구가 기다려요.',
    'pattern',
    'h-ㅗ',
    '분류·패턴과 그림 표현',
  ),
  _Chapter(
    '바람 친구 휙휙의 실수',
    'sky',
    '휙휙이 말해요. 조각을 멀리 날려서 미안해.',
    '친구들은 휙휙과 함께 조각을 정리해요.',
    '글자는 글자끼리, 숫자는 숫자끼리 모아요.',
    '휙휙도 탐험 친구가 되었어요. 세 갈래 길에 도착했어요.',
    'classify',
    'e-C',
    '협력·분류와 복습',
  ),
  _Chapter(
    '세 갈래 이야기 길',
    'forest',
    '한글 길, 영어 길, 숫자 길이 보여요. 어느 길로 갈까요?',
    '모든 길에 이야기 조각이 있어요. 친구가 함께 가요.',
    '가방, Apple, 돌 세 개를 다시 떠올려요.',
    '선택한 길에서 조각을 찾았어요. 길 끝에 종이숲이 있어요.',
    'h-bag',
    'h-ㅏ',
    '선택 경로에 따른 복습',
  ),
  _Chapter(
    '비 오는 종이숲',
    'rain',
    '비에 젖은 책 페이지가 붙었어요. 천천히 펼쳐요.',
    '씨앗을 심고 나무가 자라는 순서를 살펴요.',
    '휙휙은 자기도 이야기를 만들고 싶었대요.',
    '페이지가 이어졌어요! 마지막 별자리의 그림이 나타났어요.',
    'e-order',
    'e-A',
    '순서와 페이지 복원',
  ),
  _Chapter(
    '마지막 별자리 퍼즐',
    'sky',
    '모은 조각을 별자리에 놓아 볼까요?',
    '토토와 조각을 세고 모양을 찾아요.',
    '꽃밭의 모음, 등대의 A, 다리의 숫자를 떠올려요.',
    '별자리가 완성됐어요! 별빛 길이 도서관을 향해요.',
    'count5',
    'n-2',
    '수량·패턴·필기 복습',
  ),
  _Chapter(
    '다시 열린 별빛 도서관',
    'library',
    '도서관이 다시 환해졌어요! 모두 함께 해냈어요.',
    '휙휙이 말해요. 나도 이야기를 만들고 싶었어.',
    '친구들은 함께 만들자고 해요. 흩뜨린 것은 함께 정리해요.',
    '별빛 도서관이 다시 열렸어요. 새 책이 반짝여요. 다음 모험도 함께해요!',
    'same',
    'h-ㅜ',
    '협력과 시즌 결말',
  ),
];
final storyEpisodes = List<StoryEpisode>.generate(_chapters.length, (i) {
  final c = _chapters[i];
  StoryScene scene(
    String suffix,
    String text, {
    StoryPhase kind = StoryPhase.dialogue,
    int level = 2,
    QuizDefinition? quiz,
    String? trace,
    List<String> choices = const [],
    String? flag,
    String character = '모아',
  }) => StoryScene(
    id: 'ep${i + 1}-$suffix',
    text: text,
    background: c.background,
    character: character,
    interaction: kind,
    minimumLevel: level,
    quiz: quiz,
    traceId: trace,
    choices: choices,
    flag: flag,
  );
  final easy = QuizDefinition(
    id: 'ep${i + 1}-explore',
    prompt: '마음에 드는 친구를 눌러요',
    visual: '🦊 🐢',
    options: ['🦊', '🐢'],
    answer: 0,
    hint: '어느 친구를 골라도 좋아요.',
  );
  return StoryEpisode(
    id: i + 1,
    title: c.title,
    goal: c.goal,
    reward: '별빛 ${i + 1}',
    scenes: [
      scene('start', c.intro),
      scene('discover', c.discovery, level: 3, character: '루루'),
      scene(
        'choice',
        i == 8
            ? '어느 길로 먼저 갈까요?'
            : i == 11
            ? '도서관을 무엇으로 꾸밀까요?'
            : '누구와 함께 찾을까요?',
        kind: StoryPhase.choice,
        choices: i == 8
            ? ['한글 길', '영어 길', '숫자 길']
            : i == 11
            ? ['꽃 방', '별 방']
            : ['루루', '토토'],
        flag: i == 8
            ? 'route'
            : i == 11
            ? 'room'
            : 'companion',
      ),
      scene(
        'quiz',
        c.discovery,
        kind: StoryPhase.quiz,
        quiz: quizById(c.quizId),
      ),
      scene('clue', c.clue, level: 4, character: i >= 7 ? '휙휙' : '모아'),
      scene(
        'trace',
        i == 6 ? '정원에 꽃이나 나비를 그려 주세요.' : '빛나는 점에서 길을 따라 그려요.',
        kind: i == 6 ? StoryPhase.drawing : StoryPhase.tracing,
        level: 3,
        trace: c.traceId,
      ),
      scene(
        'review',
        '전에 모은 별빛을 다시 살펴봐요.',
        kind: StoryPhase.quiz,
        level: 4,
        quiz: quizById(i % 2 == 0 ? 'plus' : 'e-case'),
      ),
      scene('talk', '루루가 말해요. 천천히 다시 해 보니 길이 보여!', level: 5, character: '루루'),
      scene(
        'together',
        '다음 길도 친구와 함께 골라요.',
        kind: StoryPhase.quiz,
        level: 5,
        quiz: i == 9
            ? const QuizDefinition(
                id: 'seed-order',
                prompt: '씨앗 다음에는 무엇이 자랄까요?',
                visual: '🌰 → 🌱 → ?',
                options: ['🌳', '🌰', '☂'],
                answer: 0,
                hint: '싹이 커지면 나무가 돼요.',
                kind: QuizKind.order,
              )
            : easy,
      ),
      scene('end', c.ending),
    ],
  );
});
