import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../learning/domain/learning_models.dart';
import '../../tracing/domain/trace_engine.dart';
import '../../tracing/domain/trace_state.dart';
import '../../tracing/presentation/trace_canvas.dart';
import 'learning_overview_vm.dart';

class LearningOverviewPanel extends ConsumerWidget {
  final int level;
  final bool animations;
  const LearningOverviewPanel({
    super.key,
    required this.level,
    required this.animations,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(learningOverviewProvider(level));
    Widget group(
      String title,
      List<LearningItem> items, {
      int? quizzes,
      List<QuizDefinition> questions = const [],
    }) => ExpansionTile(
      key: ValueKey('overview-$title'),
      title: Text('$title · ${items.length}항목'),
      subtitle: quizzes == null ? null : Text('함께 찾기 $quizzes문항'),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                ActionChip(
                  key: ValueKey('preview-${item.id}'),
                  label: Text(item.symbol),
                  tooltip: '${item.name} · 획 보기',
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => LearningGuidePreview(
                      item: item,
                      strategy: overview.strategyFor(item),
                      animations: animations,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (questions.isNotEmpty)
          TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => LearningQuizPreview(
                title: title,
                questions: questions,
                level: level,
              ),
            ),
            child: Text('$title 함께 찾기 살펴보기'),
          ),
      ],
    );
    return ExpansionTile(
      key: const ValueKey('learning-overview'),
      title: const Text('학습 내용 미리보기'),
      subtitle: Text('기본 경로 $level · 글자를 눌러 실제 획을 확인해요'),
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            '글자 모양·필순·연령별 난이도는 전문가 최종 검수 전이에요. 아이와 함께 살펴보고 학습 경로를 조절해 주세요. 자동 단계 올리기가 켜져 있으면 함께 찾기의 범위가 늘어날 수 있어요.',
          ),
        ),
        group(
          '한글',
          overview.subjects['hangul']!,
          quizzes: overview.quizCounts['hangul'],
          questions: overview.questions['hangul']!,
        ),
        group(
          '영어',
          overview.subjects['english']!,
          quizzes: overview.quizCounts['english'],
          questions: overview.questions['english']!,
        ),
        group(
          '숫자',
          overview.subjects['math']!,
          quizzes: overview.quizCounts['math'],
          questions: overview.questions['math']!,
        ),
        group('손가락 준비 운동', overview.prewriting),
        ExpansionTile(
          title: Text('이야기 ${overview.chapters.length}화'),
          children: [
            for (final (index, chapter) in overview.chapters.indexed)
              ListTile(
                title: Text('${index + 1}화 · ${chapter.title}'),
                subtitle: Text('현재 경로 ${chapter.sceneCount}장면'),
              ),
          ],
        ),
      ],
    );
  }
}

/// Read-only: no trace/session providers, audio, routes or repository writes.
class LearningGuidePreview extends StatefulWidget {
  final LearningItem item;
  final TraceStrategy strategy;
  final bool animations;
  const LearningGuidePreview({
    super.key,
    required this.item,
    required this.strategy,
    required this.animations,
  });
  @override
  State<LearningGuidePreview> createState() => _LearningGuidePreviewState();
}

class _LearningGuidePreviewState extends State<LearningGuidePreview> {
  final canvas = GlobalKey<TraceCanvasState>();
  int stroke = 0;
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final edge = (MediaQuery.sizeOf(context).width - 128).clamp(120.0, 440.0);
    return AlertDialog(
      scrollable: true,
      title: Text('${item.symbol} · ${item.name}'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.example),
            const SizedBox(height: 12),
            SizedBox(
              width: edge,
              height: edge,
              child: IgnorePointer(
                child: TraceCanvas(
                  key: canvas,
                  strokes: item.strokes,
                  state: TraceState(
                    strokeIndex: stroke,
                    completed: item.strokes
                        .take(stroke)
                        .map((path) => path.points)
                        .toList(),
                  ),
                  strategy: widget.strategy,
                  animate: widget.animations,
                  semanticLabel: '${item.symbol} ${stroke + 1}번째 획 미리보기',
                  onStroke: (_) {},
                ),
              ),
            ),
            Text('${stroke + 1} / ${item.strokes.length}획'),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: stroke == 0
                      ? null
                      : () => setState(() => stroke--),
                  child: const Text('이전 획'),
                ),
                OutlinedButton(
                  onPressed: stroke == item.strokes.length - 1
                      ? null
                      : () => setState(() => stroke++),
                  child: const Text('다음 획'),
                ),
                if (widget.animations)
                  TextButton(
                    onPressed: () => canvas.currentState?.demonstrate(),
                    child: const Text('획 시범'),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

class LearningQuizPreview extends StatelessWidget {
  final String title;
  final List<QuizDefinition> questions;
  final int level;
  const LearningQuizPreview({
    super.key,
    required this.title,
    required this.questions,
    required this.level,
  });
  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text('$title 함께 찾기'),
    content: SizedBox(
      width: 440,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            level == 2
                ? '학습 목표에 따른 참고 답이에요. 만 2세 탐색에서는 어떤 선택도 진행할 수 있어요.'
                : '아이와 함께 살펴볼 문제와 참고 답이에요. 실제 학습 진도는 바뀌지 않아요.',
          ),
          for (final q in questions)
            ExpansionTile(
              title: Text(q.prompt),
              children: [
                Text(
                  q.visual,
                  style: const TextStyle(fontSize: 28),
                  textAlign: TextAlign.center,
                ),
                Text('선택: ${q.options.join(' / ')}'),
                Text(
                  q.isExploration
                      ? '어느 쪽을 골라도 좋아요.'
                      : '참고 답: ${q.options[q.answer]}',
                ),
                Text('힌트: ${q.hint}'),
                const SizedBox(height: 12),
              ],
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('닫기'),
      ),
    ],
  );
}
