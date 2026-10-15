import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/activity_scaffold.dart';
import '../../../core/audio/audio_service.dart';
import '../../profile/domain/settings.dart';
import '../../profile/presentation/profile_vm.dart';

class CountingState {
  final int available;
  final Set<int> basket;
  const CountingState(this.available, {this.basket = const {}});
}

final countingProvider = NotifierProvider.autoDispose
    .family<CountingVM, CountingState, int>(CountingVM.new);

class CountingVM extends Notifier<CountingState> {
  final int level;
  CountingVM(this.level);
  @override
  CountingState build() => CountingState(AgeStrategy(level).maxCount);
  void collect(int id) {
    if (id < 0 || id >= state.available || state.basket.contains(id)) return;
    state = CountingState(state.available, basket: {...state.basket, id});
  }

  void add() {
    if (level < 4 || state.basket.length >= state.available) return;
    collect(
      List.generate(
        state.available,
        (i) => i,
      ).firstWhere((i) => !state.basket.contains(i)),
    );
  }

  void remove() {
    if (level < 4 || state.basket.isEmpty) return;
    state = CountingState(
      state.available,
      basket: {...state.basket}..remove(state.basket.last),
    );
  }

  void reset() {
    state = CountingState(state.available);
  }
}

class CountingPage extends ConsumerWidget {
  const CountingPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
            ref.watch(settingsProvider).value ?? const ParentSettings(),
        level = settings.level;
    final s = ref.watch(countingProvider(level)),
        vm = ref.read(countingProvider(level).notifier);
    return ActivityScaffold(
      title: '사과를 모아 세어요',
      child: ListView(
        children: [
          const Text('사과를 바구니로 옮겨요. 눌러서 넣어도 좋아요.'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(
              s.available,
              (i) => s.basket.contains(i)
                  ? const SizedBox(width: 78, height: 78)
                  : Draggable<int>(
                      data: i,
                      feedback: const Material(
                        color: Colors.transparent,
                        child: Text('🍎', style: TextStyle(fontSize: 64)),
                      ),
                      childWhenDragging: const SizedBox(width: 78, height: 78),
                      child: Semantics(
                        label: '사과 ${i + 1}',
                        button: true,
                        child: InkWell(
                          onTap: () => vm.collect(i),
                          child: const SizedBox(
                            width: 78,
                            height: 78,
                            child: Center(
                              child: Text('🍎', style: TextStyle(fontSize: 54)),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          DragTarget<int>(
            onAcceptWithDetails: (d) => vm.collect(d.data),
            builder: (context, candidate, rejected) => Container(
              constraints: const BoxConstraints(minHeight: 170),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: candidate.isEmpty
                    ? const Color(0xffe9dcc4)
                    : const Color(0xffd3e7ca),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Text(
                    '바구니에 ${s.basket.length}개',
                    style: const TextStyle(fontSize: 30),
                  ),
                  Wrap(
                    spacing: 10,
                    children: s.basket
                        .map(
                          (i) =>
                              const Text('🍎', style: TextStyle(fontSize: 40)),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: () => ref
                    .read(audioProvider)
                    .speak(
                      '${s.basket.length}개. ${List.generate(s.basket.length, (i) => '${i + 1}').join(', ')}',
                      settings,
                    ),
                child: const Text('함께 세기'),
              ),
              if (level >= 4) ...[
                OutlinedButton(onPressed: vm.add, child: const Text('하나 더')),
                OutlinedButton(onPressed: vm.remove, child: const Text('하나 덜')),
              ],
              OutlinedButton(onPressed: vm.reset, child: const Text('다시 모으기')),
            ],
          ),
        ],
      ),
    );
  }
}
