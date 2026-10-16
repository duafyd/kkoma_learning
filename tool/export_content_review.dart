import 'dart:convert';
import 'dart:io';

import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/learning/domain/learning_models.dart';
import 'package:flutter_application_1/features/story/data/story_content.dart';
import 'package:flutter_application_1/features/story/data/support_quizzes.dart';

void main() {
  final quizzes = <String, QuizDefinition>{
    for (final q in learningQuizzes) q.id: q,
    for (final q in storySupportQuizzes.values) q.id: q,
  };
  final uses = <String, Set<String>>{};
  for (final ep in storyEpisodes) {
    for (final scene in ep.scenes) {
      for (final q in [
        ?scene.quiz,
        ?scene.exploreQuiz,
        ...scene.quizVariants.values,
      ]) {
        quizzes[q.id] = q;
        (uses[q.id] ??= {}).add(scene.id);
      }
    }
  }
  final entries = quizzes.values.toList()..sort((a, b) => a.id.compareTo(b.id));
  final report = {
    'educatorApproval': 'pending',
    'listeningApproval': 'pending',
    'note': 'Developer structural checks do not establish age suitability, stroke-order authority or pronunciation quality.',
    'quizzes': [
      for (final q in entries)
        {
          'id': q.id,
          'subject': q.subject,
          'minimumLevel': q.minimumLevel,
          'kind': q.kind.name,
          'prompt': q.prompt,
          'options': q.options,
          'answerIndex': q.answer,
          'answer': q.options[q.answer],
          'hint': q.hint,
          'visual': q.visual,
          'resultVisual': q.resultVisual,
          'sceneIds': uses[q.id]?.toList() ?? [],
          'approval': 'pending',
          if (q.artwork != null)
            'pictures': {
              'objects': q.artwork!.objects.map((g) => g.label).toList(),
              'choices': q.artwork!.choices
                  .map((c) => c.map((g) => g.label).toList())
                  .toList(),
            },
        },
    ],
    'storyPaths': [
      for (var level = 2; level <= 5; level++)
        {
          'level': level,
          'observedPlayTime': null,
          'childObservation': 'pending',
          'chapters': [
            for (final ep in storyEpisodes)
              {
                'id': ep.id,
                'title': ep.title,
                'goal': ep.goal,
                'scenes': [
                  for (final s in ep.forLevel(level))
                    {
                      'id': s.id,
                      'action': s.interaction.name,
                      'text': s.text,
                      'choices': s.choices,
                      'traceId': s.traceId,
                      'quizIds': [
                        ?s.quiz?.id,
                        ?s.exploreQuiz?.id,
                        ...s.quizVariants.values.map((q) => q.id),
                      ],
                    },
                ],
              },
          ],
        },
    ],
  };
  final dir = Directory('docs/review')..createSync(recursive: true);
  File('${dir.path}/content_review.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
  String cell(Object? value) => '"${'$value'.replaceAll('"', '""')}"';
  final csv = StringBuffer(
    'id,subject,level,prompt,options,answer,hint,educator_approval\n',
  );
  for (final q in entries) {
    csv.writeln(
      [
        q.id,
        q.subject,
        q.minimumLevel,
        q.prompt,
        q.options.join(' | '),
        q.options[q.answer],
        q.hint,
        'pending',
      ].map(cell).join(','),
    );
  }
  File('${dir.path}/quiz_review.csv').writeAsStringSync('\uFEFF$csv');
  stdout.writeln(
    '${entries.length} unique quiz review entries, 48 age/chapter paths; educator/listening approvals pending.',
  );
}
