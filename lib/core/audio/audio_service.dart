import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../features/profile/domain/settings.dart';
import '../../features/profile/presentation/profile_vm.dart';
import 'recorded_voice.dart';

enum PlaybackResult { played, muted, unavailable, cancelled, failed }

enum VoiceSource { recording, tts }

enum AudioIssue { missingVoice, playbackFailed }

class AudioStatus {
  final AudioIssue? issue;
  final String? language;
  final String? diagnostic;
  const AudioStatus({this.issue, this.language, this.diagnostic});
  String? get message => switch (issue) {
    AudioIssue.missingVoice => '읽어 주는 소리가 준비되지 않았어요. 그림과 글자로 함께 해요.',
    AudioIssue.playbackFailed => '지금은 소리를 재생할 수 없어요. 그림과 글자로 계속할 수 있어요.',
    null => null,
  };
}

final audioStatusProvider = NotifierProvider<AudioStatusVM, AudioStatus>(
  AudioStatusVM.new,
);

class AudioStatusVM extends Notifier<AudioStatus> {
  @override
  AudioStatus build() => const AudioStatus();
  void report(AudioStatus next) {
    state = next;
  }

  void dismiss() {
    state = const AudioStatus();
  }
}

final audioProvider = Provider<AudioService>((ref) {
  final service = AudioService(
    onStatus: (status) => ref.read(audioStatusProvider.notifier).report(status),
  );
  ref.onDispose(service.dispose);
  ref.listen(settingsProvider, (previous, next) {
    if (next.asData?.value.voiceVolume == 0) service.stop();
  });
  return service;
});

class AudioService {
  static int _nextInstance = 0;
  final String _instance = 'voice-${++_nextInstance}';
  final FlutterTts _tts = FlutterTts();
  final RecordedVoice recordings;
  final void Function(AudioStatus)? onStatus;
  final Duration utteranceTimeout;
  final Duration recordingTimeout;
  int _generation = 0;
  bool _disposed = false;
  bool _active = true;
  String? _recordingToken;
  VoiceSource? lastSource;
  AudioStatus status = const AudioStatus();
  AudioService({
    this.onStatus,
    this.utteranceTimeout = const Duration(seconds: 30),
    this.recordingTimeout = const Duration(seconds: 65),
    RecordedVoice? recordings,
  }) : recordings = recordings ?? RecordedVoice();
  String? get lastError =>
      status.issue == null ? null : status.diagnostic ?? status.message;
  bool _current(int generation) => !_disposed && generation == _generation;
  void _report(int generation, AudioStatus next) {
    if (!_current(generation)) return;
    status = next;
    onStatus?.call(next);
  }

