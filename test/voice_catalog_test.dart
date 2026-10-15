import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/learning/domain/learning_speech.dart';
import 'package:flutter_application_1/features/learning/presentation/learning_vm.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/story/data/story_content.dart';

import '../tool/voice_catalog.dart';

Uint8List _wav() {
  final bytes = Uint8List(44 + 32000), data = ByteData(44 + 32000);
  void tag(int offset, String value) {
    for (var i = 0; i < 4; i++) {
      data.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  data.setUint32(4, bytes.length - 8, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, 16000, Endian.little);
  data.setUint32(28, 32000, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  data.setUint32(40, 32000, Endian.little);
  data.setInt16(44, 123, Endian.little);
  bytes.setAll(0, data.buffer.asUint8List());
  return bytes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('scripts cover each letter, scene age/success variant, and all nine route questions', () {
    final lines = buildVoiceCatalog(),
        byId = {for (final l in buildVoiceCatalog()) l.id: l};
    expect(byId.length, lines.length);
    for (final item in learningItems) {
      expect(byId['voice-${item.id}']!.language, item.language);
      expect(byId['voice-${item.id}-name']!.text, learningLetterName(item));
    }
    for (final scene in storyEpisodes.expand((e) => e.scenes)) {
      expect(byId['voice-${scene.id}']!.text, scene.text);
      if (scene.exploreText != null) {
        expect(byId['voice-${scene.id}-explore']!.text, scene.exploreText);
      }
      if (scene.successText.isNotEmpty) {
        expect(byId['voice-${scene.id}-success']!.text, scene.successText);
      }
      for (final variant in scene.quizVariants.entries) {
        final line = byId['voice-quiz-${variant.value.id}']!;
        expect(
          line.contexts,
          contains('story:${scene.id}:${scene.variationFlag}=${variant.key}'),
        );
        expect(line.language, 'ko-KR');
      }
    }
    expect(lines.where((l) => l.category == 'story-dialogue').length, 120);
    expect(
      lines.every((l) => l.text.trim().isNotEmpty && l.contexts.isNotEmpty),
      true,
    );
  });
  test('English letter names and target vowel remain distinct from full words with review notes', () {
    final lines = {for (final line in buildVoiceCatalog()) line.id: line};
    expect(lines['voice-story-letter-a-name']!.text, 'A');
    expect(lines['voice-story-letter-a-name']!.language, 'en-US');
    expect(lines['voice-story-word-apple']!.text, 'Apple');
    expect(lines['voice-story-vowel-o-sound']!.text, '오');
    expect(lines['voice-story-vowel-o-sound']!.language, 'ko-KR');
    expect(
      lines['voice-e-X']!.review.any((note) => note.contains('끝소리')),
      true,
    );
    expect(lines['voice-count-2']!.review.single, contains('두 개'));
  });
  test('lowercase listening and tracing use uppercase letter-name utterances without changing symbols', () {
    for (final symbol in ['a', 'i', 'x']) {
      final item = learningItems.firstWhere((i) => i.id == 'e-$symbol');
      expect(learningLetterName(item), symbol.toUpperCase());
      expect(
        learningListeningText(item),
        startsWith('${symbol.toUpperCase()}. '),
      );
      expect(item.symbol, symbol);
    }
  });
  test(
    'learning VM sends A name and Apple word in English for lowercase a',
    () async {
      const channel = MethodChannel('flutter_tts');
      final spoken = <String>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getVoices') {
          return [
            {'name': 'local-en', 'locale': 'en-US', 'network_required': '0'},
          ];
        }
        if (call.method == 'speak') {
          spoken.add(
            call.arguments is Map
                ? (call.arguments as Map)['text'] as String
                : call.arguments as String,
          );
        }
        return 1;
      });
      final store = MemoryStore();
      await ProfileRepository(store)
          .save(const ParentSettings(age: 5, level: 5, repeats: 1));
      final c = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(store)],
      );
      try {
        await c.read(learningProvider('english').future);
        await c
            .read(learningProvider('english').notifier)
            .listen(learningItems.firstWhere((i) => i.id == 'e-a'));
        expect(spoken, ['A. Apple.']);
      } finally {
        c.dispose();
        messenger.setMockMethodCallHandler(channel, null);
      }
    },
  );
  test('WAV format accepts complete mono PCM16 and rejects truncated chunks and inconsistent rates', () {
    expect(validateVoiceWav(_wav()), isNull);
    expect(validateVoiceWav(Uint8List(10)), isNotNull);
    var bad = _wav()..[0] = 0;
    expect(validateVoiceWav(bad), isNotNull);
    bad = _wav();
    ByteData.sublistView(bad).setUint32(40, bad.length, Endian.little);
    expect(validateVoiceWav(bad), contains('truncated'));
    bad = _wav();
    ByteData.sublistView(bad).setUint32(28, 1, Endian.little);
    expect(validateVoiceWav(bad), contains('rate mismatch'));
    bad = Uint8List.fromList([..._wav(), 0]);
    ByteData.sublistView(bad).setUint32(4, bad.length - 8, Endian.little);
    expect(validateVoiceWav(bad), contains('truncated'));
  });
  test(
    'WAV production rules reject stereo, compressed and empty speech files',
    () {
      for (final (offset, value) in [(20, 3), (22, 2), (34, 8)]) {
        final bad = _wav();
        ByteData.sublistView(bad).setUint16(offset, value, Endian.little);
        expect(validateVoiceWav(bad), isNotNull);
      }
      final empty = _wav().sublist(0, 44), data = ByteData.sublistView(empty);
      data.setUint32(4, 36, Endian.little);
      data.setUint32(40, 0, Endian.little);
      expect(validateVoiceWav(empty), contains('missing'));
    },
  );
}
