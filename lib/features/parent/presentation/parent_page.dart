import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/activity_scaffold.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/sound_effects.dart';
import '../../profile/presentation/profile_vm.dart';
import '../domain/parent_gate.dart';
import 'progress_controls.dart';

class ParentPage extends ConsumerStatefulWidget {
  const ParentPage({super.key});
  @override
  ConsumerState<ParentPage> createState() => _ParentPageState();
}

class _ParentPageState extends ConsumerState<ParentPage> {
  final gate = ParentGate();
  final answer = TextEditingController();
  bool unlocked = false;
  String? error;
  @override
  void dispose() {
    answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    if (!unlocked) {
      return ActivityScaffold(
        title: '보호자 확인',
        child: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 64),
                  const Text('보호자가 계산하고 입력해 주세요.'),
                  Text(
                    gate.prompt,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  TextField(
                    controller: answer,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '답',
                      errorText: error,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => setState(() {
                      unlocked = gate.accepts(answer.text);
                      error = unlocked ? null : '다시 계산해 주세요.';
                    }),
                    child: const Text('설정 열기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return ActivityScaffold(
      title: '보호자 설정',
      child: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('설정을 읽지 못했어요: $e'),
        data: (s) => ListView(
          children: [
            const Text('설정은 이 기기에만 저장됩니다. 이름·사진·음성을 수집하지 않습니다.'),
            _dropdown('만 나이', s.age, [2, 3, 4, 5], (n) => _change('age', n)),
            _dropdown('학습 경로', s.level, [
              2,
              3,
              4,
              5,
            ], (n) => _change('level', n)),
            _dropdown('하루 사용 시간 (분)', s.minutes, [
              5,
              10,
              15,
              20,
              30,
              45,
              60,
              120,
            ], (n) => _change('minutes', n)),
            _dropdown('도움 통과까지 시도 횟수', s.helpAfter, [
              1,
              2,
              3,
              4,
              5,
            ], (n) => _change('helpAfter', n)),
            _dropdown('읽기 반복 횟수', s.repeats, [
              1,
              2,
              3,
            ], (n) => _change('repeats', n)),
            SwitchListTile(
              title: const Text('자동 읽기'),
              value: s.autoRead,
              onChanged: (v) => _change('autoRead', v),
            ),
            SwitchListTile(
              title: const Text('도움 통과 허용'),
              subtitle: const Text('끄더라도 쉬운 문제와 시범으로 함께 진행할 수 있어요.'),
              value: s.help,
              onChanged: (v) => _change('help', v),
            ),
            SwitchListTile(
              title: const Text('애니메이션'),
              value: s.animations,
              onChanged: (v) => _change('animations', v),
            ),
            const Text('음성 음량'),
            Slider(
              value: s.voiceVolume,
              onChanged: (v) => _change('voiceVolume', v),
            ),
            const Text('이야기 효과음 · 학습 진동 (0이면 끔)'),
            Slider(
              value: s.effectsVolume,
              onChanged: (v) {
                if (v == 0) ref.read(effectsProvider).stop();
                _change('effectsVolume', v);
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.music_note_rounded),
              label: const Text('이야기 효과음 들어 보기'),
              onPressed: () async {
                final result = await ref
                    .read(effectsProvider)
                    .play(StorySound.sparkle, s.effectsVolume);
                if (!context.mounted) return;
                if (result == EffectPlayback.unavailable ||
                    result == EffectPlayback.muted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result == EffectPlayback.muted
                            ? '효과음 음량이 꺼져 있어요.'
                            : '효과음을 재생하지 못했어요. 기기의 미디어 음량을 확인해 주세요.',
                      ),
                    ),
                  );
                }
              },
            ),
            const Text('배경음악은 현재 제공하지 않습니다. 녹음 음원 대신 기기의 TTS를 사용합니다.'),
            if (ref.watch(audioStatusProvider).issue != null) ...[
              const SizedBox(height: 12),
              const Text('음성 확인: 기기 설정에서 한국어·영어 TTS 오프라인 언어팩을 확인해 주세요.'),
              Text(
                '최근 음성 상태 (${ref.watch(audioStatusProvider).language ?? '언어 미확인'}): ${ref.watch(audioStatusProvider).diagnostic ?? '재생 불가'}',
              ),
            ],
            const ProgressControls(),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                if (await confirmAction(
                  context,
                  '앱을 종료할까요? 저장된 진도와 작품은 유지돼요.',
                )) {
                  await SystemNavigator.pop();
                }
              },
              icon: const Icon(Icons.exit_to_app),
              label: const Text('앱 종료'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _change(String key, Object value) async {
    try {
      await ref.read(settingsProvider.notifier).change(key, value);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설정을 저장하지 못했어요. 저장 공간을 확인해 주세요.')),
        );
      }
    }
  }

  Widget _dropdown(
    String label,
    int value,
    List<int> values,
    ValueChanged<int> onChanged,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: values
          .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
          .toList(),
      onChanged: (n) {
        if (n != null) onChanged(n);
      },
    ),
  );
}
