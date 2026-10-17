import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/audio/audio_service.dart';
import '../../profile/domain/settings.dart';
import '../../profile/presentation/profile_vm.dart';
import '../../tracing/domain/trace_engine.dart';
import '../../drawing/data/drawing_repository.dart';
import '../../drawing/presentation/drawing_vm.dart';
import '../../drawing/domain/drawing.dart';
import '../data/story_repository.dart';
import '../domain/story_models.dart';
import '../domain/story_machine.dart';

final storyRepositoryProvider = Provider(
  (ref) => StoryRepository(ref.watch(storeProvider)),
);
final storyProvider = AsyncNotifierProvider<StoryVM, StorySnapshot>(
  StoryVM.new,
);

/// Resolve the saved map by identity, never by "latest artwork" or draft.
final storyGardenMapProvider = Provider<AsyncValue<Artwork?>>((ref) {
  final id = ref.watch(storyProvider).asData?.value.flags['gardenArtwork'];
  if (id == null) return const AsyncData(null);
  return ref.watch(galleryProvider).whenData((artworks) {
    for (final artwork in artworks) {
      if (artwork.id == id) return artwork;
    }
    return null; // It may have been removed in the parent gallery.
  });
});

class StoryVM extends AsyncNotifier<StorySnapshot> {
  final machine = StoryMachine();
  bool busy = false;
  @override
  Future<StorySnapshot> build() async {
    final settings = await ref.watch(settingsProvider.future);
    var saved = await ref.read(storyRepositoryProvider).load();
    saved = saved == null ? null : machine.restore(saved);
    if (saved?.pendingDrawing != null &&
        saved!.phase == StoryPhase.drawing &&
        machine.scene(saved).interaction == StoryPhase.drawing) {
      saved = await _finishDrawing(saved);
    }
    return saved == null
        ? machine.begin(settings.level)
        : machine.relevel(machine.restore(saved), settings.level);
  }

  Future<void> _transition(StorySnapshot Function(StorySnapshot) change) async {
    if (busy || !state.hasValue || state.requireValue.pendingDrawing != null) {
      return;
    }
    busy = true;
    try {
      final next = change(state.requireValue);
      await ref.read(storyRepositoryProvider).save(next);
      state = AsyncData(next);
    } finally {
      busy = false;
    }
  }

  Future<void> advance() => _transition(machine.advance);
  Future<void> collectFragment() => _transition(machine.collectFragment);
  Future<void> discoverSceneProp(int i) =>
      _transition((s) => machine.discoverSceneProp(s, i));
  Future<void> choose(int i) => _transition((s) => machine.choose(s, i));
  Future<void> answer(int i) => _transition((s) => machine.answer(s, i));
  Future<void> hint() => _transition(machine.hint);
  Future<void> easier() => _transition(machine.easier);
  Future<void> originalMission() => _transition(machine.originalMission);
  Future<void> assist() => _transition(
    (s) => machine.assist(
      s,
      ref.read(settingsProvider).value ?? const ParentSettings(),
    ),
  );
  Future<void> trace(List<TracePoint> points) =>
      _transition((s) => machine.trace(s, points));
  Future<void> saveGardenDrawing() async {
    if (busy || state.asData?.value.phase != StoryPhase.drawing) return;
    busy = true;
    try {
      var submitted = state.requireValue;
      if (submitted.pendingDrawing == null) {
        final document = (await ref.read(storyDrawingProvider.future)).current;
        if (document.lines.isEmpty) return;
        final repository = ref.read(storyRepositoryProvider);
        final artwork = await ref
            .read(drawingRepositoryProvider)
            .prepare(document);
        final pending = submitted.change({'pendingDrawing': artwork.toJson()});
        if (!await repository.replaceIfCurrent(submitted, pending)) {
          if (ref.mounted) ref.invalidateSelf();
          return;
        }
        submitted = pending;
        if (ref.mounted) state = AsyncData(pending);
      }
      final next = await _finishDrawing(submitted);
      if (ref.mounted) state = AsyncData(next);
    } finally {
      busy = false;
    }
  }

  Future<StorySnapshot> _finishDrawing(StorySnapshot submitted) async {
    final repository = ref.read(storyRepositoryProvider);
    final drawing = ref.read(drawingRepositoryProvider);
    final level = submitted.level;
    // A second VM or a parent reset may have superseded this pending save.
    final current = await repository.load();
    if (current?.pendingDrawing?.id != submitted.pendingDrawing!.id) {
      return current == null ? machine.begin(level) : machine.restore(current);
    }
    await drawing.savePrepared(submitted.pendingDrawing!);
    if (ref.mounted) ref.invalidate(galleryProvider);
    final next = machine.drawingComplete(submitted).change({
      'pendingDrawing': null,
      'flags': {
        ...submitted.flags,
        'gardenArtwork': submitted.pendingDrawing!.id,
      },
    });
    if (await repository.replaceIfCurrent(submitted, next)) return next;
    final latest = await repository.load();
    return latest == null ? machine.begin(level) : machine.restore(latest);
  }

  Future<void> resetStrokes() => _transition((s) => s.change({'strokes': []}));
  Future<void> observeObject(int index) =>
      _transition((s) => machine.observeObject(s, index));
  Future<void> placeObject(int piece, int slot) =>
      _transition((s) => machine.placeObject(s, piece, slot));
  Future<PlaybackResult> listenTo(int index) async {
    final current = state.asData?.value;
    if (current == null) return PlaybackResult.cancelled;
    final samples = machine.speeches(current);
    if (index < 0 || index >= samples.length) return PlaybackResult.cancelled;
    final sample = samples[index];
    return ref
        .read(audioProvider)
        .speak(
          sample.text,
          ref.read(settingsProvider).value ?? const ParentSettings(),
          language: sample.language,
          recordingId: 'voice-story-${sample.id}',
        );
  }
}
