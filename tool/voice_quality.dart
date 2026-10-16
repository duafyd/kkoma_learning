import 'dart:math' as math;
import 'dart:typed_data';

import 'voice_catalog.dart';

/// Objective PCM checks only. RMS is not LUFS, and none of these measurements
/// establishes acting quality, correct pronunciation or child suitability.
Map<String, dynamic> inspectVoicePcm(Uint8List bytes) {
  final error = validateVoiceWav(bytes);
  if (error != null) {
    return {
      'formatError': error,
      'warnings': ['invalid-format'],
      'listeningReview': 'pending',
    };
  }
  final data = ByteData.sublistView(bytes);
  var rate = 16000;
  final samples = <int>[];
  for (var offset = 12; offset + 8 <= bytes.length;) {
    final length = data.getUint32(offset + 4, Endian.little);
    final tag = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    if (tag == 'fmt ') rate = data.getUint32(offset + 12, Endian.little);
    if (tag == 'data') {
      for (var i = offset + 8; i < offset + 8 + length; i += 2) {
        samples.add(data.getInt16(i, Endian.little));
      }
    }
    offset += 8 + length + length % 2;
  }
  var peak = 0, squares = 0.0, clipped = 0;
  var first = -1, last = -1;
  for (var i = 0; i < samples.length; i++) {
    final value = samples[i].abs();
    peak = math.max(peak, value);
    squares += value * value;
    if (value >= 32760) clipped++;
    if (value >= 104) {
      // Approximately -50 dBFS: silence estimate, not speech detection.
      if (first == -1) first = i;
      last = i;
    }
  }
  double? db(double value) =>
      value == 0 ? null : 20 * math.log(value / 32768) / math.ln10;
  final rms = db(math.sqrt(squares / samples.length));
  final leading = (first < 0 ? samples.length : first) / rate;
  final trailing =
      (last < 0 ? samples.length : samples.length - last - 1) / rate;
  final warnings = <String>[
    if (peak == 0) 'digital-silence',
    if (first == -1 && peak > 0) 'below-audible-reference',
    if (clipped / samples.length >= .001) 'possible-clipping',
    if (peak >= 29205) 'peak-headroom-below-1dB',
    if (rms != null && rms < -30) 'low-rms-level',
    if (rms != null && rms > -12) 'high-rms-level',
    if (leading > .8) 'long-leading-silence',
    if (trailing > 1) 'long-trailing-silence',
  ];
  return {
    'formatError': null,
    'durationSeconds': samples.length / rate,
    'samplePeakDbfs': db(peak.toDouble()),
    'rmsDbfs': rms,
    'leadingSilenceSeconds': leading,
    'trailingSilenceSeconds': trailing,
    'clippedSampleFraction': clipped / samples.length,
    'warnings': warnings,
    'listeningReview': 'pending',
  };
}
