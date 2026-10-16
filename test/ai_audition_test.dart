import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/generate_ai_auditions.dart';
import 'story_voice_direction_test.dart' as fixtures;

void main() {
  test(
    'default audition plan fixes four cast identities without generating audio',
    () {
      final plan = auditionPlan();
      expect(plan['status'], 'plan-only-not-generated');
      expect(plan['maxRequests'], 4);
      expect(
        auditionLines().map((l) => l.speaker).toSet(),
        auditionVoices.keys.toSet(),
      );
      for (final line in auditionLines()) {
        final request = auditionRequest(line);
        expect(request['store'], isFalse);
        expect(request['max_completion_tokens'], 1024);
        expect(request['modalities'], ['text', 'audio']);
        expect(
          (request['audio'] as Map)['voice'],
          auditionVoices[line.speaker],
        );
        expect(
          ((request['messages'] as List).last as Map)['content'],
          line.text,
        );
      }
    },
  );
  late Directory directory;
  setUp(() {
    directory = Directory.systemTemp.createTempSync('kkoma-auditions-');
  });
  tearDown(() {
    if (!directory.absolute.path.startsWith(
      Directory.systemTemp.absolute.path,
    )) {
      throw StateError('Unexpected temp path');
    }
    directory.deleteSync(recursive: true);
  });
  test('mock audio stays in staging with transcript/usage and pending review; retries skip existing takes', () async {
    var calls = 0;
    Future<Map<String, dynamic>> send(Map<String, dynamic> request) async {
      calls++;
      return {
        'usage': {'total_tokens': 500},
        'choices': [
          {
            'finish_reason': 'stop',
            'message': {
              'audio': {
                'data': base64Encode(
                  fixtures.wav(
                    List.generate(16000, (i) => i.isEven ? 3000 : -3000),
                  ),
                ),
                'transcript': '검수할 다른 문장',
              },
            },
          },
        ],
      };
    }

    await renderAuditions(output: directory, send: send);
    expect(calls, 4);
    final receipt = jsonDecode(
      File('${directory.path}/${auditionLines().first.id}.json')
          .readAsStringSync(),
    ) as Map;
    expect(receipt['listeningReview'], 'pending');
    expect(receipt['transcriptExact'], isFalse);
    expect(receipt['bundled'], isFalse);
    expect(receipt['source'], 'ai-generated');
    await renderAuditions(output: directory, send: send);
    expect(calls, 4);
  });
  test(
    'incomplete and malformed takes stop before writing WAVs or more calls',
    () async {
      for (final choice in [
        {'finish_reason': 'length', 'message': {}},
        {
          'finish_reason': 'stop',
          'message': {
            'audio': {'data': 'bad', 'transcript': 'x'},
          },
        },
      ]) {
        var calls = 0;
        await expectLater(
          renderAuditions(
            output: directory,
            send: (_) async {
              calls++;
              return {
                'choices': [choice],
              };
            },
          ),
          throwsFormatException,
        );
        expect(calls, 1);
        expect(directory.listSync(), isEmpty);
      }
    },
  );
}
