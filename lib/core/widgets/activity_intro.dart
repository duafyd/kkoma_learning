import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

class ActivityIntro extends StatelessWidget {
  final IconData icon;
  final String title, instruction;
  const ActivityIntro({
    super.key,
    required this.icon,
    required this.title,
    required this.instruction,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xffe5eee5),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 34, color: StorybookTheme.teal),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Jua',
                  fontSize: 26,
                  color: StorybookTheme.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(instruction),
            ],
          ),
        ),
      ],
    ),
  );
}
