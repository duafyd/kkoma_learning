import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/activity_scaffold.dart';
import '../data/prewriting_content.dart';

class PrewritingPage extends StatelessWidget {
  const PrewritingPage({super.key});
  @override
  Widget build(BuildContext context) => ActivityScaffold(
    title: '손가락 준비 운동',
    child: ListView(
      children: [
        const Text(
          '글자 전에, 손가락으로 놀아요',
          style: TextStyle(fontFamily: 'Jua', fontSize: 28),
        ),
        const SizedBox(height: 8),
        const Text('점은 톡, 길은 쭉! 좋아하는 모양부터 해도 좋아요.'),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, c) => Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final (index, item) in prewritingItems.indexed)
                SizedBox(
                  width: c.maxWidth < 580 ? c.maxWidth : (c.maxWidth - 32) / 3,
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      key: ValueKey('prewriting-${item.id}'),
                      onTap: () => context.go('/trace/${item.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(0xffe0eee5),
                              child: Icon(
                                [
                                  Icons.touch_app_rounded,
                                  Icons.arrow_forward_rounded,
                                  Icons.south_rounded,
                                  Icons.circle_outlined,
                                  Icons.waves_rounded,
                                  Icons.terrain_rounded,
                                ][index],
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontFamily: 'Jua',
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
