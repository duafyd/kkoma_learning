import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../profile/presentation/profile_vm.dart';
import '../../story/presentation/story_illustration.dart';
import '../../story/presentation/story_vm.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: ListView(
              padding: EdgeInsets.all(
                MediaQuery.sizeOf(context).width < 600 ? 20 : 32,
              ),
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: StorybookTheme.teal,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '꼬마 탐험 공부방',
                        style: TextStyle(fontFamily: 'Jua', fontSize: 25),
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: '보호자 영역',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      onPressed: () => context.go('/parent'),
                      icon: const Icon(Icons.lock_outline_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  MediaQuery.sizeOf(context).width < 600
                      ? '오늘은 어떤\n이야기를 만들까?'
                      : '오늘은 어떤 이야기를 만들까?',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                settings.when(
                  data: (s) => Text(
                    '만 ${s.age}세 탐험가 · 모아, 루루, 토토가 기다려요',
                    style: const TextStyle(color: Color(0xff63777c)),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const Text('설정을 불러오지 못했어요'),
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.gesture_rounded,
                      color: StorybookTheme.teal,
                      size: 32,
                    ),
                    title: const Text(
                      '손가락 준비 운동',
                      style: TextStyle(fontFamily: 'Jua', fontSize: 23),
                    ),
                    subtitle: const Text('점 · 선 · 동그라미로 먼저 놀아요'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.go('/prewriting'),
                  ),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, c) {
                    final scale =
                        MediaQuery.textScalerOf(context).scale(20) / 20;
                    final shelf = _ActivityShelf(scale: scale);
                    if (c.maxWidth >= 1050) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 10,
                            child: _AdventureCover(
                              height: 410 + (scale - 1) * 150,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(flex: 11, child: shelf),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _AdventureCover(height: 330 + (scale - 1) * 120),
                        const SizedBox(height: 24),
                        shelf,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Material(
                  color: const Color(0xffe9eee5),
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => context.go('/gallery'),
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.collections_bookmark_rounded,
                            size: 32,
                            color: StorybookTheme.teal,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '내 작품 · 모험 지도',
                                  style: TextStyle(
                                    fontFamily: 'Jua',
                                    fontSize: 22,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '내가 그린 그림과 모아 둔 별빛',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: StorybookTheme.teal,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdventureCover extends ConsumerWidget {
  final double height;
  const _AdventureCover({required this.height});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(storyProvider).asData?.value;
    final machine = ref.read(storyProvider.notifier).machine;
    final scene = saved == null ? null : machine.scene(saved);
    final chapter = saved == null ? null : machine.episodes[saved.episode];
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24353b2d),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xff19343b)),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 88,
              child: StoryIllustration(
                background: saved == null
                    ? 'library'
                    : machine.background(saved),
                character: scene?.character ?? '모아',
                companion: saved?.flags['companion'] ?? '루루',
                animate: false,
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, .35, .6, 1],
                  colors: [
                    Color(0x9c152c36),
                    Colors.transparent,
                    Colors.transparent,
                    Color(0xc919343b),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 24,
              top: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '오늘의 모험',
                    style: TextStyle(
                      color: Color(0xffffdc8b),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '별빛 도서관과\n사라진 이야기',
                    style: TextStyle(
                      fontFamily: 'Jua',
                      color: Colors.white,
                      fontSize: 30,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 98,
              child: Text(
                chapter == null
                    ? '친구들과 첫 모험을 떠나요'
                    : '${chapter.id}화 · ${chapter.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Jua',
                  color: Colors.white,
                  fontSize: 20,
                  shadows: [Shadow(color: Color(0xff19343b), blurRadius: 8)],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: StorybookTheme.gold,
                  foregroundColor: StorybookTheme.ink,
                ),
                onPressed: () => context.go('/story'),
                icon: const Icon(Icons.auto_stories_rounded),
                label: const Text('별빛 이야기 펼치기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityShelf extends StatelessWidget {
  final double scale;
  const _ActivityShelf({required this.scale});
  @override
  Widget build(BuildContext context) {
    const books = [
      (
        '한글 놀이터',
        '소리와 글자 친구',
        '가',
        'ep2-gate',
        '/learn/hangul',
        Color(0xfff6e3d7),
        Color(0xff9b4e32),
      ),
      (
        'English Garden',
        '알파벳을 만나요',
        'Aa',
        'ep5-dark',
        '/learn/english',
        Color(0xffdcece5),
        Color(0xff256d5c),
      ),
      (
        '숫자 탐험대',
        '하나, 둘, 셋!',
        '123',
        'ep6-bridge',
        '/learn/math',
        Color(0xffe1eaf6),
        Color(0xff466d9d),
      ),
      (
        '자유 그림방',
        '마음껏 그려요',
        '✿',
        'ep7-color',
        '/drawing',
        Color(0xffeee3f2),
        Color(0xff80558c),
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth < 400 && scale > 1.2 ? 1 : 2;
        final width = (c.maxWidth - 16 * (columns - 1)) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final book in books)
              SizedBox(
                width: width,
                child: Material(
                  color: book.$6,
                  borderRadius: BorderRadius.circular(22),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.go(book.$5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 98,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                StoryIllustration.assetFor(book.$4),
                                fit: BoxFit.cover,
                                cacheWidth: 520,
                                excludeFromSemantics: true,
                              ),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      book.$6,
                                      book.$6.withValues(alpha: .7),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 16,
                                bottom: 6,
                                child: book.$5 == '/drawing'
                                    ? Icon(
                                        Icons.palette_rounded,
                                        size: 52,
                                        color: book.$7,
                                      )
                                    : Text(
                                        book.$3,
                                        style: TextStyle(
                                          fontFamily: 'Jua',
                                          fontSize: 52,
                                          color: book.$7,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.white,
                                              blurRadius: 14,
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.$1,
                                style: const TextStyle(
                                  fontFamily: 'Jua',
                                  fontSize: 21,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                book.$2,
                                style: TextStyle(fontSize: 15, color: book.$7),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
