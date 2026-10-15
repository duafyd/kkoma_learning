import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/activity_scaffold.dart';

class RestPage extends StatelessWidget {
  const RestPage({super.key});
  @override
  Widget build(BuildContext context) => ActivityScaffold(
    title: '잠깐 쉬어요',
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.nightlight_round, size: 90),
          const Text(
            '오늘도 함께 탐험했어요!\n눈과 손을 쉬게 해 주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/gallery'),
            child: const Text('내 작품 보기'),
          ),
          TextButton(
            onPressed: () => context.go('/parent'),
            child: const Text('보호자 영역'),
          ),
        ],
      ),
    ),
  );
}
