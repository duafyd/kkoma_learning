import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../audio/audio_notice.dart';

class ActivityScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget> actions;
  const ActivityScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      leading: IconButton(
        tooltip: '집으로',
        icon: const Icon(Icons.home_rounded),
        onPressed: () => context.go('/'),
      ),
      actions: actions,
    ),
    body: SafeArea(
      child: Column(
        children: [
          const AudioNotice(),
          Expanded(
            child: Padding(padding: const EdgeInsets.all(20), child: child),
          ),
        ],
      ),
    ),
  );
}

Future<bool> confirmAction(BuildContext context, String text) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('확인'),
          ),
        ],
      ),
    ) ??
    false;
