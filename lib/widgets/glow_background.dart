import 'package:flutter/material.dart';

import '../theme.dart';

/// Screen ground with the three soft lights that sit behind the glass.
class GlowBackground extends StatelessWidget {
  const GlowBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.pb;
    final strength = Theme.of(context).brightness == Brightness.dark
        ? 0.6
        : 0.85;
    Widget glow(Color color, Alignment at, double size) => Align(
      alignment: at,
      child: FractionallySizedBox(
        widthFactor: size,
        child: AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: strength),
                  color.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return ColoredBox(
      color: c.ground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          glow(c.glow1, const Alignment(-1.6, -1.15), 1.1),
          glow(c.glow2, const Alignment(1.8, -0.2), 1.0),
          glow(c.glow3, const Alignment(-0.3, 1.35), 1.2),
          child,
        ],
      ),
    );
  }
}
