import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/audio/audio_service.dart';
import '../core/audio/sound_effects.dart';
import '../features/parent/presentation/usage_vm.dart';

class AppLifecycle extends ConsumerStatefulWidget {
  final Widget child;
  final GoRouter router;
  const AppLifecycle({super.key, required this.child, required this.router});
  @override
  ConsumerState<AppLifecycle> createState() => _AppLifecycleState();
}

class _AppLifecycleState extends ConsumerState<AppLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    ref
        .read(audioProvider)
        .setActive(lifecycle == null || lifecycle == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref
        .read(usageProvider.notifier)
        .setActive(state == AppLifecycleState.resumed);
    ref.read(audioProvider).setActive(state == AppLifecycleState.resumed);
    ref.read(effectsProvider).setActive(state == AppLifecycleState.resumed);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(usageProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          widget.router.go(
            widget.router.routeInformationProvider.value.uri.path == '/'
                ? '/parent'
                : '/',
          );
        }
      },
      child: widget.child,
    );
  }
}
