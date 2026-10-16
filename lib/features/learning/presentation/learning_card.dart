import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../domain/learning_models.dart';

class LearningCard extends StatelessWidget {
  final LearningItem item;
  final bool showLetterPair;
  final VoidCallback onListen;
  final VoidCallback? onTrace;
  const LearningCard({
    super.key,
    required this.item,
    required this.showLetterPair,
    required this.onListen,
    required this.onTrace,
  });

  @override
  Widget build(BuildContext context) {
    final (wash, ink) = switch (item.subject) {
      'hangul' => (const Color(0xfff8e9de), const Color(0xffa75238)),
      'english' => (const Color(0xffe1efe7), const Color(0xff276c59)),
      _ => (const Color(0xffe5edf7), const Color(0xff456e9e)),
    };
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: StorybookTheme.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08283b49),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Material(
              color: wash,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onListen,
                child: Center(
                  child: Text(
                    item.symbol,
                    style: TextStyle(
                      fontFamily: 'Jua',
                      fontSize: 76,
                      color: ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${item.picture} ${item.example}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              fontFamilyFallback: ['Noto Color Emoji', 'Segoe UI Emoji'],
            ),
          ),
          if (showLetterPair)
            Text(
              '${item.symbol.toUpperCase()} ↔ ${item.symbol.toLowerCase()}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, color: ink),
            ),
          if (item.subject == 'math')
            Text(
              List.filled(int.parse(item.symbol), '●').join(' '),
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: ink),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: '${item.symbol} 읽어 주기',
                onPressed: onListen,
                style: IconButton.styleFrom(
                  backgroundColor: wash,
                  foregroundColor: ink,
                ),
                icon: const Icon(Icons.volume_up_rounded),
              ),
              if (onTrace != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onTrace,
                    child: const Text('따라 그리기', textAlign: TextAlign.center),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
