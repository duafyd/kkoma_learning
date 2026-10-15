import 'package:flutter/material.dart';

import '../../learning/domain/learning_models.dart';
import 'story_picture_quiz.dart';

/// Presentation only: the state machine validates every piece and destination.
class StoryPlacementBoard extends StatelessWidget {
  final QuizArtwork artwork;
  final List<int> placed;
  final void Function(int piece, int slot) onPlace;
  const StoryPlacementBoard({
    super.key,
    required this.artwork,
    required this.placed,
    required this.onPlace,
  });
  @override
  Widget build(BuildContext context) {
    final bridge = artwork.arrangement == QuizArrangement.bridge;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bridge ? const Color(0xffdcefe9) : const Color(0xffe8e3f3),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Text(
            bridge ? '돌을 끌어놓거나 눌러 다리를 이어요.' : '별을 끌어놓거나 눌러 별자리를 이어요.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 8,
            children: [
              for (var slot = 0; slot < artwork.objects.length; slot++)
                DragTarget<int>(
                  key: ValueKey('place-target-$slot'),
                  onWillAcceptWithDetails: (d) =>
                      slot == placed.length && !placed.contains(d.data),
                  onAcceptWithDetails: (d) => onPlace(d.data, slot),
                  builder: (context, candidates, rejected) => Semantics(
                    label: '${artwork.objectName} 자리 ${slot + 1}',
                    child: Container(
                      width: 62,
                      height: 70,
                      decoration: BoxDecoration(
                        color: slot < placed.length
                            ? const Color(0xfffff5cb)
                            : Colors.white70,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          width: 2,
                          color: candidates.isNotEmpty || slot == placed.length
                              ? const Color(0xffc89736)
                              : const Color(0xffb5c7c1),
                        ),
                      ),
                      child: Center(
                        child: slot < placed.length
                            ? QuizGlyphPicture(
                                glyph: artwork.objects[placed[slot]],
                                edge: 48,
                              )
                            : Text(
                                '${slot + 1}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Color(0xff788b85),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Icon(Icons.arrow_upward_rounded),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < artwork.objects.length; i++)
                Draggable<int>(
                  data: i,
                  maxSimultaneousDrags: placed.contains(i) ? 0 : 1,
                  feedback: Material(
                    color: Colors.transparent,
                    child: QuizGlyphPicture(
                      glyph: artwork.objects[i],
                      edge: 56,
                    ),
                  ),
                  childWhenDragging: const SizedBox(width: 60, height: 64),
                  child: Semantics(
                    button: true,
                    label:
                        '${artwork.objectName} ${i + 1}, ${placed.contains(i) ? '놓았어요' : '눌러서 다음 자리에 놓기'}',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: ValueKey('quiz-object-$i'),
                        borderRadius: BorderRadius.circular(16),
                        onTap: placed.contains(i)
                            ? null
                            : () => onPlace(i, placed.length),
                        child: Container(
                          width: 60,
                          height: 64,
                          decoration: BoxDecoration(
                            color: placed.contains(i)
                                ? const Color(0xffcddfd7)
                                : const Color(0xfffffcf2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: placed.contains(i)
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Color(0xff366b5f),
                                  )
                                : QuizGlyphPicture(
                                    glyph: artwork.objects[i],
                                    edge: 48,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${placed.length} / ${artwork.objects.length}개',
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
