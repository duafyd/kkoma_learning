import 'package:flutter/material.dart';

/// Keeps pointer drawing outside scrollable controls, including short landscapes.
class CanvasWorkspace extends StatefulWidget {
  final Widget canvas;
  final Widget controls;
  final bool controlsFirst;
  const CanvasWorkspace({
    super.key,
    required this.canvas,
    required this.controls,
    this.controlsFirst = false,
  });

  @override
  State<CanvasWorkspace> createState() => _CanvasWorkspaceState();
}

class _CanvasWorkspaceState extends State<CanvasWorkspace> {
  final toolScroll = ScrollController();
  @override
  void dispose() {
    toolScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final tools = Scrollbar(
        controller: toolScroll,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: toolScroll,
          primary: false,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: widget.controls,
          ),
        ),
      );
      if (bounds.maxWidth >= 600 && bounds.maxHeight < 450) {
        return Row(
          children: [
            Expanded(child: widget.canvas),
            const SizedBox(width: 12),
            SizedBox(width: bounds.maxWidth * .42, child: tools),
          ],
        );
      }
      final panel = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: bounds.maxHeight * .4),
        child: tools,
      );
      return Column(
        children: [
          if (widget.controlsFirst) panel,
          Expanded(child: widget.canvas),
          if (!widget.controlsFirst) panel,
        ],
      );
    },
  );
}
