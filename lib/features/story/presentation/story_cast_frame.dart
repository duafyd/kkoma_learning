import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/story_art.dart';

enum CastPose { idle, open, stepA, stepB }

/// The generated atlas has unequal row gutters; explicit source bounds preserve
/// feet/wings instead of assuming a regular grid. Columns are quarter-width.
Rect castFrameRect(Size image, String character, CastPose pose) {
  final row = storyCharacterCells[character] ?? 2;
  const boundaries = [0.0, .285, .535, .792, 1.0];
  return Rect.fromLTRB(
    pose.index * image.width / 4,
    boundaries[row] * image.height,
    (pose.index + 1) * image.width / 4,
    boundaries[row + 1] * image.height,
  );
}

class StoryCastFrame extends StatefulWidget {
  final String character;
  final CastPose pose;
  final double edge;
  const StoryCastFrame({
    super.key,
    required this.character,
    required this.pose,
    required this.edge,
  });
  @override
  State<StoryCastFrame> createState() => _StoryCastFrameState();
}

class _StoryCastFrameState extends State<StoryCastFrame> {
  ImageStream? stream;
  ImageInfo? info;
  bool failed = false;
  late final listener = ImageStreamListener(
    (next, _) {
      if (!mounted) {
        next.dispose();
        return;
      }
      setState(() {
        info?.dispose();
        info = next;
        failed = false;
      });
    },
    onError: (Object _, StackTrace? _) {
      if (mounted) setState(() => failed = true);
    },
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = const ResizeImage(
      AssetImage(storyMotionCastAsset),
      width: 1024,
    ).resolve(createLocalImageConfiguration(context));
    if (next.key != stream?.key) {
      stream?.removeListener(listener);
      stream = next;
      stream!.addListener(listener);
    }
  }

  @override
  void dispose() {
    stream?.removeListener(listener);
    info?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.edge,
    child: failed
        ? const Icon(Icons.auto_awesome_rounded)
        : info == null
        ? null
        : CustomPaint(
            painter: _CastPainter(info!.image, widget.character, widget.pose),
          ),
  );
}

class _CastPainter extends CustomPainter {
  final ui.Image image;
  final String character;
  final CastPose pose;
  _CastPainter(this.image, this.character, this.pose);
  @override
  void paint(Canvas c, Size size) {
    final source = castFrameRect(
      Size(image.width.toDouble(), image.height.toDouble()),
      character,
      pose,
    );
    final fitted = applyBoxFit(BoxFit.contain, source.size, size);
    c.drawImageRect(
      image,
      source,
      Alignment.bottomCenter.inscribe(fitted.destination, Offset.zero & size),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _CastPainter old) =>
      old.image != image || old.character != character || old.pose != pose;
}
