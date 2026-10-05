import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Dense glass for panels that hold large numbers and input.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(PbSpace.s4),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.pb;
    final radius = BorderRadius.circular(PbRadius.xl);
    // Reduce Transparency and similar settings swap glass for a solid surface.
    final solid = MediaQuery.highContrastOf(context);
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: solid ? c.surface : c.glassStrong,
        borderRadius: radius,
        border: Border.all(color: c.glassLine),
      ),
      child: Padding(padding: padding, child: child),
    );
    if (solid) return panel;
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: PbSize.glassBlur / 2,
          sigmaY: PbSize.glassBlur / 2,
        ),
        child: panel,
      ),
    );
  }
}
