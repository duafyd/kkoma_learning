import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/audio/audio_service.dart';
import 'package:flutter_application_1/core/audio/recorded_voice.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/core/storage/local_store.dart';
import 'package:flutter_application_1/features/learning/data/learning_content.dart';
import 'package:flutter_application_1/features/learning/presentation/learning_vm.dart';
import 'package:flutter_application_1/features/progress/data/progress_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');
  var available = false;
  setUp(() {
    available = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          RecordedVoice.nativeChannel,
          (call) async => null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getVoices') {
            return available
                ? [
                    {
                      'name': 'ko',
                      'locale': 'ko-KR',
                      'network_required': false,
                    },
                  ]
                : [];
          }
          return 1;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(RecordedVoice.nativeChannel, null);
  });
  test('unavailable speech records attempt; only audible retry completes listening', () async {
    final store = MemoryStore(),
        c = ProviderContainer(
          overrides: [storeProvider.overrideWithValue(store)],
        );
    addTearDown(c.dispose);
    final sub = c.listen(learningProvider('hangul'), (_, _) {});
    addTearDown(sub.close);
    await c.read(learningProvider('hangul').future);
    final vm = c.read(learningProvider('hangul').notifier),
        item = learningItems.first;
    await vm.listen(item);
    var saved = (await ProgressRepository(store).load())['listen-${item.id}'];
    expect(saved['attempts'], 1);
    expect(saved['completed'], false);
    available = true;
    await vm.listen(item);
    saved = (await ProgressRepository(store).load())['listen-${item.id}'];
    expect(saved['attempts'], 2);
    expect(saved['successes'], 1);
    expect(saved['completed'], true);
  });
  testWidgets(
    'missing speech shows dismissible notice and leaves learning usable',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(MemoryStore())],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const KkomaApp()),
      );
      await tester.pumpAndSettle();
      c.read(routerProvider).go('/learn/hangul');
      await tester.pumpAndSettle();
      // Asset I/O needs real async execution outside the widget test clock.
      await tester.runAsync(
        () => c.read(audioProvider).recordings.find('ㄱ', 'ko-KR'),
      );
      await tester.tap(find.byTooltip('ㄱ 읽어 주기'));
      await tester.pumpAndSettle();
      expect(find.text('읽어 주는 소리가 준비되지 않았어요. 그림과 글자로 함께 해요.'), findsOneWidget);
      await tester.tap(find.byTooltip('음성 안내 닫기'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('음성 안내 닫기'), findsNothing);
      await tester.tap(find.text('함께 찾기'));
      await tester.pumpAndSettle();
      expect(find.text('가방의 첫 글자를 찾아요'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
