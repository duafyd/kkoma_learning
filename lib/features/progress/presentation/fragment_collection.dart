import 'package:flutter/material.dart';

/// A read-only view of the same saved fragments shown inside the story.
class FragmentCollection extends StatelessWidget {
  final Set<int> collected;
  const FragmentCollection({super.key, required this.collected});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xff213e48), Color(0xff385d62)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xffceaa63), width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          collected.length == 12 ? '다시 열린 도서관 책' : '열두 칸 수집책',
          style: const TextStyle(
            fontFamily: 'Jua',
            fontSize: 24,
            color: Color(0xffffe3a5),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '모은 조각은 같은 번호에서 빛나요.',
          style: TextStyle(color: Color(0xfff5eddc)),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final columns = c.maxWidth >= 660 ? 12 : 6;
            final width = (c.maxWidth - (columns - 1) * 8) / columns;
            return Wrap(
              spacing: 8,
              runSpacing: 12,
              children: [
                for (var chapter = 1; chapter <= 12; chapter++)
                  Semantics(
                    key: ValueKey('fragment-slot-$chapter'),
                    label:
                        '$chapter번째 별조각 ${collected.contains(chapter) ? '담았어요' : '빈칸'}',
                    image: true,
                    excludeSemantics: true,
                    child: Container(
                      width: width,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: collected.contains(chapter)
                            ? const Color(0xffffdf94)
                            : const Color(0xff29454f),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xffad9568)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            collected.contains(chapter)
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 30,
                            color: collected.contains(chapter)
                                ? const Color(0xff965719)
                                : const Color(0xffb7c9c7),
                          ),
                          Text(
                            '$chapter',
                            style: TextStyle(
                              fontFamily: 'Jua',
                              fontSize: 18,
                              color: collected.contains(chapter)
                                  ? const Color(0xff633f27)
                                  : const Color(0xffe5eeee),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
