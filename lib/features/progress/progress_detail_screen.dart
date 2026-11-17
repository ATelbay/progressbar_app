import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../domain/progress_logic.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/step_button.dart';
import '../format.dart';
import '../workout/workout_providers.dart';
import 'progress_chart.dart';
import 'progress_providers.dart';

/// One exercise over time: the chosen metric, its chart and a point per
/// completed workout.
class ProgressDetailScreen extends ConsumerWidget {
  const ProgressDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final workouts = ref.watch(completedWorkoutsProvider).value;
    final progress = workouts == null
        ? null
        : exerciseProgress(exerciseId, workouts);
    final chosen = ref.watch(progressMetricProvider);
    final metric = progress == null
        ? null
        : progress.metrics.containsKey(chosen)
        ? chosen
        : progress.mainMetric;

    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              PbSpace.s4,
              PbSpace.s4,
              PbSpace.s4,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: PbSpace.s3,
              children: [
                Row(
                  spacing: PbSpace.s3,
                  children: [
                    StepButton(
                      icon: Icons.chevron_left,
                      label: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      size: PbSize.touchMin,
                      onTap: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        progress?.name ?? '',
                        style: PbText.title.copyWith(color: c.ink),
                      ),
                    ),
                  ],
                ),
                if (workouts == null)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (progress == null || metric == null)
                  Text(
                    l10n.progressGone,
                    style: PbText.body.copyWith(color: c.inkMuted),
                  )
                else ...[
                  if (progress.metrics.length > 1)
                    _MetricSelector(
                      metrics: progress.metrics.keys.toList(),
                      value: metric,
                      onChanged: ref.read(progressMetricProvider.notifier).set,
                    ),
                  Expanded(child: _Points(progress.metrics[metric]!)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Max, weight or reps; a dropdown when large text would not fit segments.
class _MetricSelector extends StatelessWidget {
  const _MetricSelector({
    required this.metrics,
    required this.value,
    required this.onChanged,
  });

  final List<ProgressMetric> metrics;
  final ProgressMetric value;
  final ValueChanged<ProgressMetric> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    return LayoutBuilder(
      builder: (context, constraints) {
        final available =
            (constraints.maxWidth - 2 * PbSpace.s1) / metrics.length;
        final fits = metrics.every((metric) {
          final painter = TextPainter(
            text: TextSpan(text: metricName(l10n, metric), style: PbText.label),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          final fits = painter.width + 2 * PbSpace.s4 <= available;
          painter.dispose();
          return fits;
        });
        if (!fits) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: PbSpace.s4,
              vertical: PbSize.rowInset,
            ),
            decoration: BoxDecoration(
              color: c.sunken,
              borderRadius: BorderRadius.circular(PbRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.progressMetricLabel,
                  style: PbText.label.copyWith(color: c.inkMuted),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<ProgressMetric>(
                    value: value,
                    isExpanded: true,
                    itemHeight: null,
                    icon: Icon(
                      Icons.unfold_more_rounded,
                      color: c.inkMuted,
                      size: PbSize.icon,
                    ),
                    items: [
                      for (final metric in metrics)
                        DropdownMenuItem(
                          value: metric,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: PbSize.touchMin,
                            ),
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                metricName(l10n, metric),
                                style: PbText.bodyStrong.copyWith(color: c.ink),
                              ),
                            ),
                          ),
                        ),
                    ],
                    onChanged: (metric) {
                      if (metric != null) onChanged(metric);
                    },
                  ),
                ),
              ],
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.all(PbSpace.s1),
          decoration: BoxDecoration(
            color: c.sunken,
            borderRadius: BorderRadius.circular(PbRadius.md),
          ),
          child: SegmentedButton<ProgressMetric>(
            showSelectedIcon: false,
            style: ButtonStyle(
              minimumSize: const WidgetStatePropertyAll(
                Size(0, PbSize.touchMin),
              ),
              side: const WidgetStatePropertyAll(BorderSide.none),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(PbRadius.md),
                ),
              ),
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? c.selection
                    : Colors.transparent,
              ),
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) =>
                    states.contains(WidgetState.selected) ? c.ink : c.inkMuted,
              ),
              textStyle: const WidgetStatePropertyAll(PbText.label),
            ),
            segments: [
              for (final metric in metrics)
                ButtonSegment(
                  value: metric,
                  label: Text(metricName(l10n, metric)),
                ),
            ],
            selected: {value},
            onSelectionChanged: (selected) => onChanged(selected.single),
          ),
        );
      },
    );
  }
}

/// The latest value with its chart, then every point, newest first.
class _Points extends StatelessWidget {
  const _Points(this.points);

  /// At least one point, oldest first.
  final List<ProgressPoint> points;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final language = Localizations.localeOf(context).languageCode;
    final last = points.last;
    final best = pointSet(context, last);
    final change = progressChange(context, points);
    return ListView(
      padding: const EdgeInsets.only(bottom: PbSpace.s4),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(PbSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: PbSpace.s2,
            children: [
              Text(
                metricTitle(l10n, last.metric),
                style: PbText.label.copyWith(color: c.inkMuted),
              ),
              ProgressValue(
                last,
                style: PbText.numHero,
                approxStyle: PbText.numMd,
              ),
              if (change != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: PbChip(
                    l10n.progressChange(change.text, points.length),
                    color: change.down
                        ? c.warning
                        : points.last.value == points.first.value
                        ? c.inkMuted
                        : c.success,
                  ),
                ),
              if (best != null)
                Text(
                  l10n.progressBest(best.text),
                  style: PbText.caption.copyWith(color: c.ink),
                ),
              if (last.metric == ProgressMetric.estimatedMax)
                Text(
                  l10n.progressEstimatedMaxHint,
                  style: PbText.caption.copyWith(color: c.inkMuted),
                ),
              ProgressChart(points),
            ],
          ),
        ),
        const SizedBox(height: PbSpace.s2),
        GlassCard(
          padding: const EdgeInsets.symmetric(
            horizontal: PbSpace.s4,
            vertical: PbSpace.s1,
          ),
          child: Column(
            children: [
              for (final (index, point) in points.reversed.indexed) ...[
                if (index > 0) Divider(color: c.line, height: PbSize.stroke),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: PbSize.rowInset,
                  ),
                  child: Row(
                    spacing: PbSpace.s3,
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat.MMMMd(language).format(point.at),
                          style: PbText.body.copyWith(color: c.ink),
                        ),
                      ),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            NumberText(
                              pointSet(context, point) ??
                                  pointValue(context, point),
                              style: PbText.numSm,
                              beside: true,
                            ),
                            if (point.metric == ProgressMetric.estimatedMax)
                              Text(
                                pointValue(context, point).text,
                                style: PbText.caption.copyWith(
                                  color: c.inkMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
