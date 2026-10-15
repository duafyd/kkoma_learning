import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/audio/audio_service.dart';
import '../../profile/domain/settings.dart';
import '../../profile/presentation/profile_vm.dart';
import '../../progress/data/progress_repository.dart';
import '../data/learning_content.dart';
import '../data/learning_repository.dart';
import '../domain/learning_models.dart';
import '../domain/learning_session.dart';
export '../domain/learning_session.dart';

final learningRepositoryProvider = Provider(
  (ref) => LearningRepository(ref.watch(storeProvider)),
);
final learningProvider = AsyncNotifierProvider.autoDispose
    .family<LearningVM, LearningSession, String>(LearningVM.new);

class LearningVM extends AsyncNotifier<LearningSession> {
  final String subject;
  bool busy = false;
  LearningVM(this.subject);
  @override
  Future<LearningSession> build() async {
    final repository = ref.read(learningRepositoryProvider);
    final settings = await ref.read(settingsProvider.future);
    return repository.load(subject, settings.level);
  }

  List<LearningItem> get items => learningItems
      .where(
        (i) =>
            i.subject == subject && i.minimumLevel <= state.requireValue.level,
      )
      .toList();
  List<QuizDefinition> get quizzes => learningQuizzes
      .where(
        (q) =>
            q.subject == subject && q.minimumLevel <= state.requireValue.level,
      )
      .toList();
  QuizDefinition get quiz {
    final session = state.requireValue;
    final overrides = learningQuizzes.where(
      (q) =>
          q.id == session.quizOverrideId &&
          q.subject == subject &&
          q.minimumLevel <= session.level,
    );
    return overrides.isNotEmpty
        ? overrides.first
        : quizzes[session.index % quizzes.length];
  }

  Future<void> listen(LearningItem item) async {
    if (item.subject != subject) return;
    final audio = ref.read(audioProvider),
        progress = ref.read(progressRepositoryProvider);
    final settings = ref.read(settingsProvider).value ?? const ParentSettings();
    final result = await audio.speak(
      '${item.name}. ${item.example}.',
      settings,
      language: item.language,
    );
    if (result == PlaybackResult.cancelled) return;
    await progress.record('listen-${item.id}', result == PlaybackResult.played);
  }

  Future<void> _save(LearningSession next) async {
    await ref.read(learningRepositoryProvider).save(subject, next);
    if (ref.mounted) state = AsyncData(next);
  }

  // Every quiz command shares one guard, including hints and navigation.
  Future<void> _transition(
    Future<void> Function(LearningSession) action,
  ) async {
    if (busy || !state.hasValue) return;
    busy = true;
    try {
      await action(state.requireValue);
    } finally {
      busy = false;
    }
  }

  Future<void> answer(int choice) => _transition((old) async {
    final current = quiz;
    if (old.answered || choice < 0 || choice >= current.options.length) return;
    final settings = ref.read(settingsProvider).value ?? const ParentSettings();
    final success =
        AgeStrategy(old.level).exploration || current.accepts(choice);
    final failures = success ? 0 : old.failures + 1;
    final next = old.change({
      'successes': success ? old.successes + 1 : 0,
      'failures': failures,
      'answered': success,
      'message': success
          ? '함께 살펴봤어요! 멋진 시도예요.'
          : failures >= settings.helpAfter && settings.help
          ? '빛나는 답을 함께 찾아봐요.'
          : '이쪽도 살펴볼까요?',
      'hint': success ? 0 : failures,
    });
    final repository = ref.read(learningRepositoryProvider);
    await ref.read(progressRepositoryProvider).record(current.id, success);
    await repository.save(subject, next);
    if (ref.mounted) state = AsyncData(next);
  });
  Future<void> showHint() => _transition((old) async {
    if (old.answered) return;
    await _save(old.change({'hint': old.hint + 1, 'message': quiz.hint}));
  });
  Future<void> assist() => _transition((old) async {
    final settings = ref.read(settingsProvider).value ?? const ParentSettings();
    if (!settings.help || old.failures < settings.helpAfter || old.answered) {
      return;
    }
    final repository = ref.read(learningRepositoryProvider);
    final next = old.change({
      'answered': true,
      'assisted': true,
      'message': '친구와 함께 해냈어요!',
    });
    await ref
        .read(progressRepositoryProvider)
        .record(quiz.id, true, assisted: true);
    await repository.save(subject, next);
    if (ref.mounted) state = AsyncData(next);
  });
  Future<void> next() => _transition((old) async {
    if (!old.answered) return;
    final level = AgeStrategy(old.level).adapt(old.successes, old.failures);
    await _save(
      LearningSession(
        level: level,
        baseLevel: old.baseLevel,
        index: old.index + 1,
        successes: level == old.level ? old.successes : 0,
      ),
    );
  });
  Future<void> easier() => _transition((old) async {
    if (old.answered) return;
    final level = (old.level - 1).clamp(2, 5);
    final targets = learningQuizzes.where(
      (q) =>
          q.id == quiz.easierId &&
          q.subject == subject &&
          q.minimumLevel <= level,
    );
    await _save(
      LearningSession(
        level: level,
        baseLevel: old.baseLevel,
        index: old.index,
        quizOverrideId: targets.isEmpty ? null : targets.first.id,
        message: '다른 길로 함께 가요.',
      ),
    );
  });
}
