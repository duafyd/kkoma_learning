import '../../learning/domain/learning_models.dart';

const storySupportQuizzes = <String, QuizDefinition>{
  'hangul': QuizDefinition(
    id: 'story-support-hangul',
    subject: 'hangul',
    prompt: '빛나는 글자와 같은 친구를 찾아요',
    visual: 'ㄱ',
    options: ['ㄴ', 'ㄱ'],
    answer: 1,
    hint: 'ㄱ 모양을 함께 살펴봐요.',
  ),
  'english': QuizDefinition(
    id: 'story-support-english',
    subject: 'english',
    prompt: '등대의 A와 같은 글자를 찾아요',
    visual: 'A',
    options: ['A', 'B'],
    answer: 0,
    hint: '두 다리와 가운데 선이 있는 A예요.',
  ),
  'math': QuizDefinition(
    id: 'story-support-count',
    prompt: '별 두 개와 같은 수를 찾아요',
    visual: '★ ★',
    options: ['●', '● ●'],
    answer: 1,
    hint: '별 하나에 동그라미 하나씩 짝을 지어요.',
    kind: QuizKind.matching,
  ),
  'shape': QuizDefinition(
    id: 'story-support-shape',
    prompt: '동그라미와 같은 모양을 찾아요',
    visual: '●',
    options: ['●', '▲'],
    answer: 0,
    hint: '둥글고 모서리가 없어요.',
    kind: QuizKind.classify,
  ),
  'pattern': QuizDefinition(
    id: 'story-support-pattern',
    prompt: '친구들이 번갈아 와요. 다음은 누구일까요?',
    visual: '● ▲ ● ?',
    options: ['●', '▲'],
    answer: 1,
    hint: '동그라미 다음에는 세모가 와요.',
    kind: QuizKind.pattern,
  ),
};
