import 'dart:convert';

import 'package:flutter/services.dart';

enum RecordingResult { completed, missing, failed, cancelled }

class VoiceClip {
  final String id, text, language;
  final int bytes;
  const VoiceClip(this.id, this.text, this.language, this.bytes);
}

/// Exact transcript/locale matching avoids using stale or unrelated recordings.
class RecordedVoice {
  static const indexAsset = 'assets/audio/recordings.json';
  static const nativeChannel = MethodChannel('kkoma/recorded_voice');
  final AssetBundle bundle;
  final MethodChannel channel;
  Future<List<VoiceClip>>? _index;
  List<VoiceClip>? _clips;
  String? lastError;
  RecordedVoice({AssetBundle? bundle, this.channel = nativeChannel})
    : bundle = bundle ?? rootBundle;

  Future<List<VoiceClip>> _load() async {
    try {
      final value = jsonDecode(await bundle.loadString(indexAsset));
      if (value is! Map || value['version'] != 1 || value['clips'] is! List) {
        throw const FormatException('unsupported voice index');
      }
      final clips = <VoiceClip>[], ids = <String>{};
      for (final entry in value['clips'] as List) {
        if (entry is! Map ||
            entry['id'] is! String ||
            entry['text'] is! String ||
            !['ko-KR', 'en-US'].contains(entry['language']) ||
            entry['bytes'] is! int) {
          throw const FormatException('invalid voice entry');
        }
        final id = entry['id'] as String,
            text = entry['text'] as String,
            bytes = entry['bytes'] as int;
        if (!id.startsWith('voice-') ||
            id.contains(RegExp(r'[/\\:*?"<>|]')) ||
            text.trim().isEmpty ||
            bytes < 44 ||
            bytes > 6000000 ||
            !ids.add(id)) {
          throw const FormatException('unsafe or duplicate voice entry');
        }
        clips.add(VoiceClip(id, text, entry['language'] as String, bytes));
      }
      return _clips = clips;
    } catch (error) {
      lastError = error.toString();
      return _clips = const [];
    }
  }

  Future<VoiceClip?> find(String text, String language, {String? id}) async {
    if (_clips == null) await (_index ??= _load());
    return _clips!
        .where(
          (c) =>
              c.text == text &&
              c.language == language &&
              (id == null || c.id == id),
        )
        .firstOrNull;
  }

  Future<RecordingResult> play(
    VoiceClip clip,
    String token,
    double volume,
  ) async {
    try {
      final outcome = await channel.invokeMethod<String>('play', {
        'id': clip.id,
        'bytes': clip.bytes,
        'token': token,
        'volume': volume.clamp(0.0, 1.0),
      });
      return switch (outcome) {
        'completed' => RecordingResult.completed,
        'cancelled' => RecordingResult.cancelled,
        'missing' => RecordingResult.missing,
        _ => RecordingResult.failed,
      };
    } catch (error) {
      lastError = error.toString();
      return RecordingResult.failed;
    }
  }

  Future<void> stop({String? token}) async {
    try {
      await channel.invokeMethod<void>(
        'stop',
        token == null ? null : {'token': token},
      );
    } on MissingPluginException {
      // Unsupported host/platform: no native recording can be playing.
    }
  }
}
