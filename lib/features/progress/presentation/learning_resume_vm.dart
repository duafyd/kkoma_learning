import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../profile/presentation/profile_vm.dart';
import '../data/learning_resume_repository.dart';
import '../domain/learning_resume.dart';

final learningResumeRepositoryProvider = Provider(
  (ref) => LearningResumeRepository(ref.watch(storeProvider)),
);
final learningResumeProvider =
    AsyncNotifierProvider.autoDispose<
      LearningResumeVM,
      List<LearningResumeTarget>
    >(LearningResumeVM.new);

class LearningResumeVM extends AsyncNotifier<List<LearningResumeTarget>> {
  @override
  Future<List<LearningResumeTarget>> build() async => ref
      .read(learningResumeRepositoryProvider)
      .load(await ref.watch(settingsProvider.future));
}
