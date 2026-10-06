import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

class _Glass extends StatelessWidget {
  const _Glass({
    required this.child,
    required this.padding,
    required this.radius,
    required this.strong,
    this.outlined = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool strong;
  final bool outlined;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.pb;
    final shape = BorderRadius.circular(radius);
    // Reduce Transparency and similar settings swap glass for a solid surface.
    final solid = MediaQuery.highContrastOf(context);
    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(onTap: onTap, borderRadius: shape, child: content),
      );
    }
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: solid
            ? c.surface
            : strong
            ? c.glassStrong
            : c.glass,
        borderRadius: shape,
        border: outlined
            ? Border.all(color: c.accentText, width: 2)
            : Border.all(color: c.glassLine),
      ),
      child: content,
    );
    if (solid) return panel;
    return ClipRRect(
      borderRadius: shape,
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
  Widget build(BuildContext context) =>
      _Glass(padding: padding, radius: PbRadius.xl, strong: true, child: child);
}

/// The basic material: exercise cards and list rows. [current] marks the one
/// being worked on.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.current = false,
    this.onTap,
  });

  final Widget child;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => _Glass(
    padding: const EdgeInsets.symmetric(
      horizontal: PbSpace.s4,
      vertical: PbSpace.s3,
    ),
    radius: PbRadius.lg,
    strong: current,
    outlined: current,
    onTap: onTap,
    child: child,
  );
}
