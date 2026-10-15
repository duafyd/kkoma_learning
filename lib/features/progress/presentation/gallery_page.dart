import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/activity_scaffold.dart';
import '../../drawing/presentation/drawing_vm.dart';
import '../../story/data/story_content.dart';
import '../../story/presentation/story_vm.dart';
import '../data/progress_repository.dart';

final progressSummaryProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(progressRepositoryProvider).load(),
);

class GalleryPage extends ConsumerWidget {
  const GalleryPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gallery = ref.watch(galleryProvider),
        story = ref.watch(storyProvider);
    return ActivityScaffold(
      title: '내 작품 · 모험 지도',
      child: ListView(
        children: [
          const Text('모은 별빛', style: TextStyle(fontSize: 26)),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: storyEpisodes
                .map(
                  (ep) => Chip(
                    avatar: Icon(
                      story.value?.completed.contains(ep.id) == true
                          ? Icons.star
                          : Icons.star_outline,
                      color: const Color(0xffc28f21),
                    ),
                    label: Text('${ep.id}. ${ep.title}'),
                  ),
                )
                .toList(),
          ),
          if (story.value?.flags['room'] != null)
            Text('내 도서관: ${story.value!.flags['room']}'),
          const SizedBox(height: 20),
          const Text(
            '내 그림 (보호자 영역에서 삭제할 수 있어요)',
            style: TextStyle(fontSize: 26),
          ),
          gallery.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('작품을 열지 못했어요: $e'),
            data: (items) => items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('아직 작품이 없어요. 자유 그림방에서 그려 보아요!'),
                  )
                : Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: items.reversed
                        .map(
                          (a) => SizedBox(
                            width: 280,
                            child: Card(
                              child: Column(
                                children: [
                                  Image.file(
                                    File(a.path),
                                    height: 180,
                                    width: 280,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => const SizedBox(
                                      height: 180,
                                      child: Center(
                                        child: Text('이미지 파일을 찾지 못했어요'),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${a.created.year}.${a.created.month}.${a.created.day}',
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        await ref.read(drawingProvider.future);
                                        await ref
                                            .read(drawingProvider.notifier)
                                            .load(a.document);
                                        if (context.mounted) {
                                          context.go('/drawing');
                                        }
                                      } catch (_) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    '작품을 다시 열지 못했어요. 저장 공간을 확인해 주세요.',
                                                  ),
                                                ),
                                              );
                                        }
                                      }
                                    },
                                    child: const Text('다시 그리기'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
