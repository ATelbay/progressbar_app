import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../domain/workout_logic.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../widgets/barbell.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glow_background.dart';
import '../format.dart';
import '../workout/workout_providers.dart';

String _unit(AppLocalizations l10n, ProgressUnit unit) => switch (unit) {
  ProgressUnit.kilograms => l10n.unitKg,
  ProgressUnit.seconds => l10n.unitSec,
  ProgressUnit.reps => l10n.unitReps,
};

/// «60 кг», «45 с», «12» — and «12 +10 кг» for reps done with extra weight.
NumberLine _pointLine(BuildContext context, ProgressPoint point) {
  final l10n = AppLocalizations.of(context)!;
  return NumberLine([
    (formatNumber(context, point.value), false),
    if (point.unit != ProgressUnit.reps) (' ${_unit(l10n, point.unit)}', true),
    if (point.extraKg > 0)
      (' +${formatNumber(context, point.extraKg)} ${l10n.unitKg}', true),
  ]);
}

/// One exercise over time: a point per completed workout.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  /// The exercise shown; the most recently done one until the user picks.
  String? _exerciseId;

  Future<void> _pick(List<({String exerciseId, String name})> exercises) async {
    final c = context.pb;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: c.scrim,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PbSpace.s2),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.7,
            ),
            child: GlassPanel(
              padding: const EdgeInsets.symmetric(vertical: PbSpace.s2),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final exercise in exercises)
                    ListTile(
                      title: Text(
                        exercise.name,
                        style: PbText.body.copyWith(color: c.ink),
                      ),
                      onTap: () => Navigator.pop(context, exercise.exerciseId),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _exerciseId = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final language = Localizations.localeOf(context).languageCode;
    final workouts = ref.watch(completedWorkoutsProvider).value;
    final exercises = exercisesWithResults(workouts ?? const []);
    final selected =
        exercises.where((e) => e.exerciseId == _exerciseId).firstOrNull ??
        exercises.firstOrNull;
    final points = selected == null
        ? const <ProgressPoint>[]
        : progressFor(selected.exerciseId, workouts!);

    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(PbSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: PbSpace.s3,
              children: [
                Text(
                  l10n.tabProgress,
                  style: PbText.title.copyWith(color: c.ink),
                ),
                if (workouts == null)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (selected == null)
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: PbSpace.s3,
                          children: [
                            Barbell(
                              plates: List.filled(5, Plate.waiting),
                              label: l10n.progressEmptyTitle,
                            ),
                            Text(
                              l10n.progressEmptyTitle,
                              style: PbText.heading.copyWith(color: c.ink),
                            ),
                            Text(
                              l10n.progressEmptyText,
                              style: PbText.body.copyWith(color: c.inkMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else ...[
                  OutlinedButton(
                    onPressed: () => _pick(exercises),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: c.glassStrong,
                      side: BorderSide(color: c.lineStrong),
                      padding: const EdgeInsets.symmetric(
                        horizontal: PbSpace.s4,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            selected.name,
                            style: PbText.heading.copyWith(color: c.ink),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.expand_more),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        _ChartPanel(points),
                        for (final point in points.reversed)
                          Padding(
                            padding: const EdgeInsets.only(top: PbSpace.s2),
                            child: GlassCard(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      DateFormat.MMMMd(language)
                                          .format(point.at),
                                      style: PbText.body.copyWith(color: c.ink),
                                    ),
                                  ),
                                  NumberText(
                                    _pointLine(context, point),
                                    style: PbText.numSm,
                                    beside: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel(this.points);

  /// At least one point, oldest first.
  final List<ProgressPoint> points;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final language = Localizations.localeOf(context).languageCode;
    final first = points.first, last = points.last;
    final change = last.value - first.value;
    final sign = change > 0
        ? '+'
        : change < 0
        ? '−'
        : '';
    final changeText =
        '$sign${formatNumber(context, change.abs())} ${_unit(l10n, last.unit)}';
    String day(DateTime at) => DateFormat.MMMd(language).format(at);
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PbSpace.s2,
        children: [
          Text(switch (last.unit) {
            ProgressUnit.kilograms => l10n.progressMaxWeight,
            ProgressUnit.seconds => l10n.progressMaxTime,
            ProgressUnit.reps => l10n.progressMaxReps,
          }, style: PbText.label.copyWith(color: c.inkMuted)),
          Wrap(
            spacing: PbSpace.s3,
            runSpacing: PbSpace.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // The value large, its unit and extra weight smaller beside it.
              Text.rich(
                TextSpan(
                  children: [
                    for (final (text, isUnit) in _pointLine(
                      context,
                      last,
                    ).parts)
                      TextSpan(
                        text: text,
                        style: isUnit
                            ? PbText.numMd.copyWith(color: c.inkMuted)
                            : null,
                      ),
                  ],
                ),
                style: PbText.numHero.copyWith(color: c.ink),
              ),
              if (points.length > 1)
                PbChip(
                  l10n.progressChange(changeText, points.length),
                  color: change < 0 ? c.warning : c.success,
                ),
            ],
          ),
          Semantics(
            image: true,
            label: l10n.progressChartLabel(
              _pointLine(context, first).text,
              day(first.at),
              _pointLine(context, last).text,
              day(last.at),
            ),
            child: AspectRatio(
              aspectRatio: 326 / 190,
              child: CustomPaint(
                painter: _ChartPainter(
                  values: [for (final p in points) p.value],
                  firstDay: day(first.at),
                  lastDay: day(last.at),
                  format: (v) => formatNumber(context, v),
                  colors: c,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
  });

  final List<double> values;
  final String firstDay, lastDay;
  final String Function(double) format;
  final PbColors colors;

  static const _left = 34.0, _top = 12.0, _bottom = 30.0, _inset = 12.0;

  TextPainter _text(String text, TextStyle style) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    var low = values.reduce((a, b) => a < b ? a : b);
    var high = values.reduce((a, b) => a > b ? a : b);
    if (low == high) {
      // A flat line sits in the middle rather than on an edge.
      low -= 1;
      high += 1;
    }
    final plot = Rect.fromLTRB(_left, _top, size.width, size.height - _bottom);
    double y(double value) =>
        plot.bottom - (value - low) / (high - low) * plot.height;
    double x(int index) => values.length == 1
        ? plot.center.dx
        : plot.left +
              _inset +
              index * (plot.width - 2 * _inset) / (values.length - 1);

    final axis = PbText.numSm.copyWith(fontSize: 13, color: colors.inkMuted);
    final grid = Paint()
      ..color = colors.line
      ..strokeWidth = 1;
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
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
    final dot = Paint()..color = colors.accentText;
    for (final spot in spots.take(spots.length - 1)) {
      canvas.drawCircle(spot, 5, dot);
    }
    canvas
      ..drawCircle(spots.last, 7, Paint()..color = colors.accent)
      ..drawCircle(
        spots.last,
        7,
        Paint()
          ..color = colors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

    final days = PbText.caption.copyWith(fontSize: 12, color: colors.inkMuted);
    final from = _text(firstDay, days), to = _text(lastDay, days);
    final baseline = size.height - from.height;
    if (values.length > 1) from.paint(canvas, Offset(plot.left, baseline));
    to.paint(canvas, Offset(size.width - to.width, baseline));
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.values != values || old.colors != colors || old.lastDay != lastDay;
}
