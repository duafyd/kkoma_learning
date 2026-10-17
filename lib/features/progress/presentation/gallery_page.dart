import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/activity_scaffold.dart';
import '../../drawing/presentation/drawing_vm.dart';
import '../../story/domain/story_quest.dart';
import '../../../core/widgets/activity_intro.dart';
import '../../drawing/domain/drawing_renderer.dart';
import '../../drawing/domain/drawing.dart';
import 'adventure_map.dart';
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
          ActivityIntro(
            icon: Icons.explore_rounded,
            title: story.when(
              data: (s) => '별조각 ${StoryQuest.collectedFrom(s).length} / 12',
              loading: () => '수집책을 여는 중이에요',
              error: (_, _) => '수집책을 다시 열어 주세요',
            ),
            instruction: '조각으로 책의 빈칸을 채워요.\n표지를 눌러 이야기를 만나요.',
          ),
          const SizedBox(height: 20),
          story.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Text('모험 지도를 열지 못했어요. 다시 들어와 주세요.'),
            data: (s) => AdventureMap(snapshot: s),
          ),
          if (story.value?.flags['room'] != null)
            Text('내 도서관: ${story.value!.flags['room']}'),
          const SizedBox(height: 20),
          const ActivityIntro(
            icon: Icons.palette_rounded,
            title: '나의 작은 전시회',
            instruction: '그림을 눌러 크게 봐요. 다시 그려 새 작품을 만들 수도 있어요.',
          ),
          const SizedBox(height: 20),
          gallery.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('작품을 열지 못했어요: $e'),
            data: (items) => items.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.brush_rounded,
                          size: 56,
                          color: Color(0xff527469),
                        ),
                        const SizedBox(height: 12),
                        const Text('아직 작품이 없어요. 자유 그림방에서 그려 보아요!'),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.go('/drawing'),
                          child: const Text('첫 작품 그리기'),
                        ),
                      ],
                    ),
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
                                  InkWell(
                                    key: ValueKey('artwork-preview-${a.id}'),
                                    onTap: () => showDialog<void>(
                                      context: context,
                                      builder: (dialogContext) => Dialog(
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 900,
                                            maxHeight: 700,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              children: [
                                                Expanded(
                                                  child: _ArtworkPicture(a),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        dialogContext,
                                                      ),
                                                  child: const Text(
                                                    '전시회로 돌아가기',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    child: Container(
                                      height: 200,
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xffe9d8b8),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: _ArtworkPicture(a),
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

class _ArtworkPicture extends StatelessWidget {
  final Artwork artwork;
  const _ArtworkPicture(this.artwork);
  @override
  Widget build(BuildContext context) => Semantics(
    label: '내가 그린 작품',
    image: true,
    child: Image.file(
      File(artwork.path),
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => SizedBox.expand(
        child: CustomPaint(painter: DrawingPainter(artwork.document)),
      ),
    ),
  );
}
