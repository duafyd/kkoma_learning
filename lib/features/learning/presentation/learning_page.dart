import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/widgets/activity_scaffold.dart';
import '../../profile/domain/settings.dart';
import '../../profile/presentation/profile_vm.dart';
import '../../parent/presentation/usage_vm.dart';
import '../domain/learning_models.dart';
import 'learning_vm.dart';

class LearningPage extends ConsumerStatefulWidget {
  final String subject;
  const LearningPage({super.key, required this.subject});
  @override
  ConsumerState<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends ConsumerState<LearningPage> {
  bool quizMode = false;
  String? autoReadKey;
  Future<void> safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('진도를 저장하지 못했어요. 다시 시도해 주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!['hangul', 'english', 'math'].contains(widget.subject)) {
      return const ActivityScaffold(title: '학습', child: Text('과목을 찾을 수 없어요.'));
    }
    final asyncState = ref.watch(learningProvider(widget.subject));
    if (!asyncState.hasValue) {
      return ActivityScaffold(
        title: '학습',
        child: asyncState.hasError
            ? const Text('학습을 열지 못했어요. 다시 열어 주세요.')
            : const Center(child: CircularProgressIndicator()),
      );
    }
    final state = asyncState.requireValue,
        vm = ref.read(learningProvider(widget.subject).notifier);
    final settings =
        ref.watch(settingsProvider).value ?? const ParentSettings();
    final title =
        {
          'hangul': '한글 놀이터',
          'english': 'English Garden',
          'math': '숫자 탐험대',
        }[widget.subject] ??
        '학습';
    return ActivityScaffold(
      title: title,
      actions: [
        if (widget.subject == 'math')
          TextButton(
            onPressed: () => context.go('/math/play'),
            child: const Text('사과 모으기'),
          ),
        TextButton(
          onPressed: () => setState(() => quizMode = !quizMode),
          child: Text(quizMode ? '글자 듣기' : '함께 찾기'),
        ),
      ],
      child: quizMode
          ? _quiz(vm, state, settings)
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: MediaQuery.sizeOf(context).width < 600
                    ? 600
                    : 300,
                mainAxisExtent:
                    340 + (MediaQuery.textScalerOf(context).scale(25) - 25) * 6,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: vm.items.length,
              itemBuilder: (context, index) {
                final item = vm.items[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => _readItem(item, settings),
                            child: Text(
                              item.symbol,
                              style: const TextStyle(fontSize: 66),
                            ),
                          ),
                        ),
                        Text(
                          '${item.picture} ${item.example}',
                          style: const TextStyle(fontSize: 25),
                        ),
                        if (widget.subject == 'english' && settings.level >= 4)
                          Text(
                            '${item.symbol.toUpperCase()} ↔ ${item.symbol.toLowerCase()}',
                          ),
                        if (widget.subject == 'math')
                          Text(
                            List.filled(int.parse(item.symbol), '●').join(' '),
                            maxLines: 2,
                            style: const TextStyle(fontSize: 15),
                          ),
                        Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              tooltip: '${item.symbol} 읽어 주기',
                              onPressed: () => _readItem(item, settings),
                              icon: const Icon(Icons.volume_up),
                            ),
                            if (item.strokes.isNotEmpty)
                              OutlinedButton(
                                onPressed: () =>
                                    context.go('/trace/${item.id}'),
                                child: const Text('따라 그리기'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _readItem(LearningItem item, ParentSettings settings) async {
    await safe(
      () => ref.read(learningProvider(widget.subject).notifier).listen(item),
    );
    if (!mounted) return;
    final expired = await ref.read(usageProvider.notifier).boundary();
    if (mounted && expired) context.go('/rest');
  }

  Widget _quiz(LearningVM vm, LearningSession state, ParentSettings settings) {
    final q = vm.quiz;
    if (autoReadKey != q.id && settings.autoRead) {
      autoReadKey = q.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(audioProvider).speak(q.prompt, settings);
      });
    }
    return ListView(
      children: [
        Text(q.prompt, style: Theme.of(context).textTheme.headlineMedium),
        IconButton(
          tooltip: '문제 읽기',
          onPressed: () => ref.read(audioProvider).speak(q.prompt, settings),
          icon: const Icon(Icons.volume_up),
        ),
        AnimatedSwitcher(
          duration: Duration(milliseconds: settings.animations ? 300 : 0),
          child: Text(
            state.answered && q.resultVisual != null
                ? q.resultVisual!
                : q.visual,
            key: ValueKey('${q.id}-${state.answered}'),
            style: const TextStyle(fontSize: 60),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: List.generate(
            q.options.length,
            (i) => FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: state.hint >= 2 && i == q.answer
                    ? const Color(0xffc69424)
                    : null,
              ),
              onPressed: state.answered ? null : () => safe(() => vm.answer(i)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(q.options[i], style: const TextStyle(fontSize: 32)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(state.message, textAlign: TextAlign.center),
        if (state.hint > 0) Text(q.hint, textAlign: TextAlign.center),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton(
              onPressed: () => safe(vm.showHint),
              child: const Text('힌트'),
            ),
            if (state.failures >= 2 && !state.answered)
              OutlinedButton(
                onPressed: () => safe(vm.easier),
                child: const Text('다른 길로 가기'),
              ),
            if (settings.help &&
                state.failures >= settings.helpAfter &&
                !state.answered)
              FilledButton(
                onPressed: () => safe(vm.assist),
                child: const Text('친구와 함께 통과'),
              ),
            if (state.answered)
              FilledButton(
                onPressed: () => safe(() async {
                  await vm.next();
                  final expired = await ref
                      .read(usageProvider.notifier)
                      .boundary();
                  if (mounted && expired) context.go('/rest');
                }),
                child: const Text('다음 놀이'),
              ),
          ],
        ),
      ],
    );
  }
}
