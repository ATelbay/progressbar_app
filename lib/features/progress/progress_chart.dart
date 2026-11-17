import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../domain/models.dart';
import '../../domain/progress_logic.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../format.dart';

String progressUnit(AppLocalizations l10n, ProgressUnit unit) => switch (unit) {
  ProgressUnit.kilograms => l10n.unitKg,
  ProgressUnit.seconds => l10n.unitSec,
  ProgressUnit.reps => l10n.unitReps,
};

/// What the value of [metric] is called above the chart.
String metricTitle(AppLocalizations l10n, ProgressMetric metric) =>
    switch (metric) {
      ProgressMetric.estimatedMax => l10n.progressEstimatedMax,
      ProgressMetric.weight => l10n.progressMaxWeight,
      ProgressMetric.reps => l10n.progressRepsAtTop,
      ProgressMetric.time => l10n.progressMaxTime,
      ProgressMetric.bodyReps => l10n.progressMaxReps,
    };

/// The short name of [metric] on its switch.
String metricName(AppLocalizations l10n, ProgressMetric metric) =>
    switch (metric) {
      ProgressMetric.estimatedMax => l10n.progressMetricMax,
      ProgressMetric.weight => l10n.progressMetricWeight,
      ProgressMetric.reps || ProgressMetric.bodyReps => l10n.progressMetricReps,
      ProgressMetric.time => l10n.entryTime,
    };

/// The value of a point: «≈ 80 кг» for an estimate, «60 кг», «10», «45 с»,
/// and «12 +10 кг» for reps done with extra weight.
NumberLine pointValue(BuildContext context, ProgressPoint point) {
  final l10n = AppLocalizations.of(context)!;
  return NumberLine([
    if (point.metric == ProgressMetric.estimatedMax) ('≈ ', true),
    (formatNumber(context, point.value), false),
    (' ${progressUnit(l10n, point.unit)}', true),
    if (point.extraKg > 0)
      (' +${formatNumber(context, point.extraKg)} ${l10n.unitKg}', true),
  ]);
}

/// The set a point comes from, «60 кг × 10»; null when the value already
/// says it all (time, body weight).
NumberLine? pointSet(BuildContext context, ProgressPoint point) =>
    switch (point.metric) {
      ProgressMetric.estimatedMax ||
      ProgressMetric.weight ||
      ProgressMetric.reps => setLine(
        context,
        point.best,
        measure: Measure.reps,
        usesBodyWeight: false,
      ),
      ProgressMetric.time || ProgressMetric.bodyReps => null,
    };

/// «+4 кг»: the change from the first point to the last.
({String text, bool down})? progressChange(
  BuildContext context,
  List<ProgressPoint> points,
) {
  if (points.length < 2) return null;
  final change = points.last.value - points.first.value;
  final sign = change > 0
      ? '+'
      : change < 0
      ? '−'
      : '';
  final unit = progressUnit(AppLocalizations.of(context)!, points.last.unit);
  return (
    text: '$sign${formatNumber(context, change.abs())} $unit',
    down: change < 0,
  );
}

/// The big chart of one metric: grid with values, the line, the latest point
/// larger, the first and last day under it.
class ProgressChart extends StatelessWidget {
  const ProgressChart(this.points, {super.key});

  /// At least one point, oldest first.
  final List<ProgressPoint> points;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final language = Localizations.localeOf(context).languageCode;
    String day(DateTime at) => DateFormat.MMMd(language).format(at);
    final first = points.first, last = points.last;
    return Semantics(
      image: true,
      label: l10n.progressChartLabel(
        pointValue(context, first).text,
        day(first.at),
        pointValue(context, last).text,
        day(last.at),
      ),
      child: SizedBox(
        height:
            (PbSize.chartHeight + PbSize.chartDateHeight) *
            MediaQuery.textScalerOf(context).scale(1),
        child: CustomPaint(
          painter: _ChartPainter(
            values: [for (final p in points) p.value],
            firstDay: day(first.at),
            lastDay: day(last.at),
            format: (v) => formatNumber(context, v),
            colors: c,
            textScaler: MediaQuery.textScalerOf(context),
          ),
        ),
      ),
    );
  }
}

/// A small line for a list row, without labels.
class Sparkline extends StatelessWidget {
  const Sparkline(this.points, {super.key});

  /// At least one point, oldest first.
  final List<ProgressPoint> points;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: PbSize.sparkWidth,
      height: PbSize.sparkHeight,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: [for (final p in points) p.value],
          colors: context.pb,
        ),
      ),
    ),
  );
}

