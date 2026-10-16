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
      title: Tooltip(
        message: title,
        child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      leading: IconButton.filledTonal(
        style: IconButton.styleFrom(backgroundColor: Colors.white),
        tooltip: '집으로',
        icon: const Icon(Icons.home_rounded),
        onPressed: () => context.go('/'),
      ),
      actions: MediaQuery.sizeOf(context).width < 600 ? [] : actions,
      bottom: MediaQuery.sizeOf(context).width < 600 && actions.isNotEmpty
          ? PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: SizedBox(
                height: 64,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: actions),
                ),
              ),
            )
          : null,
    ),
    body: SafeArea(
      child: Column(
        children: [
          const AudioNotice(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(
                MediaQuery.sizeOf(context).shortestSide < 600 ? 12 : 20,
              ),
              child: child,
            ),
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
