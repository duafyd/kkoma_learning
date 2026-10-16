import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/learning_resume.dart';
import 'learning_resume_vm.dart';

class LearningResumePanel extends ConsumerWidget {
  const LearningResumePanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(learningResumeProvider)
      .when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => Card(
          child: ListTile(
            title: const Text('학습 이어하기를 불러오지 못했어요'),
            subtitle: const Text('다른 놀이는 계속 이용할 수 있어요.'),
            trailing: IconButton(
              tooltip: '이어하기 다시 불러오기',
              onPressed: () => ref.invalidate(learningResumeProvider),
              icon: const Icon(Icons.refresh),
            ),
          ),
        ),
        data: (targets) => targets.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: LayoutBuilder(
                  builder: (context, constraints) => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final target in targets)
                        SizedBox(
                          width:
                              constraints.maxWidth >= 760 && targets.length > 1
                              ? (constraints.maxWidth - 12) / 2
                              : constraints.maxWidth,
                          child: Card(
                            child: ListTile(
                              key: ValueKey('resume-${target.kind.name}'),
                              leading: Icon(
                                target.kind == LearningResumeKind.tracing
                                    ? Icons.edit_rounded
                                    : Icons.extension_rounded,
                                size: 32,
                              ),
                              title: Text(
                                target.title,
                                style: const TextStyle(
                                  fontFamily: 'Jua',
                                  fontSize: 22,
                                ),
                              ),
                              subtitle: Text(target.detail),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => context.go(target.location),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      );
}
