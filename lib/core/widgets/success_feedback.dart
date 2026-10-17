import 'package:flutter/material.dart';

/// Persistent visual confirmation; a short entrance plays only for a new save.
class SuccessFeedback extends StatelessWidget {
  final String title, message;
  final bool animate;
  const SuccessFeedback({
    super.key,
    this.title = '맞았어요!',
    required this.message,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: '$title $message',
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: animate ? .86 : 1, end: 1),
      duration: Duration(
        milliseconds: animate && !MediaQuery.disableAnimationsOf(context)
            ? 650
            : 0,
      ),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        key: const ValueKey('success-feedback'),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: MediaQuery.sizeOf(context).height < 450 ? 10 : 18,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xffffed9d), Color(0xffd5f4df)],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xffe3ba49), width: 2),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 42,
              color: Color(0xffad7318),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Jua',
                      fontSize: MediaQuery.sizeOf(context).height < 450
                          ? 24
                          : 29,
                      color: Color(0xff20624c),
                    ),
                  ),
                  if (MediaQuery.sizeOf(context).height >= 450)
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 19,
                        color: Color(0xff304c42),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xff258968),
              size: 34,
            ),
          ],
        ),
      ),
    ),
  );
}
