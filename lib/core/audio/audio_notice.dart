import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_service.dart';

class AudioNotice extends ConsumerWidget {
  const AudioNotice({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(audioStatusProvider);
    if (status.message == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Material(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8, top: 6, bottom: 6),
          child: Row(
            children: [
              const Icon(Icons.volume_off_outlined),
              const SizedBox(width: 12),
              Expanded(child: Text(status.message!)),
              IconButton(
                tooltip: '음성 안내 닫기',
                onPressed: ref.read(audioStatusProvider.notifier).dismiss,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
