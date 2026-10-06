import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/models.dart';
import '../domain/workout_logic.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';

/// «12,5» in Russian and Kazakh, «12.5» in English.
String formatNumber(BuildContext context, num value) => NumberFormat(
  '0.##',
  Localizations.localeOf(context).languageCode,
).format(value);

/// A line of numbers such as «3 × 12 × 15 кг»; units are kept apart so they
/// can be shown muted.
class NumberLine {
  const NumberLine(this.parts);

  final List<(String text, bool isUnit)> parts;

  String get text => parts.map((p) => p.$1).join();
}

List<(String, bool)> _count(BuildContext context, SetValues v) => [
  (formatNumber(context, v.reps ?? v.seconds ?? 0), false),
  if (v.reps == null) (' ${AppLocalizations.of(context)!.unitSec}', true),
];

List<(String, bool)> _weight(BuildContext context, SetValues v) => [
  (formatNumber(context, v.weightKg), false),
  (' ${AppLocalizations.of(context)!.unitKg}', true),
];

/// Weight is part of the line unless the exercise is done without any.
bool _showsWeight(SetValues v, Measure measure, bool usesBodyWeight) =>
    v.weightKg > 0 || (!usesBodyWeight && measure == Measure.reps);

/// «3 × 12 × 15 кг»; just the number of sets when they differ.
NumberLine summaryLine(
  BuildContext context,
  SetsSummary summary, {
  required Measure measure,
  required bool usesBodyWeight,
}) {
  final values = summary.values;
  if (values == null) {
    return NumberLine([
      (AppLocalizations.of(context)!.setsCount(summary.count), false),
    ]);
  }
  return NumberLine([
    ('${summary.count} × ', false),
    ..._count(context, values),
    if (_showsWeight(values, measure, usesBodyWeight)) ...[
      (' × ', false),
      ..._weight(context, values),
    ],
  ]);
}

/// One set: «15 кг × 12», «12», «60 с».
NumberLine setLine(
  BuildContext context,
  SetValues values, {
  required Measure measure,
  required bool usesBodyWeight,
}) => NumberLine([
  if (_showsWeight(values, measure, usesBodyWeight)) ...[
    ..._weight(context, values),
    (' × ', false),
  ],
  ..._count(context, values),
]);

class NumberText extends StatelessWidget {
  const NumberText(this.line, {super.key, required this.style, this.color});

  final NumberLine line;
  final TextStyle style;

  /// Colour of the numbers; units are always muted.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.pb;
    return Text.rich(
      TextSpan(
        children: [
          for (final (text, isUnit) in line.parts)
            TextSpan(
              text: text,
              style: isUnit ? TextStyle(color: c.inkMuted) : null,
            ),
        ],
      ),
      style: style.copyWith(color: color ?? c.ink),
      softWrap: false,
    );
  }
}

/// «по плану», «ниже плана», «сейчас»…
class PbChip extends StatelessWidget {
  const PbChip(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.pb;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.sunken,
        borderRadius: BorderRadius.circular(PbRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PbSpace.s2,
          vertical: PbSpace.s1,
        ),
        child: Text(
          text,
          style: PbText.label.copyWith(
            fontSize: 13,
            letterSpacing: 0,
            color: color ?? c.inkMuted,
          ),
        ),
      ),
    );
  }
}

/// The chip for how an exercise or set went against its plan; null when
/// there is nothing to compare.
PbChip? deviationChip(BuildContext context, DeviationKind kind) {
  final l10n = AppLocalizations.of(context)!;
  final c = context.pb;
  return switch (kind) {
    DeviationKind.asPlanned => PbChip(l10n.chipAsPlanned, color: c.success),
    DeviationKind.above => PbChip(l10n.chipAbovePlan, color: c.success),
    DeviationKind.below => PbChip(l10n.chipBelowPlan, color: c.warning),
    DeviationKind.extra || DeviationKind.missing => null,
  };
}
