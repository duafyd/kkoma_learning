// Original synthesized PCM16 mono effects. No downloads or recorded samples.
// Run: dart run tool/generate_story_sounds.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const rate = 22050;
void write(String name, List<double> samples) {
  final peak = samples.fold<double>(0, (p, v) => max(p, v.abs()));
  final scale = peak == 0 ? 1 : min(1, .35 / peak);
  final bytes = ByteData(44 + samples.length * 2);
  void tag(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      bytes.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  bytes.setUint32(4, bytes.lengthInBytes - 8, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, rate, Endian.little);
  bytes.setUint32(28, rate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  bytes.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    bytes.setInt16(
      44 + i * 2,
      (samples[i] * scale * 32767).round(),
      Endian.little,
    );
  }
  final target = File('assets/audio/effects/$name.wav');
  target.parent.createSync(recursive: true);
  target.writeAsBytesSync(bytes.buffer.asUint8List());
}

void bells(String name, List<(double, double)> notes, double duration) {
  write(
    name,
    List.generate((rate * duration).round(), (i) {
      final t = i / rate;
      var value = 0.0;
      for (final (start, frequency) in notes) {
        final age = t - start;
        if (age >= 0) {
          value +=
              .16 *
              min(1, age / .012) *
              exp(-age * 12) *
              (sin(2 * pi * frequency * age) +
                  .18 * sin(2 * pi * frequency * 2 * age));
        }
      }
      return value * min(1, (duration - t) / .04);
    }),
  );
}

void main() {
  final random = Random(2205);
  var noise = 0.0;
  write(
    'pageTurn',
    List.generate((rate * .28).round(), (i) {
      noise = noise * .65 + (random.nextDouble() * 2 - 1) * .35;
      return noise * pow(sin(pi * i / rate / .28), 2) * .45;
    }),
  );
  bells('friend', [(0, 523.25), (.10, 659.25)], .36);
  bells('sparkle', [
    (0, 523.25),
    (.12, 659.25),
    (.24, 783.99),
    (.36, 1046.5),
  ], .66);
  stdout.writeln('Generated 3 original effects in assets/audio/effects');
}
