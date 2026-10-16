import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'voice_catalog.dart';
import 'voice_quality.dart';

/// Offline production utility, never imported by the app. The default creates
/// a reviewable plan only: no credentials, network requests, billing or WAVs.
const auditionVoices = {
  '모아': 'marin',
  '루루': 'coral',
  '토토': 'cedar',
  '휙휙': 'ash',
};
const auditionModel = 'gpt-audio-1.5';

Map<String, dynamic> auditionRequest(VoiceLine line) => {
  'model': auditionModel,
  'modalities': ['text', 'audio'],
  'audio': {'voice': auditionVoices[line.speaker], 'format': 'wav'},
  'store': false,
  'max_completion_tokens': 1024,
  'messages': [
    {
      'role': 'system',
      'content':
          'Perform pre-written Korean picture-book dialogue for children aged 2–5. '
          'Speak only the user text, exactly, with no introduction, commentary, music or sound effects. '
          'Keep a consistent character voice and natural Korean pronunciation. '
          'Character: ${line.speaker}. Emotion: ${line.emotion}. '
          '${line.performance['delivery']} ${line.performance['pacing']}',
    },
    {'role': 'user', 'content': line.text},
  ],
};

List<VoiceLine> auditionLines() {
  final lines = buildVoiceCatalog();
  return [
    for (final speaker in auditionVoices.keys)
      lines.firstWhere(
        (l) =>
            l.category == 'story-dialogue' &&
            l.speaker == speaker &&
            l.text.length <= 150,
      ),
  ];
}

Map<String, dynamic> auditionPlan() {
  final lines = auditionLines();
  return {
    'status': 'plan-only-not-generated',
    'model': auditionModel,
    'endpoint': 'https://api.openai.com/v1/chat/completions',
    'maxRequests': lines.length,
    'inputCharacters': lines.fold<int>(0, (n, line) => n + line.text.length),
    'cost': 'Paid API. No charge has been made. Actual cost depends on input/output token usage and account pricing; request/token limits are not a dollar spending cap.',
    'casting': auditionVoices,
    'takes': [
      for (final line in lines)
        {
          'id': line.id,
          'speaker': line.speaker,
          'text': line.text,
          'request': auditionRequest(line),
          'listeningReview': 'pending',
        },
    ],
  };
}

Future<void> renderAuditions({
  required Directory output,
  required Future<Map<String, dynamic>> Function(Map<String, dynamic>) send,
}) async {
  await output.create(recursive: true);
  for (final line in auditionLines()) {
    final file = File('${output.path}/${line.id}.wav');
    final receipt = File('${output.path}/${line.id}.json');
    // No automatic replacement or retry: avoid destroying a reviewed take or
    // paying twice after an ambiguous failure. Existing files remain untouched.
    if (file.existsSync() || receipt.existsSync()) continue;
    final response = await send(auditionRequest(line));
    final choices = response['choices'];
    if (choices is! List || choices.isEmpty || choices.first is! Map) {
      throw const FormatException('Missing audio choice');
    }
    final choice = choices.first as Map;
    if (choice['finish_reason'] != 'stop') {
      throw const FormatException('Incomplete audio take');
    }
    final message = choice['message'];
    final audio = message is Map ? message['audio'] : null;
    if (audio is! Map ||
        audio['data'] is! String ||
        audio['transcript'] is! String) {
      throw const FormatException('Missing audio or transcript');
    }
    final encoded = audio['data'] as String;
    if (encoded.length > 8000000) {
      throw const FormatException('Audio take exceeds size limit');
    }
    final Uint8List bytes = base64Decode(encoded);
    final quality = inspectVoicePcm(bytes);
    if (quality['formatError'] != null ||
        (quality['warnings'] as List).contains('digital-silence')) {
      throw const FormatException('Invalid or silent WAV take');
    }
    if (file.existsSync() || receipt.existsSync()) {
      throw StateError('Take already exists');
    }
    await file.writeAsBytes(bytes, flush: true);
    await receipt.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert({'id': line.id, 'speaker': line.speaker, 'voice': auditionVoices[line.speaker], 'model': auditionModel, 'source': 'ai-generated', 'requestedText': line.text, 'returnedTranscript': audio['transcript'], 'transcriptExact': audio['transcript'] == line.text, 'usage': response['usage'], 'quality': quality, 'listeningReview': 'pending', 'bundled': false})}\n',
      flush: true,
    );
  }
}

Future<void> main(List<String> args) async {
  if (args.any((arg) => !['--execute'].contains(arg))) {
    stderr.writeln(
      'Usage: dart run tool/generate_ai_auditions.dart [--execute]',
    );
    exitCode = 1;
    return;
  }
  final plan = File('docs/audio/ai_audition_plan.json');
  await plan.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(auditionPlan())}\n',
  );
  if (!args.contains('--execute')) {
    stdout.writeln(
      'Plan only: 4 character auditions, 0 API calls, 0 generated audio files. See ${plan.path}.',
    );
    return;
  }
  // Execute only after the user authorizes paid generation. Read the key from
  // this shell's environment; never store it in the project or Android app.
  final key = Platform.environment['OPENAI_API_KEY'];
  if (key == null || key.trim().isEmpty) {
    stderr.writeln('OPENAI_API_KEY is not configured. No API call was made.');
    exitCode = 1;
    return;
  }
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  try {
    await renderAuditions(
      output: Directory('.tool_tmp/voice-auditions'),
      send: (body) async {
        final request = await client.postUrl(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
        );
        request.followRedirects = false;
        request.headers.contentType = ContentType.json;
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $key');
        request.write(jsonEncode(body));
        final response = await request.close().timeout(
          const Duration(seconds: 90),
        );
        if (response.statusCode != 200) {
          throw HttpException('Voice API returned HTTP ${response.statusCode}');
        }
        final bytes = <int>[];
        await for (final chunk in response.timeout(
          const Duration(seconds: 30),
        )) {
          bytes.addAll(chunk);
          if (bytes.length > 10000000) {
            throw const FormatException('Response exceeds size limit');
          }
        }
        return Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map);
      },
    );
    stdout.writeln(
      'Auditions staged in .tool_tmp/voice-auditions. Listen and check transcripts before bundling. No app assets were changed.',
    );
  } catch (_) {
    stderr.writeln(
      'Audition generation stopped. Existing staged files are preserved; no automatic retry. Check service access and account usage before retrying.',
    );
    exitCode = 1;
  } finally {
    client.close(force: true);
  }
}