  Future<PlaybackResult> speak(
    String text,
    ParentSettings settings, {
    String language = 'ko-KR',
    String? recordingId,
  }) async {
    if (_disposed || !_active) return PlaybackResult.cancelled;
    final generation = ++_generation;
    final token = '$_instance-$generation';
    _recordingToken = token;
    lastSource = null;
    try {
      await recordings.stop().timeout(const Duration(seconds: 2));
      if (!_current(generation)) return PlaybackResult.cancelled;
      await _tts.stop().timeout(const Duration(seconds: 5));
      if (!_current(generation)) return PlaybackResult.cancelled;
      _report(generation, const AudioStatus());
      if (settings.voiceVolume == 0) return PlaybackResult.muted;
      VoiceClip? clip;
      try {
        clip = await recordings
            .find(text, language, id: recordingId)
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // A slow/unreadable index must not prevent offline TTS.
      }
      var repeatsLeft = settings.repeats;
      if (!_current(generation)) return PlaybackResult.cancelled;
      if (clip != null) {
        var completed = 0;
        for (var i = 0; i < settings.repeats; i++) {
          RecordingResult outcome;
          try {
            outcome = await recordings
                .play(clip, token, settings.voiceVolume)
                .timeout(recordingTimeout);
          } catch (_) {
            outcome = RecordingResult.failed;
          }
          if (!_current(generation)) return PlaybackResult.cancelled;
          if (outcome == RecordingResult.cancelled) {
            return PlaybackResult.cancelled;
          }
          if (outcome != RecordingResult.completed) break;
          completed++;
          repeatsLeft--;
        }
        if (completed == settings.repeats) {
          lastSource = VoiceSource.recording;
          _report(generation, const AudioStatus());
          return PlaybackResult.played;
        }
        // Stop the failed/timed-out player before TTS. Token prevents stopping a newer request.
        await recordings.stop(token: token).timeout(const Duration(seconds: 2));
        if (!_current(generation)) return PlaybackResult.cancelled;
      }
      final voices = await _tts.getVoices.timeout(const Duration(seconds: 5));
      if (!_current(generation)) return PlaybackResult.cancelled;
      String locale(Object? value) =>
          value.toString().replaceAll('_', '-').toLowerCase();
      final offline = voices is List
          ? voices
                .whereType<Map>()
                .where(
                  (v) =>
                      locale(v['locale']) == locale(language) &&
                      v['name'] is String &&
                      (v['network_required'] == false ||
                          v['network_required'] == 'false' ||
                          v['network_required'] == '0' ||
                          v['network_required'] == 0),
                )
                .toList()
          : <Map>[];
      if (offline.isEmpty) {
        _report(
          generation,
          AudioStatus(
            issue: AudioIssue.missingVoice,
            language: language,
            diagnostic:
                '오프라인 $language 음성이 없습니다. 보호자 영역에서 기기의 TTS 언어팩을 확인해 주세요.',
          ),
        );
        return PlaybackResult.unavailable;
      }
      final voice = offline.first;
      await _tts.setLanguage(language).timeout(const Duration(seconds: 5));
      if (!_current(generation)) return PlaybackResult.cancelled;
      await _tts
          .setVoice({
            'name': voice['name'] as String,
            'locale': voice['locale'] as String,
          })
          .timeout(const Duration(seconds: 5));
      if (!_current(generation)) return PlaybackResult.cancelled;
      await _tts
          .setVolume(settings.voiceVolume)
          .timeout(const Duration(seconds: 5));
      await _tts.setSpeechRate(.38).timeout(const Duration(seconds: 5));
      await _tts.awaitSpeakCompletion(true).timeout(const Duration(seconds: 5));
      for (var i = 0; i < repeatsLeft; i++) {
        if (!_current(generation)) return PlaybackResult.cancelled;
        final result = await _tts.speak(text).timeout(utteranceTimeout);
        if (!_current(generation)) return PlaybackResult.cancelled;
        if (result != 1) throw StateError('TTS speak returned $result');
      }
      _report(generation, const AudioStatus());
      lastSource = VoiceSource.tts;
      return PlaybackResult.played;
    } catch (e) {
      if (!_current(generation)) return PlaybackResult.cancelled;
      // A timed-out native utterance must not keep speaking after the UI falls back to text.
      _report(
        generation,
        AudioStatus(
          issue: AudioIssue.playbackFailed,
          language: language,
          diagnostic: e.toString(),
        ),
      );
      _stopRecording(token: token);
      try {
        await _tts.stop().timeout(const Duration(seconds: 2));
      } catch (_) {}
      return PlaybackResult.failed;
    }
  }

  Future<void> success(ParentSettings settings) async {
    if (settings.effectsVolume == 0 || _disposed) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  Future<void> stop() async {
    _generation++;
    _stopRecording();
    // Route changes only need to send stop, and must never wait on the engine.
    _tts.stop().then<void>((_) {}, onError: (Object _, StackTrace _) {});
  }

  void dispose() {
    _disposed = true;
    _generation++;
    _stopRecording(token: _recordingToken);
    // Disposal cannot await native playback. Avoid leaving a timeout timer behind.
    _tts.stop().then<void>((_) {}, onError: (Object _, StackTrace _) {});
  }

  void _stopRecording({String? token}) {
    recordings
        .stop(token: token)
        .then<void>((_) {}, onError: (Object _, StackTrace _) {});
  }

  void setActive(bool active) {
    _active = active;
    if (!active) stop();
  }
}
