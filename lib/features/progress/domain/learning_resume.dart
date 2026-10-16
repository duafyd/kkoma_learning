enum LearningResumeKind { tracing, quiz }

class LearningResumeTarget {
  final LearningResumeKind kind;
  final String title, detail, location;
  final DateTime updatedAt;
  const LearningResumeTarget({
    required this.kind,
    required this.title,
    required this.detail,
    required this.location,
    required this.updatedAt,
  });
}
