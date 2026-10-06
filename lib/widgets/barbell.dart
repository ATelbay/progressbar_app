import 'package:flutter/material.dart';

import '../theme.dart';

enum Plate { done, now, waiting }

/// Workout progress drawn as a bar that fills with plates, one per exercise.
class Barbell extends StatelessWidget {
  const Barbell({
    super.key,
    required this.plates,
    required this.label,
    this.count,
  });

  final List<Plate> plates;

  /// Read aloud instead of the drawing.
  final String label;

  /// Shown after the bar, e.g. «2 из 5».
  final InlineSpan? count;

  static const _height = 44.0, _plateWidth = 15.0, _barThickness = 6.0;

  @override
  Widget build(BuildContext context) {
    final c = context.pb;
    Widget plate(Plate state) => DecoratedBox(
      decoration: BoxDecoration(
        color: switch (state) {
          Plate.done => c.accent,
          Plate.now => Colors.transparent,
          Plate.waiting => c.sunken,
        },
        borderRadius: BorderRadius.circular(PbRadius.sm),
        border: switch (state) {
          Plate.done => null,
          Plate.now => Border.all(color: c.accentText, width: 2),
          Plate.waiting => Border.all(color: c.lineStrong, width: 2),
        },
      ),
      child: const SizedBox(width: _plateWidth, height: _height),
    );
    return Semantics(
      label: label,
      image: true,
      excludeSemantics: true,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: _height,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: _barThickness,
                    decoration: BoxDecoration(
                      color: c.lineStrong,
                      borderRadius: BorderRadius.circular(_barThickness / 2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: PbSpace.s3),
                    child: Row(
                      children: [
                        for (final state in plates)
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(right: PbSpace.s2),
                              child: plate(state),
                            ),
                          ),
                        Container(
                          width: 10,
                          height: 20,
                          decoration: BoxDecoration(
                            color: c.ink,
                            borderRadius: BorderRadius.circular(PbSpace.s1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: PbSpace.s3),
            Text.rich(count!, style: PbText.numMd.copyWith(color: c.ink)),
          ],
        ],
      ),
    );
  }
}
