import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../profile/presentation/profile_vm.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    const entries = [
      ('오늘의 모험', '별빛 도서관으로 떠나요', Icons.auto_stories, '/story'),
      ('한글 놀이터', '듣고, 찾고, 따라 그려요', Icons.translate, '/learn/hangul'),
      ('English Garden', 'Letters and friends', Icons.abc, '/learn/english'),
      ('숫자 탐험대', '함께 세어 보아요', Icons.looks_3, '/learn/math'),
      ('자유 그림방', '내 마음을 그려요', Icons.palette, '/drawing'),
      ('내 작품 · 모험 지도', '그림과 별빛을 모아요', Icons.collections, '/gallery'),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('꼬마 탐험 공부방'),
        actions: [
          IconButton(
            tooltip: '보호자 영역',
            onPressed: () => context.go('/parent'),
            icon: const Icon(Icons.lock_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              '모아 · 루루 · 토토와 함께 놀아요!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            settings.when(
              data: (s) => Text('만 ${s.age}세 탐험가 · 모든 활동은 이 기기에 저장돼요'),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => const Text('설정을 불러오지 못했어요'),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, c) => Wrap(
                spacing: 18,
                runSpacing: 18,
                children: entries
                    .map(
                      (e) => SizedBox(
                        width: c.maxWidth >= 850
                            ? (c.maxWidth - 36) / 3
                            : c.maxWidth >= 520
                            ? (c.maxWidth - 18) / 2
                            : c.maxWidth,
                        height: 250,
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => context.go(e.$4),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    e.$3,
                                    size: 46,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                  Text(
                                    e.$1,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge,
                                  ),
                                  Text(e.$2),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
