import 'package:flutter/material.dart';

import '../domain/trace_coach.dart';

class TraceCoachBar extends StatelessWidget {
  final ValueNotifier<TracePreview?> preview;
  final int stroke, total;
  final bool done;
  final String completionPrompt;
  const TraceCoachBar({
    super.key,
    required this.preview,
    required this.stroke,
    required this.total,
    required this.done,
    this.completionPrompt = '다음 글자도 만나 볼까?',
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 500;
    return ValueListenableBuilder(
      valueListenable: preview,
      builder: (context, value, _) => Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: const Color(0xffe8f2eb),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              done ? '멋진 집중이었어!' : '${stroke + 1}번째 길을 함께 그려요',
              style: const TextStyle(
                fontFamily: 'Jua',
                fontSize: 23,
                color: Color(0xff286458),
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < total; i++)
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < stroke
                            ? const Color(0xff387b6b)
                            : i == stroke && !done
                            ? const Color(0xffeab756)
                            : Colors.white,
                      ),
                      child: i < stroke
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.white,
                            )
                          : Text(
                              '${i + 1}',
                              style: const TextStyle(fontSize: 15),
                            ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Text(
              done ? completionPrompt : value?.message ?? '시범을 보고, 빛나는 점을 찾아요',
              key: const ValueKey('trace-coaching'),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: done ? 1 : (stroke + (value?.progress ?? 0)) / total,
                minHeight: 7,
                color: const Color(0xff387b6b),
                backgroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
