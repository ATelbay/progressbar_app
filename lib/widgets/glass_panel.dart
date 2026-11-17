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
    // A solid surface supports the platform's increased-contrast setting.
    final solid = MediaQuery.highContrastOf(context);
    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = InkWell(onTap: onTap, borderRadius: shape, child: content);
    }
    // Lets switches, list rows and ink effects inside paint on the glass.
    content = Material(type: MaterialType.transparency, child: content);
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: solid
            ? c.surface
            : strong
            ? c.glassStrong
            : c.glass,
        borderRadius: shape,
        border: outlined
            ? Border.all(color: c.accentText)
            : Border.all(color: strong ? c.glassLine : c.line),
      ),
      child: content,
    );
    final clipped = ClipRRect(
      borderRadius: shape,
      child: solid || !strong
          ? panel
          : BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: PbSize.glassBlur,
                sigmaY: PbSize.glassBlur,
              ),
              child: panel,
            ),
    );
    if (!strong) return clipped;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: [
          BoxShadow(
            color: c.glassShadow,
            offset: const Offset(0, PbSize.shadowOffset),
            blurRadius: PbSize.shadowBlur,
          ),
        ],
      ),
      child: clipped,
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
    this.padding = const EdgeInsets.symmetric(
      horizontal: PbSpace.s4,
      vertical: PbSpace.s3,
    ),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => _Glass(
    padding: padding,
    radius: PbRadius.lg,
    strong: current,
    outlined: current,
    onTap: onTap,
    child: child,
  );
}
