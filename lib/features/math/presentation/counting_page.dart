import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/activity_scaffold.dart';
import '../../../core/audio/audio_service.dart';
import '../../profile/domain/settings.dart';
import '../../profile/presentation/profile_vm.dart';
import '../../../core/widgets/activity_intro.dart';
import '../../story/presentation/story_picture_quiz.dart';
import '../../learning/domain/learning_models.dart';
import 'counting_vm.dart';
export 'counting_vm.dart';

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
          const ActivityIntro(
            icon: Icons.shopping_basket_rounded,
            title: '사과 소풍을 준비해요',
            instruction: '사과를 바구니로 옮겨요. 눌러서 넣어도 좋아요.',
          ),
          const SizedBox(height: 20),
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
                        child: QuizGlyphPicture(
                          glyph: QuizGlyph.apple,
                          edge: 64,
                        ),
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
                              child: QuizGlyphPicture(
                                glyph: QuizGlyph.apple,
                                edge: 54,
                              ),
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
                    style: const TextStyle(fontFamily: 'Jua', fontSize: 30),
                  ),
                  Wrap(
                    spacing: 10,
                    children: s.basket
                        .map(
                          (i) => const QuizGlyphPicture(
                            glyph: QuizGlyph.apple,
                            edge: 40,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (level >= 4 && s.change != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Text(
                      s.change!.delta > 0 ? '하나가 더 왔어요' : '하나를 꺼냈어요',
                      style: const TextStyle(fontFamily: 'Jua', fontSize: 23),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.change!.equation,
                      key: const ValueKey('counting-equation'),
                      style: const TextStyle(
                        fontFamily: 'Jua',
                        fontSize: 32,
                        color: Color(0xff17776b),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
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
