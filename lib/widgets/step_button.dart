import 'package:flutter/material.dart';

import '../theme.dart';

/// Square «minus»/«plus» button of the entry panel; [label] is read aloud.
class StepButton extends StatelessWidget {
  const StepButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = PbSize.actionHeight,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.pb;
    return IconButton(
      onPressed: onTap,
      tooltip: label,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        fixedSize: Size.square(size),
        backgroundColor: c.sunken,
        foregroundColor: c.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PbRadius.md),
        ),
      ),
    );
  }
}

/// A choice in a row of options: muscle groups, effort, keypad keys.
class PbPill extends StatelessWidget {
  const PbPill({
    super.key,
    required this.child,
    required this.onTap,
    this.selected = false,
    this.tooltip,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.pb;
    final button = TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(PbSize.touchMin, PbSize.touchMin),
        padding: const EdgeInsets.symmetric(
          horizontal: PbSpace.s3,
          vertical: PbSpace.s2,
        ),
        backgroundColor: selected ? c.accent : c.sunken,
        foregroundColor: selected ? c.onAccent : c.ink,
        textStyle: PbText.label,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PbRadius.md),
        ),
      ),
      child: child,
    );
    return Semantics(
      selected: selected,
      child: tooltip == null
          ? button
          : Tooltip(message: tooltip, child: button),
    );
  }
}
