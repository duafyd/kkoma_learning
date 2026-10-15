import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/activity_scaffold.dart';
import '../../drawing/presentation/drawing_vm.dart';
import '../../progress/data/progress_repository.dart';
import '../../progress/presentation/gallery_page.dart';
import '../../story/presentation/story_vm.dart';
import '../../math/presentation/sorting_vm.dart';
import '../../learning/presentation/learning_vm.dart';
import '../../tracing/presentation/trace_vm.dart';

class ProgressControls extends ConsumerWidget {
  const ProgressControls({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Divider(),
      const Text('학습 기록 및 작품 관리', style: TextStyle(fontSize: 26)),
      ref
          .watch(progressSummaryProvider)
          .when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('진도를 읽지 못했어요: $e'),
            data: (progress) => Column(
              children: [
                Text(
                  '학습 항목 ${progress.length}개 · 완료 ${progress.values.where((v) => v['completed'] == true).length}개',
                ),
                ...progress.entries
                    .take(30)
                    .map(
                      (e) => ListTile(
                        title: Text(e.key),
                        subtitle: Text(
                          '시도 ${e.value['attempts']}회 · 성공 ${e.value['successes']}회${e.value['assisted'] == true ? ' · 도움과 함께' : ''}',
                        ),
                      ),
                    ),
              ],
            ),
          ),
      OutlinedButton(
        onPressed: () async {
          if (!await confirmAction(
            context,
            '학습 진도와 이야기만 초기화할까요? 작품과 설정은 유지됩니다.',
          )) {
            return;
          }
          try {
            await ref.read(progressRepositoryProvider).reset();
            ref.invalidate(storyProvider);
            ref.invalidate(sortingProvider);
            ref.invalidate(learningProvider);
            ref.invalidate(traceProvider);
            ref.invalidate(progressSummaryProvider);
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('초기화하지 못했어요. 다시 시도해 주세요.')),
              );
            }
          }
        },
        child: const Text('진도 초기화'),
      ),
      ref
          .watch(galleryProvider)
          .when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('작품을 읽지 못했어요: $e'),
            data: (items) => Column(
              children: items
                  .map(
                    (a) => ListTile(
                      title: Text(
                        '작품 ${a.created.year}.${a.created.month}.${a.created.day}',
                      ),
                      trailing: IconButton(
                        tooltip: '작품 삭제',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          if (!await confirmAction(
                            context,
                            '이 작품을 기기에서 삭제할까요?',
                          )) {
                            return;
                          }
                          try {
                            await ref
                                .read(galleryProvider.notifier)
                                .delete(a.id);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('작품 삭제를 마치지 못했어요.'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
    ],
  );
}
