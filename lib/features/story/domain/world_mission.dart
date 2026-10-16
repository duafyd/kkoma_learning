import '../../learning/domain/learning_models.dart';

/// Scene-specific stage direction; the existing machine owns placement rules.
class WorldMission {
  final QuizArtwork artwork;
  final String instruction, assembled, resolution;
  const WorldMission(
    this.artwork,
    this.instruction,
    this.assembled,
    this.resolution,
  );
  bool get bridge => artwork.arrangement == QuizArrangement.bridge;
  int get count => artwork.objects.length;

  static WorldMission? forQuiz(QuizDefinition quiz) {
    final art = quiz.artwork;
    if (art == null) return null;
    return switch (art.arrangement) {
      QuizArrangement.bridge => WorldMission(
        art,
        '돌을 끌거나 톡 눌러, 빛나는 자리로 보내 줘.',
        '돌길이 이어졌어! 함께 세고 아래 그림을 골라 봐.',
        '길이 이어졌어. 친구와 함께 건너자!',
      ),
      QuizArrangement.constellation => WorldMission(
        art,
        '별을 끌거나 톡 눌러, 하늘의 빈자리를 이어 줘.',
        '별길이 이어졌어! 함께 세고 아래 그림을 골라 봐.',
        '별빛이 도서관으로 가는 길을 비춰 줘!',
      ),
      QuizArrangement.tray => null,
    };
  }
}
