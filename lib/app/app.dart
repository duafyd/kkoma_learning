import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/audio/audio_service.dart';
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
import '../features/math/presentation/counting_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    redirect: (context, state) {
      final path = state.uri.path;
      if (ref.read(usageProvider.notifier).expired &&
          (path.startsWith('/learn') ||
              path.startsWith('/trace') ||
              path.startsWith('/math') ||
              path == '/story' ||
              path == '/drawing')) {
        return '/rest';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomePage()),
      GoRoute(path: '/parent', builder: (_, _) => const ParentPage()),
      GoRoute(path: '/rest', builder: (_, _) => const RestPage()),
      GoRoute(path: '/math/play', builder: (_, _) => const CountingPage()),
      GoRoute(path: '/story', builder: (_, _) => const StoryPage()),
      GoRoute(path: '/gallery', builder: (_, _) => const GalleryPage()),
      GoRoute(path: '/drawing', builder: (_, _) => const DrawingPage()),
      GoRoute(
        path: '/learn/:subject',
        builder: (_, s) => LearningPage(subject: s.pathParameters['subject']!),
      ),
      GoRoute(
        path: '/trace/:id',
        builder: (_, s) => TracePage(itemId: s.pathParameters['id']!),
      ),
    ],
  );
  router.routerDelegate.addListener(() => ref.read(audioProvider).stop());
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
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xfffaf7ef),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff376e64)),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 19),
        titleLarge: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(88, 60),
          textStyle: const TextStyle(fontSize: 21),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(88, 60)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(60, 60)),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Color(0xffedf1e5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
    ),
  );
}
