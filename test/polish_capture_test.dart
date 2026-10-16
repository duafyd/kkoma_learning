import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/drawing/domain/drawing.dart';
import 'package:flutter_application_1/features/drawing/presentation/drawing_vm.dart';
import 'package:flutter_application_1/features/math/presentation/counting_vm.dart';
import 'package:flutter_application_1/features/math/presentation/sorting_vm.dart';
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/story/data/story_art.dart';
import 'package:flutter_application_1/features/story/data/story_repository.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/tracing/domain/trace_engine.dart';

const _picture = DrawingDocument(
  background: 0xffe6f1d8,
  lines: [
    DrawingLine([TracePoint(.35, .4)], color: 0xffe76f51, stamp: 'flower'),
    DrawingLine([TracePoint(.65, .3)], color: 0xff8648a6, stamp: 'butterfly'),
    DrawingLine([TracePoint(.35, .46), TracePoint(.35, .7)], width: .014),
    DrawingLine([
      TracePoint(.2, .8),
      TracePoint(.4, .7),
      TracePoint(.7, .8),
    ], width: .018),
  ],
);

class _Gallery extends GalleryVM {
  @override
  Future<List<Artwork>> build() async => [
    Artwork(
      id: 'garden',
      path: 'missing.png',
      created: DateTime(2026, 10, 16),
      document: _picture,
    ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const capture = bool.fromEnvironment('POLISH_CAPTURE');
  setUpAll(() async {
    if (!capture) return;
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
    for (final (name, path) in [
      ('Roboto', 'C:/Windows/Fonts/malgun.ttf'),
      (
        'MaterialIcons',
        'C:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
    ]) {
      final file = File(path);
      if (file.existsSync()) {
        await (FontLoader(name)..addFont(
              Future.value(ByteData.sublistView(file.readAsBytesSync())),
            ))
            .load();
      }
    }
  });
  for (final (label, size) in [
    ('tablet', const Size(1280, 800)),
    ('phone', const Size(360, 780)),
    ('landscape', const Size(780, 360)),
  ]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('polished app routes stay usable on $label at $scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final store = MemoryStore();
        await ProfileRepository(store).save(
          const ParentSettings(
            age: 5,
            level: 5,
            autoRead: false,
            animations: false,
            voiceVolume: 0,
            effectsVolume: 0,
          ),
        );
        await StoryRepository(store).save(
          const StorySnapshot(
            episode: 10,
            level: 5,
            completed: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
          ),
        );
        await store.write('drawing-draft', _picture.toJson());
        final c = ProviderContainer(
          overrides: [
            storeProvider.overrideWithValue(store),
            galleryProvider.overrideWith(_Gallery.new),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: RepaintBoundary(
              key: const ValueKey('polish-screen'),
              child: const KkomaApp(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (capture) {
          await tester.runAsync(() async {
            final context = tester.element(find.byType(MaterialApp));
            for (final asset in storyArtAssets.values.toSet()) {
              await precacheImage(
                ResizeImage(AssetImage(asset), width: 400),
                context,
              );
            }
            for (final asset in [
              storyCastAsset,
              storySearchCastAsset,
              storyMotionCastAsset,
            ]) {
              await precacheImage(
                ResizeImage(AssetImage(asset), width: 1024),
                context,
              );
            }
            await precacheImage(
              ResizeImage(
                AssetImage(storyArtAssets['ep11-empty']!),
                width: 1536,
              ),
              context,
            );
          });
          await tester.pumpAndSettle();
        }
        Future<void> photo(String name) async {
          expect(tester.takeException(), isNull, reason: '$label $scale $name');
          if (!capture) return;
          await tester.runAsync(() async {
            final image = await tester
                .renderObject<RenderRepaintBoundary>(
                  find.byKey(const ValueKey('polish-screen')),
                )
                .toImage();
            try {
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File('docs/screenshots/polish-$name-$label-$scale.png')
                  .writeAsBytes(data!.buffer.asUint8List());
            } finally {
              image.dispose();
            }
          });
        }

        await photo('home');
        for (final (name, path) in [
          ('prewriting', '/prewriting'),
          ('dot', '/trace/p-dot'),
          ('curve', '/trace/e-e'),
          ('drawing', '/drawing'),
          ('counting', '/math/play'),
          ('connection', '/math/match'),
          ('gallery', '/gallery'),
        ]) {
          c.read(routerProvider).go(path);
          await tester.pumpAndSettle();
          if (name == 'counting') {
            final vm = c.read(countingProvider(5).notifier);
            vm.add();
            vm.add();
            vm.remove();
            await tester.pumpAndSettle();
          }
          if (name == 'connection') {
            final button = find.text('선으로 잇기');
            await tester.ensureVisible(button);
            await tester.pumpAndSettle();
            await tester.tap(button);
            await tester.pumpAndSettle();
            final vm = c.read(sortingProvider(5).notifier),
                s = c.read(sortingProvider(5)).requireValue;
            final r = vm.rules.activity(s);
            await vm.place(0, r.targets.indexOf(r.pieces[0]));
            await tester.pumpAndSettle();
            await tester.ensureVisible(
              find.byKey(const ValueKey('connection-piece-0')),
            );
            await tester.pumpAndSettle();
          }
          await photo(name);
          if (name == 'gallery') {
            final art = find.byKey(const ValueKey('artwork-preview-garden'));
            await tester.scrollUntilVisible(
              art,
              400,
              scrollable: find.byType(Scrollable).first,
              maxScrolls: 30,
            );
            await tester.pumpAndSettle();
            await photo('exhibition');
          }
        }
        await tester.pumpWidget(const SizedBox.shrink());
        c.dispose();
      });
    }
  }
}
