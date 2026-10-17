import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../story/data/story_content.dart';
import '../../story/domain/story_models.dart';
import '../../story/domain/story_quest.dart';
import 'fragment_collection.dart';
import '../../story/presentation/story_illustration.dart';

class AdventureMap extends StatelessWidget {
  final StorySnapshot snapshot;
  const AdventureMap({super.key, required this.snapshot});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final collected = StoryQuest.collectedFrom(snapshot);
      final columns = c.maxWidth < 560
          ? 2
          : c.maxWidth < 900
          ? 3
          : 4;
      final width = (c.maxWidth - (columns - 1) * 12) / columns;
      final textScale = MediaQuery.textScalerOf(context).scale(20) / 20;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FragmentCollection(collected: collected),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final ep in storyEpisodes)
                SizedBox(
                  width: width,
                  child: Card(
                    child: InkWell(
                      key: ValueKey('map-chapter-${ep.id}'),
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text('${ep.id}화 · ${ep.title}'),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.asset(
                                    StoryIllustration.assetFor(
                                      ep.scenes.first.background,
                                    ),
                                    fit: BoxFit.cover,
                                    cacheWidth: 600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(ep.goal),
                                const SizedBox(height: 12),
                                Text(
                                  collected.contains(ep.id)
                                      ? '함께 모은 ${ep.reward}'
                                      : snapshot.episode + 1 == ep.id
                                      ? '지금 모험하고 있는 이야기예요'
                                      : '지도에서 미리 만나는 이야기예요',
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('지도 보기'),
                            ),
                            if (snapshot.episode + 1 == ep.id)
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  context.go('/story');
                                },
                                child: const Text('이어서 모험하기'),
                              ),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            child: Image.asset(
                              StoryIllustration.assetFor(
                                collected.contains(ep.id)
                                    ? ep.scenes.last.backgroundVariants[snapshot
                                              .flags['room']] ??
                                          ep.scenes.last.background
                                    : ep.scenes.first.background,
                              ),
                              height: width * .62,
                              fit: BoxFit.cover,
                              cacheWidth: 400,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                            child: Row(
                              children: [
                                Icon(
                                  collected.contains(ep.id)
                                      ? Icons.stars_rounded
                                      : Icons.auto_stories_rounded,
                                  color: collected.contains(ep.id)
                                      ? const Color(0xffb77c20)
                                      : const Color(0xff527469),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${ep.id}화',
                                  style: const TextStyle(
                                    fontFamily: 'Jua',
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 60 * textScale,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                              child: Text(
                                ep.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Jua',
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    },
  );
}