(double low, double high) _range(List<double> values) {
  var low = values.reduce((a, b) => a < b ? a : b);
  var high = values.reduce((a, b) => a > b ? a : b);
  if (low == high) {
    // A flat line sits in the middle rather than on an edge.
    low -= 1;
    high += 1;
  }
  return (low, high);
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.colors});

  final List<double> values;
  final PbColors colors;

  static const _dot = PbSize.sparkDot;

  @override
  void paint(Canvas canvas, Size size) {
    final (low, high) = _range(values);
    final plot = Rect.fromLTRB(
      _dot,
      _dot,
      size.width - _dot,
      size.height - _dot,
    );
    final spots = [
      for (final (i, v) in values.indexed)
        Offset(
          values.length == 1
              ? plot.right
              : plot.left + i * plot.width / (values.length - 1),
          plot.bottom - (v - low) / (high - low) * plot.height,
        ),
    ];
    canvas
      ..drawPath(
        Path()..addPolygon(spots, false),
        Paint()
          ..color = colors.accentText
          ..style = PaintingStyle.stroke
          ..strokeWidth = PbSize.strokeStrong
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(spots.last, _dot, Paint()..color = colors.accentText);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.colors != colors;
}

/// Three grid lines with their values, the line through the points, and the
/// latest point drawn larger.
class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.values,
    required this.firstDay,
    required this.lastDay,
    required this.format,
    required this.colors,
    required this.textScaler,
  });

  final TextScaler textScaler;
  final List<double> values;
  final String firstDay, lastDay;
  final String Function(double) format;
  final PbColors colors;

  static const _left = PbSize.chartAxisWidth,
      _top = PbSize.chartTop,
      _bottom = PbSize.chartDateHeight,
      _inset = PbSize.chartInset;

  TextPainter _text(String text, TextStyle style) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final (low, high) = _range(values);
    final axis = PbText.numAxis.copyWith(color: colors.inkMuted);
    final days = PbText.caption.copyWith(color: colors.inkMuted);
    final labels = [
      high,
      (high + low) / 2,
      low,
    ].map((v) => _text(format(v), axis)).toList();
    final left = labels.fold<double>(
      _left,
      (width, label) => math.max(width, label.width + PbSpace.s2),
    );
    final dateHeight = _text(firstDay, days).height;
    final plot = Rect.fromLTRB(
      left,
      _top,
      size.width,
      size.height - math.max(_bottom, dateHeight + PbSpace.s2),
    );
    double y(double value) =>
        plot.bottom - (value - low) / (high - low) * plot.height;
    double x(int index) => values.length == 1
        ? plot.center.dx
        : plot.left +
              _inset +
              index * (plot.width - 2 * _inset) / (values.length - 1);

    final grid = Paint()
      ..color = colors.line
      ..strokeWidth = PbSize.stroke;
    for (final value in [high, (high + low) / 2, low]) {
      canvas.drawLine(
        Offset(plot.left, y(value)),
        Offset(size.width, y(value)),
        grid,
      );
      final label = _text(format(value), axis);
      label.paint(canvas, Offset(0, y(value) - label.height / 2));
    }

    final spots = [for (final (i, v) in values.indexed) Offset(x(i), y(v))];
    canvas.drawPath(
      Path()..addPolygon(spots, false),
      Paint()
        ..color = colors.accentText
        ..style = PaintingStyle.stroke
        ..strokeWidth = PbSize.strokeStrong
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    final dot = Paint()..color = colors.accentText;
    for (final spot in spots.take(spots.length - 1)) {
      canvas.drawCircle(spot, PbSize.chartDot, Paint()..color = colors.surface);
      canvas.drawCircle(
        spot,
        PbSize.chartDot,
        dot
          ..style = PaintingStyle.stroke
          ..strokeWidth = PbSize.strokeStrong,
      );
    }
    canvas
      ..drawCircle(
        spots.last,
        PbSize.chartLastDot,
        Paint()..color = colors.accent,
      )
      ..drawCircle(
        spots.last,
        PbSize.chartLastDot,
        Paint()
          ..color = colors.surface
          ..style = PaintingStyle.stroke
          ..strokeWidth = PbSize.strokeStrong,
      );

    final from = _text(firstDay, days), to = _text(lastDay, days);
    final baseline = size.height - from.height;
    if (values.length > 1) from.paint(canvas, Offset(plot.left, baseline));
    to.paint(canvas, Offset(size.width - to.width, baseline));
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.values != values ||
      old.colors != colors ||
      old.lastDay != lastDay ||
      old.firstDay != firstDay ||
      old.textScaler != textScaler;
}

/// Approximation sign and units stay quieter than the measured value.
class ProgressValue extends StatelessWidget {
  const ProgressValue(
    this.point, {
    super.key,
    required this.style,
    required this.approxStyle,
  });
  final ProgressPoint point;
  final TextStyle style, approxStyle;
  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        for (final (text, unit) in pointValue(context, point).parts)
          TextSpan(
            text: text,
            style: unit
                ? approxStyle.copyWith(color: context.pb.inkMuted)
                : style.copyWith(color: context.pb.ink),
          ),
      ],
    ),
  );
}

class EmptyProgressChart extends StatelessWidget {
  const EmptyProgressChart({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: PbSize.emptyChartHeight,
      width: PbSize.emptyChartWidth,
      child: CustomPaint(painter: _EmptyChartPainter(context.pb)),
    ),
  );
}

class _EmptyChartPainter extends CustomPainter {
  _EmptyChartPainter(this.colors);
  final PbColors colors;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = colors.line
      ..strokeWidth = PbSize.stroke;
    for (final y in [PbSpace.s2, size.height / 2, size.height - PbSpace.s2]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      PbSize.emptyChartDot,
      Paint()..color = colors.ground,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      PbSize.emptyChartDot,
      Paint()
        ..color = colors.lineStrong
        ..style = PaintingStyle.stroke
        ..strokeWidth = PbSize.strokeStrong,
    );
  }

  @override
  bool shouldRepaint(_EmptyChartPainter old) => old.colors != colors;
}
