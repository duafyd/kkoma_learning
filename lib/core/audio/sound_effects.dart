import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sound_assets.dart';
export 'sound_assets.dart';

enum EffectPlayback { started, muted, cancelled, unavailable }

final effectsProvider = Provider<SoundEffects>((ref) {
  final service = SoundEffects();
  ref.onDispose(service.dispose);
  return service;
});

/// Short bundled sounds use Android SoundPool independently of speech volume.
class SoundEffects {
  static const channel = MethodChannel('kkoma/sound_effects');
  final DateTime Function() now;
  int _generation = 0;
  bool _disposed = false;
  bool _active = true;
  StorySound? _lastSound;
  DateTime? _lastStarted;
  String? lastError;
  SoundEffects({DateTime Function()? now}) : now = now ?? DateTime.now;

  Future<EffectPlayback> play(StorySound sound, double volume) async {
    if (_disposed || !_active) return EffectPlayback.cancelled;
    if (volume <= 0) {
      await stop();
      return EffectPlayback.muted;
    }
    final instant = now();
    if (_lastSound == sound &&
        _lastStarted != null &&
        instant.difference(_lastStarted!) < const Duration(milliseconds: 300)) {
      return EffectPlayback.cancelled;
    }
    _lastSound = sound;
    _lastStarted = instant;
    final generation = ++_generation;
    try {
      final started = await channel
          .invokeMethod<bool>('play', {
            'sound': sound.name,
            'volume': volume.clamp(0.0, 1.0),
          })
          .timeout(const Duration(seconds: 3));
      if (_disposed || generation != _generation) {
        return EffectPlayback.cancelled;
      }
      if (started != true) throw StateError('Effect playback did not start');
      lastError = null;
      return EffectPlayback.started;
    } catch (error) {
      if (_disposed || generation != _generation) {
        return EffectPlayback.cancelled;
      }
      lastError = error.toString();
      // Cancel a native pending load as well as any already playing stream.
      await stop();
      return EffectPlayback.unavailable;
    }
  }

  Future<void> stop() async {
    _generation++;
    _lastSound = null;
    _lastStarted = null;
    // Route changes/disposal only send cancellation; never wait on native audio.
    channel
        .invokeMethod<void>('stop')
        .then<void>((_) {}, onError: (Object _, StackTrace _) {});
  }

  void setActive(bool active) {
    _active = active;
    if (!active) stop();
  }

  void dispose() {
    _disposed = true;
    stop();
  }
}
