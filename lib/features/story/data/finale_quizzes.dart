import '../../learning/domain/learning_models.dart';

const bridgeThree = QuizDefinition(
  id: 'ep6-bridge-three',
  subject: 'math',
  prompt: '작은 다리판에 놓을 돌은 몇 개일까요?',
  visual: 'stone stone stone',
  options: ['2개', '3개', '4개'],
  answer: 1,
  hint: '빈 자리에 돌을 하나씩 놓아 세어봐요.',
  kind: QuizKind.count,
  minimumLevel: 2,
  artwork: QuizArtwork(
    objects: [QuizGlyph.stone, QuizGlyph.stone, QuizGlyph.stone],
    choices: [
      [QuizGlyph.stone, QuizGlyph.stone],
      [QuizGlyph.stone, QuizGlyph.stone, QuizGlyph.stone],
      [QuizGlyph.stone, QuizGlyph.stone, QuizGlyph.stone, QuizGlyph.stone],
    ],
    countOnTap: true,
    objectName: '돌',
    arrangement: QuizArrangement.bridge,
  ),
);

const bridgeMore = QuizDefinition(
  id: 'ep6-one-more',
  subject: 'math',
  prompt: '돌 두 개에 하나 더 놓으면 몇 개일까요?',
  visual: 'stone stone',
  options: ['1개', '2개', '3개'],
  answer: 2,
  hint: '하나, 둘 다음에 하나 더 놓아요.',
  kind: QuizKind.addition,
  minimumLevel: 4,
  artwork: QuizArtwork(
    objects: [QuizGlyph.stone, QuizGlyph.stone],
    choices: [
      [QuizGlyph.stone],
      [QuizGlyph.stone, QuizGlyph.stone],
      [QuizGlyph.stone, QuizGlyph.stone, QuizGlyph.stone],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const bridgeLess = QuizDefinition(
  id: 'ep6-one-less',
  subject: 'math',
  prompt: '돌 세 개에서 하나를 빼면 몇 개일까요?',
  visual: 'stone stone stone',
  options: ['2개', '3개', '4개'],
  answer: 0,
  hint: '세 개 중 하나를 가리고 남은 돌을 세어봐요.',
  kind: QuizKind.subtraction,
  minimumLevel: 5,
  artwork: QuizArtwork(
    objects: [QuizGlyph.stone, QuizGlyph.stone, QuizGlyph.stone],
    choices: [
      [QuizGlyph.stone, QuizGlyph.stone],
      [QuizGlyph.stone, QuizGlyph.stone, QuizGlyph.stone],
      [QuizGlyph.stone, QuizGlyph.stone, QuizGlyph.stone, QuizGlyph.stone],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const gardenRed = QuizDefinition(
  id: 'ep7-red-flowers',
  subject: 'math',
  prompt: '빨간 꽃끼리 모인 그림을 골라요.',
  visual: 'redFlower',
  options: ['파란 꽃 둘', '빨간 꽃 둘'],
  answer: 1,
  hint: '모양보다 꽃잎의 빨간 색을 살펴봐요.',
  kind: QuizKind.classify,
  minimumLevel: 2,
  artwork: QuizArtwork(
    objects: [QuizGlyph.redFlower],
    choices: [
      [QuizGlyph.blueFlower, QuizGlyph.blueFlower],
      [QuizGlyph.redFlower, QuizGlyph.redFlower],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const gardenPattern = QuizDefinition(
  id: 'ep7-shape-path',
  subject: 'math',
  prompt: '동그라미, 세모, 동그라미 다음은 무엇일까요?',
  visual: 'circle triangle circle',
  options: ['세모', '동그라미', '꽃'],
  answer: 0,
  hint: '동그라미와 세모가 번갈아 나와요.',
  kind: QuizKind.pattern,
  minimumLevel: 4,
  artwork: QuizArtwork(
    objects: [QuizGlyph.circle, QuizGlyph.triangle, QuizGlyph.circle],
    choices: [
      [QuizGlyph.triangle],
      [QuizGlyph.circle],
      [QuizGlyph.flower],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const gardenLeaves = QuizDefinition(
  id: 'ep7-leaf-pair',
  subject: 'math',
  prompt: '잎끼리 모인 그림을 골라요.',
  visual: 'leaf',
  options: ['잎과 꽃', '잎과 잎'],
  answer: 1,
  hint: '초록 잎 두 개가 함께 있는지 살펴봐요.',
  kind: QuizKind.classify,
  minimumLevel: 5,
  artwork: QuizArtwork(
    objects: [QuizGlyph.leaf],
    choices: [
      [QuizGlyph.leaf, QuizGlyph.flower],
      [QuizGlyph.leaf, QuizGlyph.leaf],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const windLetters = QuizDefinition(
  id: 'ep8-letter-basket',
  subject: 'english',
  prompt: '영어 글자끼리 모인 바구니를 골라요.',
  visual: 'latinA latinC',
  options: ['A와 3', 'A와 C', '1과 3'],
  answer: 1,
  hint: '영어 글자 A와 C를 함께 모아요.',
  kind: QuizKind.classify,
  minimumLevel: 2,
  artwork: QuizArtwork(
    objects: [QuizGlyph.latinA, QuizGlyph.latinC],
    choices: [
      [QuizGlyph.latinA, QuizGlyph.three],
      [QuizGlyph.latinA, QuizGlyph.latinC],
      [QuizGlyph.one, QuizGlyph.three],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const windNumbers = QuizDefinition(
  id: 'ep8-number-basket',
  subject: 'math',
  prompt: '숫자끼리 모인 바구니를 골라요.',
  visual: 'one three',
  options: ['1과 A', '1과 3', 'A와 C'],
  answer: 1,
  hint: '숫자 1과 3을 함께 모아요.',
  kind: QuizKind.classify,
  minimumLevel: 4,
  artwork: QuizArtwork(
    objects: [QuizGlyph.one, QuizGlyph.three],
    choices: [
      [QuizGlyph.one, QuizGlyph.latinA],
      [QuizGlyph.one, QuizGlyph.three],
      [QuizGlyph.latinA, QuizGlyph.latinC],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const windPattern = QuizDefinition(
  id: 'ep8-page-pattern',
  subject: 'math',
  prompt: '별, 책, 별 다음에 놓을 것을 골라요.',
  visual: 'star book star',
  options: ['별', '책', '동그라미'],
  answer: 1,
  hint: '별과 책이 번갈아 나와요.',
  kind: QuizKind.pattern,
  minimumLevel: 5,
  artwork: QuizArtwork(
    objects: [QuizGlyph.star, QuizGlyph.book, QuizGlyph.star],
    choices: [
      [QuizGlyph.star],
      [QuizGlyph.book],
      [QuizGlyph.circle],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const routeHangul = QuizDefinition(
  id: 'ep9-hangul',
  subject: 'hangul',
  prompt: '기역과 아가 만나 만든 가를 골라요.',
  visual: 'giyeok vowelA',
  options: ['나', '가'],
  answer: 1,
  hint: '나무와 기차에서 만난 가를 떠올려요.',
  kind: QuizKind.combination,
  minimumLevel: 2,
  artwork: QuizArtwork(
    objects: [QuizGlyph.giyeok, QuizGlyph.vowelA],
    choices: [
      [QuizGlyph.na],
      [QuizGlyph.ga],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const routeEnglish = QuizDefinition(
  id: 'ep9-english',
  subject: 'english',
  prompt: 'Apple 단어와 같은 과일을 골라요.',
  visual: 'apple',
  options: ['바나나', '사과'],
  answer: 1,
  hint: '등대에서 Apple은 사과라고 배웠어요.',
  kind: QuizKind.matching,
  minimumLevel: 2,
  artwork: QuizArtwork(
    objects: [QuizGlyph.apple],
    choices: [
      [QuizGlyph.banana],
      [QuizGlyph.apple],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const routeMath = QuizDefinition(
  id: 'ep9-math',
  subject: 'math',
  prompt: '작은 판의 돌은 몇 개일까요?',
  visual: 'stone stone stone',
  options: ['2개', '3개', '4개'],
  answer: 1,
  hint: '다리에서처럼 하나씩 눌러 세어봐요.',
  kind: QuizKind.count,
  minimumLevel: 2,
  artwork: QuizArtwork(
    objects: [QuizGlyph.stone, QuizGlyph.stone, QuizGlyph.stone],
    choices: [
      [QuizGlyph.stone, QuizGlyph.stone],
      [QuizGlyph.stone, QuizGlyph.stone, QuizGlyph.stone],
      [QuizGlyph.stone, QuizGlyph.stone, QuizGlyph.stone, QuizGlyph.stone],
    ],
    countOnTap: true,
    objectName: '돌',
    arrangement: QuizArrangement.tray,
  ),
);

const routeHangulReview = QuizDefinition(
  id: 'ep9-hangul-vowel',
  subject: 'hangul',
  prompt: '오 소리가 나는 모음을 골라요.',
  visual: 'vowelO',
  options: ['우', '오'],
  answer: 1,
  hint: '짧은 줄이 위로 올라간 오를 찾아요.',
  kind: QuizKind.matching,
  minimumLevel: 4,
  artwork: QuizArtwork(
    objects: [QuizGlyph.vowelO],
    choices: [
      [QuizGlyph.vowelU],
      [QuizGlyph.vowelO],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const routeEnglishReview = QuizDefinition(
  id: 'ep9-english-case',
  subject: 'english',
  prompt: '대문자 A의 작은 글자 짝을 골라요.',
  visual: 'latinA',
  options: ['작은 에이', '작은 비'],
  answer: 0,
  hint: 'A와 a는 에이라는 같은 이름이에요.',
  kind: QuizKind.matching,
  minimumLevel: 4,
  artwork: QuizArtwork(
    objects: [QuizGlyph.latinA],
    choices: [
      [QuizGlyph.lowerA],
      [QuizGlyph.lowerB],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const routeMathReview = QuizDefinition(
  id: 'ep9-math-more',
  subject: 'math',
  prompt: '돌 두 개에 하나 더 놓은 그림을 골라요.',
  visual: 'stone stone',
  options: ['2개', '3개'],
  answer: 1,
  hint: '둘 다음에 하나 더, 셋이에요.',
  kind: QuizKind.addition,
  minimumLevel: 4,
  artwork: QuizArtwork(
    objects: [QuizGlyph.stone, QuizGlyph.stone],
    choices: [
      [QuizGlyph.stone, QuizGlyph.stone],
      [QuizGlyph.stone, QuizGlyph.stone, QuizGlyph.stone],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const routeHangulTogether = QuizDefinition(
  id: 'ep9-hangul-order',
  subject: 'hangul',
  prompt: '왼쪽 가, 오른쪽 나의 순서를 골라요.',
  visual: 'ga na',
  options: ['나, 가', '가, 나'],
  answer: 1,
  hint: '기차의 가 다음 나 표지를 떠올려요.',
  kind: QuizKind.order,
  minimumLevel: 5,
  artwork: QuizArtwork(
    objects: [QuizGlyph.ga, QuizGlyph.na],
    choices: [
      [QuizGlyph.na, QuizGlyph.ga],
      [QuizGlyph.ga, QuizGlyph.na],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const routeEnglishTogether = QuizDefinition(
  id: 'ep9-english-pair',
  subject: 'english',
  prompt: 'A와 사과가 함께 있는 그림을 골라요.',
  visual: 'latinA apple',
  options: ['B와 사과', 'A와 사과'],
  answer: 1,
  hint: '에이라는 글자와 Apple 사과를 찾아요.',
  kind: QuizKind.matching,
  minimumLevel: 5,
  artwork: QuizArtwork(
    objects: [QuizGlyph.latinA, QuizGlyph.apple],
    choices: [
      [QuizGlyph.latinB, QuizGlyph.apple],
      [QuizGlyph.latinA, QuizGlyph.apple],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const routeMathTogether = QuizDefinition(
  id: 'ep9-math-pattern',
  subject: 'math',
  prompt: '돌, 씨앗, 돌 다음에 놓을 것을 골라요.',
  visual: 'stone seed stone',
  options: ['돌', '씨앗'],
  answer: 1,
  hint: '돌과 씨앗이 번갈아 나와요.',
  kind: QuizKind.pattern,
  minimumLevel: 5,
  artwork: QuizArtwork(
    objects: [QuizGlyph.stone, QuizGlyph.seed, QuizGlyph.stone],
    choices: [
      [QuizGlyph.stone],
      [QuizGlyph.seed],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const paperSprout = QuizDefinition(
  id: 'ep10-seed-next',
  subject: 'math',
  prompt: '씨앗 다음에 자라는 것을 골라요.',
  visual: 'seed',
  options: ['나무', '싹'],
  answer: 1,
  hint: '씨앗에서 작은 싹이 먼저 나와요.',
  kind: QuizKind.order,
  minimumLevel: 2,
  artwork: QuizArtwork(
    objects: [QuizGlyph.seed],
    choices: [
      [QuizGlyph.tree],
      [QuizGlyph.sprout],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const paperOrder = QuizDefinition(
  id: 'ep10-growth-order',
  subject: 'math',
  prompt: '씨앗이 자라는 순서대로 놓인 그림을 골라요.',
  visual: 'seed sprout tree',
  options: ['나무, 싹, 씨앗', '씨앗, 싹, 나무'],
  answer: 1,
  hint: '작은 씨앗에서 싹, 그다음 나무가 되어요.',
  kind: QuizKind.order,
  minimumLevel: 4,
  artwork: QuizArtwork(
    objects: [QuizGlyph.seed, QuizGlyph.sprout, QuizGlyph.tree],
    choices: [
      [QuizGlyph.tree, QuizGlyph.sprout, QuizGlyph.seed],
      [QuizGlyph.seed, QuizGlyph.sprout, QuizGlyph.tree],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const paperBooks = QuizDefinition(
  id: 'ep10-book-pair',
  subject: 'math',
  prompt: '책끼리 모인 그림을 골라요.',
  visual: 'book',
  options: ['책과 잎', '책과 책'],
  answer: 1,
  hint: '같은 책 두 권을 함께 찾아요.',
  kind: QuizKind.classify,
  minimumLevel: 5,
  artwork: QuizArtwork(
    objects: [QuizGlyph.book],
    choices: [
      [QuizGlyph.book, QuizGlyph.leaf],
      [QuizGlyph.book, QuizGlyph.book],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const skyFive = QuizDefinition(
  id: 'ep11-five-stars',
  subject: 'math',
  prompt: '작은 별자리판에 놓을 별은 몇 개일까요?',
  visual: 'star star star star star',
  options: ['4개', '5개', '3개'],
  answer: 1,
  hint: '다섯 자리에 별을 하나씩 놓아봐요.',
  kind: QuizKind.count,
  minimumLevel: 2,
  artwork: QuizArtwork(
    objects: [
      QuizGlyph.star,
      QuizGlyph.star,
      QuizGlyph.star,
      QuizGlyph.star,
      QuizGlyph.star,
    ],
    choices: [
      [QuizGlyph.star, QuizGlyph.star, QuizGlyph.star, QuizGlyph.star],
      [
        QuizGlyph.star,
        QuizGlyph.star,
        QuizGlyph.star,
        QuizGlyph.star,
        QuizGlyph.star,
      ],
      [QuizGlyph.star, QuizGlyph.star, QuizGlyph.star],
    ],
    countOnTap: true,
    objectName: '별',
    arrangement: QuizArrangement.constellation,
  ),
);

const skyPattern = QuizDefinition(
  id: 'ep11-star-pattern',
  subject: 'math',
  prompt: '별, 동그라미, 별 다음에 올 모양을 골라요.',
  visual: 'star circle star',
  options: ['별', '동그라미', '세모'],
  answer: 1,
  hint: '별과 동그라미가 번갈아 빛나요.',
  kind: QuizKind.pattern,
  minimumLevel: 4,
  artwork: QuizArtwork(
    objects: [QuizGlyph.star, QuizGlyph.circle, QuizGlyph.star],
    choices: [
      [QuizGlyph.star],
      [QuizGlyph.circle],
      [QuizGlyph.triangle],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const skyRecall = QuizDefinition(
  id: 'ep11-three-memories',
  subject: 'math',
  prompt: '아, A, 숫자 3이 모두 같은 그림을 골라요.',
  visual: 'vowelA latinA three',
  options: ['오, A, 3', '아, A, 3'],
  answer: 1,
  hint: '꽃밭의 아와 등대의 A, 다리의 3을 찾아요.',
  kind: QuizKind.matching,
  minimumLevel: 5,
  artwork: QuizArtwork(
    objects: [QuizGlyph.vowelA, QuizGlyph.latinA, QuizGlyph.three],
    choices: [
      [QuizGlyph.vowelO, QuizGlyph.latinA, QuizGlyph.three],
      [QuizGlyph.vowelA, QuizGlyph.latinA, QuizGlyph.three],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const libraryStars = QuizDefinition(
  id: 'ep12-star-decoration',
  subject: 'math',
  prompt: '별끼리 모인 장식을 골라요.',
  visual: 'star',
  options: ['별과 책', '별과 별'],
  answer: 1,
  hint: '두 모양이 모두 별인지 살펴봐요.',
  kind: QuizKind.matching,
  minimumLevel: 2,
  artwork: QuizArtwork(
    objects: [QuizGlyph.star],
    choices: [
      [QuizGlyph.star, QuizGlyph.book],
      [QuizGlyph.star, QuizGlyph.star],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const libraryFlowers = QuizDefinition(
  id: 'ep12-flower-decoration',
  subject: 'math',
  prompt: '꽃끼리 모인 장식을 골라요.',
  visual: 'flower',
  options: ['꽃과 잎', '꽃과 꽃'],
  answer: 1,
  hint: '두 모양이 모두 꽃인지 살펴봐요.',
  kind: QuizKind.matching,
  minimumLevel: 2,
  artwork: QuizArtwork(
    objects: [QuizGlyph.flower],
    choices: [
      [QuizGlyph.flower, QuizGlyph.leaf],
      [QuizGlyph.flower, QuizGlyph.flower],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const libraryCase = QuizDefinition(
  id: 'ep12-letter-reunion',
  subject: 'english',
  prompt: 'A와 a가 함께 있는 그림을 골라요.',
  visual: 'latinA lowerA',
  options: ['A와 b', 'A와 a'],
  answer: 1,
  hint: '등대에서 만난 에이의 큰 글자와 작은 글자예요.',
  kind: QuizKind.matching,
  minimumLevel: 4,
  artwork: QuizArtwork(
    objects: [QuizGlyph.latinA, QuizGlyph.lowerA],
    choices: [
      [QuizGlyph.latinA, QuizGlyph.lowerB],
      [QuizGlyph.latinA, QuizGlyph.lowerA],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const libraryBooks = QuizDefinition(
  id: 'ep12-tidy-books',
  subject: 'math',
  prompt: '책장에 돌려놓을 책끼리 모인 그림을 골라요.',
  visual: 'book',
  options: ['책과 씨앗', '책과 책'],
  answer: 1,
  hint: '흩뜨린 책은 책끼리 모아 함께 정리해요.',
  kind: QuizKind.classify,
  minimumLevel: 5,
  artwork: QuizArtwork(
    objects: [QuizGlyph.book],
    choices: [
      [QuizGlyph.book, QuizGlyph.seed],
      [QuizGlyph.book, QuizGlyph.book],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const ep6Explore = QuizDefinition(
  id: 'ep6-explore-bridge',
  subject: 'math',
  prompt: '다리에 함께 놓고 싶은 돌이나 꽃을 눌러요.',
  visual: 'stone flower',
  options: ['돌', '꽃'],
  answer: 0,
  hint: '어느 쪽을 골라도 좋아요.',
  kind: QuizKind.matching,
  minimumLevel: 2,
  artwork: QuizArtwork(
    objects: [QuizGlyph.stone, QuizGlyph.flower],
    choices: [
      [QuizGlyph.stone],
      [QuizGlyph.flower],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const ep7Explore = QuizDefinition(
  id: 'ep7-explore-garden',
  subject: 'math',
  prompt: '마음에 드는 빨간 꽃이나 파란 꽃을 눌러요.',
  visual: 'redFlower blueFlower',
  options: ['빨간 꽃', '파란 꽃'],
  answer: 0,
  hint: '어느 쪽을 골라도 좋아요.',
  kind: QuizKind.matching,
  minimumLevel: 2,
  artwork: QuizArtwork(
    objects: [QuizGlyph.redFlower, QuizGlyph.blueFlower],
    choices: [
      [QuizGlyph.redFlower],
      [QuizGlyph.blueFlower],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const ep8Explore = QuizDefinition(
  id: 'ep8-explore-wind',
  subject: 'math',
  prompt: '함께 정리하고 싶은 책이나 동그라미를 눌러요.',
  visual: 'book circle',
  options: ['책', '동그라미'],
  answer: 0,
  hint: '어느 쪽을 골라도 좋아요.',
  kind: QuizKind.matching,
  minimumLevel: 2,
  artwork: QuizArtwork(
    objects: [QuizGlyph.book, QuizGlyph.circle],
    choices: [
      [QuizGlyph.book],
      [QuizGlyph.circle],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const ep9Explore = QuizDefinition(
  id: 'ep9-explore-path',
  subject: 'math',
  prompt: '좋아하는 꽃이나 별을 골라 길을 찾아요.',
  visual: 'flower star',
  options: ['꽃', '별'],
  answer: 0,
  hint: '어느 쪽을 골라도 좋아요.',
  kind: QuizKind.matching,
  minimumLevel: 2,
  artwork: QuizArtwork(
    objects: [QuizGlyph.flower, QuizGlyph.star],
    choices: [
      [QuizGlyph.flower],
      [QuizGlyph.star],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const ep10Explore = QuizDefinition(
  id: 'ep10-explore-paper',
  subject: 'math',
  prompt: '마음에 드는 씨앗이나 잎을 눌러요.',
  visual: 'seed leaf',
  options: ['씨앗', '잎'],
  answer: 0,
  hint: '어느 쪽을 골라도 좋아요.',
  kind: QuizKind.matching,
  minimumLevel: 2,
  artwork: QuizArtwork(
    objects: [QuizGlyph.seed, QuizGlyph.leaf],
    choices: [
      [QuizGlyph.seed],
      [QuizGlyph.leaf],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const ep11Explore = QuizDefinition(
  id: 'ep11-explore-sky',
  subject: 'math',
  prompt: '마음에 드는 별이나 동그라미 빛을 눌러요.',
  visual: 'star circle',
  options: ['별', '동그라미'],
  answer: 0,
  hint: '어느 쪽을 골라도 좋아요.',
  kind: QuizKind.matching,
  minimumLevel: 2,
  artwork: QuizArtwork(
    objects: [QuizGlyph.star, QuizGlyph.circle],
    choices: [
      [QuizGlyph.star],
      [QuizGlyph.circle],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);

const ep12Explore = QuizDefinition(
  id: 'ep12-explore-library',
  subject: 'math',
  prompt: '도서관에 놓고 싶은 별이나 꽃을 눌러요.',
  visual: 'star flower',
  options: ['별', '꽃'],
  answer: 0,
  hint: '어느 쪽을 골라도 좋아요.',
  kind: QuizKind.matching,
  minimumLevel: 2,
  artwork: QuizArtwork(
    objects: [QuizGlyph.star, QuizGlyph.flower],
    choices: [
      [QuizGlyph.star],
      [QuizGlyph.flower],
    ],
    countOnTap: false,
    objectName: '별조각',
    arrangement: QuizArrangement.tray,
  ),
);
