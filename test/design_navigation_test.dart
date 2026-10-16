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
import 'package:flutter_application_1/features/profile/data/profile_repository.dart';
import 'package:flutter_application_1/features/profile/domain/settings.dart';
import 'package:flutter_application_1/features/learning/presentation/learning_card.dart';
import 'package:flutter_application_1/features/story/domain/story_models.dart';
import 'package:flutter_application_1/features/story/presentation/story_vm.dart';
import 'package:flutter_application_1/features/story/presentation/story_illustration.dart';
import 'package:flutter_application_1/features/story/data/story_art.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const capture = bool.fromEnvironment('DESIGN_CAPTURE');
  setUpAll(() async {
    if (!capture) return;
    await (FontLoader(
      'Jua',
    )..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'))).load();
    for (final (name, path) in [
      ('Roboto', 'C:/Windows/Fonts/malgun.ttf'),
      ('Segoe UI Emoji', 'C:/Windows/Fonts/seguiemj.ttf'),
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
  for (final (name, size) in [
    ('tablet', const Size(1280, 800)),
    ('phone', const Size(360, 780)),
    ('landscape', const Size(780, 360)),
  ]) {
    testWidgets(
      'storybook shelf routes, learning actions and story remain usable on $name',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
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
        final c = ProviderContainer(
          overrides: [storeProvider.overrideWithValue(store)],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: RepaintBoundary(
              key: const ValueKey('design-screen'),
              child: const KkomaApp(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (capture) {
          await tester.runAsync(() async {
            final context = tester.element(find.byType(MaterialApp));
            for (final background in [
              'library',
              'ep2-gate',
              'ep5-dark',
              'ep6-bridge',
              'ep7-color',
              'ep1-quiet',
            ]) {
              for (final width in [520, 1536]) {
                await precacheImage(
                  ResizeImage(
                    AssetImage(StoryIllustration.assetFor(background)),
                    width: width,
                  ),
                  context,
                );
              }
            }
            await precacheImage(
              const ResizeImage(AssetImage(storyCastAsset), width: 1024),
              context,
            );
            await precacheImage(
              const ResizeImage(AssetImage(storySearchCastAsset), width: 1024),
              context,
            );
          });
          await tester.pumpAndSettle();
        }
        Future<void> bring(Finder target) async {
          if (target.evaluate().isEmpty) {
            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, 2000),
            );
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              target,
              200,
              scrollable: find.byType(Scrollable).first,
            );
          }
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
        }

        Future<void> photograph(String page) async {
          if (!capture) return;
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('design-screen')),
            );
            final image = await boundary.toImage();
            try {
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File('docs/screenshots/design-$page-$name.png')
                  .writeAsBytes(bytes!.buffer.asUint8List());
            } finally {
              image.dispose();
            }
          });
        }

        await photograph('home');
        expect(find.textContaining('이 기기에 저장'), findsNothing);
        await bring(find.text('한글 놀이터'));
        await tester.tap(find.text('한글 놀이터'));
        await tester.pumpAndSettle();
        expect(find.byType(LearningCard), findsWidgets);
        await photograph('hangul');
        await tester.tap(find.byTooltip('ㄱ 읽어 주기'));
        await tester.pumpAndSettle();
        final trace = find.descendant(
          of: find.byType(LearningCard).first,
          matching: find.text('따라 그리기'),
        );
        await bring(trace);
        await tester.tap(trace);
        await tester.pumpAndSettle();
        expect(find.text('ㄱ 따라 그리기'), findsOneWidget);
        await tester.tap(find.byTooltip('집으로'));
        await tester.pumpAndSettle();
        for (final (label, path) in [
          ('English Garden', '/learn/english'),
          ('숫자 탐험대', '/learn/math'),
          ('자유 그림방', '/drawing'),
          ('내 작품 · 모험 지도', '/gallery'),
        ]) {
          await bring(find.text(label));
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
          expect(
            c.read(routerProvider).routeInformationProvider.value.uri.path,
            path,
          );
          expect(tester.takeException(), isNull, reason: label);
          await tester.tap(find.byTooltip('집으로'));
          await tester.pumpAndSettle();
        }
        await bring(find.text('별빛 이야기 펼치기'));
        await tester.tap(find.text('별빛 이야기 펼치기'));
        await tester.pumpAndSettle();
        await photograph('story');
        final before = c.read(storyProvider).requireValue;
        final advance = find.text('다음 장면');
        await bring(advance);
        await photograph('story-dialogue');
        await tester.tap(advance);
        await tester.pumpAndSettle();
        final after = c.read(storyProvider).requireValue;
        expect(after.toJson(), isNot(before.toJson()));
        expect(after.phase, isNot(StoryPhase.finished));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        c.dispose();
      },
    );
  }
}
