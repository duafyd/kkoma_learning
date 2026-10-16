import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/audio/audio_service.dart';
import '../core/audio/sound_effects.dart';
import '../features/home/presentation/home_page.dart';
import '../features/parent/presentation/parent_page.dart';
import '../features/tracing/presentation/trace_page.dart';
import '../features/drawing/presentation/drawing_page.dart';
import '../features/learning/presentation/learning_page.dart';
import '../features/story/presentation/story_page.dart';
import '../features/progress/presentation/gallery_page.dart';
import '../features/parent/presentation/rest_page.dart';
import '../features/parent/presentation/usage_vm.dart';
import 'lifecycle.dart';
import 'app_theme.dart';
import '../features/math/presentation/counting_page.dart';
import '../features/math/presentation/sorting_page.dart';
import '../features/tracing/presentation/prewriting_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    redirect: (context, state) {
      final path = state.uri.path;
      if (ref.read(usageProvider.notifier).expired &&
          (path.startsWith('/learn') ||
              path.startsWith('/trace') ||
              path == '/prewriting' ||
              path.startsWith('/math') ||
              path == '/story' ||
              path == '/drawing')) {
        return '/rest';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomePage()),
      GoRoute(path: '/prewriting', builder: (_, _) => const PrewritingPage()),
      GoRoute(path: '/parent', builder: (_, _) => const ParentPage()),
      GoRoute(path: '/rest', builder: (_, _) => const RestPage()),
      GoRoute(path: '/math/play', builder: (_, _) => const CountingPage()),
      GoRoute(path: '/math/match', builder: (_, _) => const SortingPage()),
      GoRoute(path: '/story', builder: (_, _) => const StoryPage()),
      GoRoute(path: '/gallery', builder: (_, _) => const GalleryPage()),
      GoRoute(path: '/drawing', builder: (_, _) => const DrawingPage()),
      GoRoute(
        path: '/learn/:subject',
        builder: (_, s) => LearningPage(
          subject: s.pathParameters['subject']!,
          initialQuizMode: s.uri.queryParameters['mode'] == 'quiz',
        ),
      ),
      GoRoute(
        path: '/trace/:id',
        builder: (_, s) => TracePage(itemId: s.pathParameters['id']!),
      ),
    ],
  );
  router.routerDelegate.addListener(() {
    ref.read(audioProvider).stop();
    ref.read(effectsProvider).stop();
  });
  ref.onDispose(router.dispose);
  return router;
});

class KkomaApp extends ConsumerWidget {
  const KkomaApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: '꼬마 탐험 공부방',
    debugShowCheckedModeBanner: false,
    routerConfig: ref.watch(routerProvider),
    builder: (context, child) =>
        AppLifecycle(router: ref.read(routerProvider), child: child!),
    theme: StorybookTheme.data,
  );
}
