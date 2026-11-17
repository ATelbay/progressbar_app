import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../../domain/workout_logic.dart';
import '../../domain/execution_logic.dart';
import '../execution_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../router.dart';
import '../../theme.dart';
import '../../widgets/barbell.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/step_button.dart';
import '../format.dart';
import '../workout/workout_providers.dart';
import 'workout_order_block.dart';

/// «2 октября · Грудь и трицепс»; just the date for a workout without a day.
String workoutTitle(BuildContext context, Workout workout) {
  final date = DateFormat.MMMMd(Localizations.localeOf(context).languageCode)
      .format(performedAt(workout));
  return workout.dayName == null ? date : '$date · ${workout.dayName}';
}

/// Chips summing a workout up: against the plan, and whether it was edited.
List<Widget> verdictChips(BuildContext context, Workout workout) {
  final l10n = AppLocalizations.of(context)!;
  final c = context.pb;
  final verdict = planVerdict(workout);
  return [
    if (!workout.isCompleted) PbChip(l10n.homeActiveLabel),
    if (!hasPlan(workout))
      PbChip(l10n.historyExercises(recordedCount(workout)))
    else if (verdict.below == 0 && verdict.skipped == 0)
      PbChip(l10n.chipAsPlanned, color: c.success),
    if (verdict.below > 0)
      PbChip(l10n.historyBelow(verdict.below), color: c.warning),
    if (verdict.skipped > 0)
      PbChip(l10n.historySkipped(verdict.skipped), color: c.warning),
    if (workout.editedAfterCompletion) PbChip(l10n.historyEdited),
  ];
}

/// One exercise as «name, plan under it, fact on the right». With [action]
/// the name gets its own line with the action next to it.
class PlanFactRow extends StatelessWidget {
  const PlanFactRow(
    this.exercise, {
    super.key,
    required this.workout,
    this.action,
    this.completed = true,
    this.showHeading = true,
  });

  final WorkoutExercise exercise;
  final Workout workout;
  final Widget? action;
  final bool completed;
  final bool showHeading;

  @override
  Widget build(BuildContext context) {
    final chip = exercise.hasFact
        ? deviationChip(context, compareExercise(workout, exercise))
        : null;
    final estimate = planComparisonEstimate(workout, exercise);
    final l = AppLocalizations.of(context)!;
    String kg(double value) => '${formatNumber(context, value)} ${l.unitKg}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PbSpace.s1,
      children: [
        _content(context),
        if (chip != null)
          Wrap(
            spacing: PbSpace.s2,
            runSpacing: PbSpace.s1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              chip,
              if (estimate != null)
                Text(
                  l.compareEstimate(kg(estimate.factKg), kg(estimate.planKg)),
                  style: PbText.caption.copyWith(color: context.pb.inkMuted),
                ),
            ],
          ),
      ],
    );
  }

  Widget _content(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final plan = planSummary(exercise);
    final fact = factSummary(exercise);
    NumberLine line(SetsSummary summary) => summaryLine(
      context,
      summary,
      measure: exercise.measure,
      usesBodyWeight: exercise.usesBodyWeight,
    );
    final name = Text(
      exercise.name,
      style: PbText.bodyStrong.copyWith(
        color: !exercise.hasFact && (completed || exercise.skipped)
            ? c.inkMuted
            : c.ink,
      ),
    );
    if (exercise.executionMode != ExecutionMode.ordinary) {
      String values(WorkoutSet set, bool planned) {
        final stages = [
          planned ? set.plan : set.fact,
          if (exercise.executionMode == ExecutionMode.dropSet)
            for (final d in set.drops) planned ? d.plan : d.fact,
        ];
        return stages
            .map(
              (v) => v == null
                  ? '—'
                  : setLine(
                      context,
                      v,
                      measure: exercise.measure,
                      usesBodyWeight: exercise.usesBodyWeight,
                    ).text,
            )
            .join(' → ');
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PbSpace.s1,
        children: [
          if (showHeading)
            Row(
              children: [
                Expanded(child: name),
                ?action,
              ],
            ),
          if (showHeading)
            Text(
              executionLabel(l10n, exercise.executionMode),
              style: PbText.caption.copyWith(color: c.inkMuted),
            ),
          if (exercise.planExecutionMode != null &&
              exercise.planExecutionMode != exercise.executionMode)
            Text(
              l10n.historyPlanPrefix(
                executionLabel(l10n, exercise.planExecutionMode!),
              ),
              style: PbText.caption.copyWith(color: c.inkMuted),
            ),
          Table(
            columnWidths: const {0: FixedColumnWidth(PbSpace.s8)},
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            children: [
              TableRow(
                children: [
                  Text('№', style: PbText.caption.copyWith(color: c.inkMuted)),
                  Text(
                    l10n.entryPlan,
                    style: PbText.caption.copyWith(color: c.inkMuted),
                  ),
                  Text(
                    l10n.entryFact,
                    style: PbText.caption.copyWith(color: c.inkMuted),
                  ),
                ],
              ),
              for (final (i, set) in exercise.sets.indexed)
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.line)),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: PbSpace.s2),
                      child: Text(
                        '${i + 1}',
                        style: PbText.caption.copyWith(color: c.inkMuted),
                      ),
                    ),
                    for (final planned in [true, false])
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          0,
                          PbSpace.s2,
                          PbSpace.s2,
                          PbSpace.s2,
                        ),
                        child: Text(
                          values(set, planned).replaceAll(' → ', '\n'),
                          style: PbText.numSm.copyWith(
                            color: planned ? c.inkMuted : c.ink,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          if (!exercise.hasFact) _MissingMark(exercise, completed: completed),
        ],
      );
    }
    final planText = plan == null
        ? null
        : Text(
            l10n.historyPlanPrefix(line(plan).text),
            style: PbText.numPlan.copyWith(color: c.inkMuted),
          );
    final result = fact != null
        ? NumberText(line(fact), style: PbText.numMd, beside: true)
        : _MissingMark(exercise, completed: completed);
    if (action case final action?) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PbSpace.s1,
        children: [
          Row(
            spacing: PbSpace.s3,
            children: [
              Expanded(child: name),
              action,
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: PbSpace.s3,
            children: [
              Expanded(child: planText ?? const SizedBox()),
              result,
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PbSpace.s1,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: PbSpace.s3,
          children: [
            Expanded(child: name),
            result,
          ],
        ),
        ?planText,
      ],
    );
  }
}

/// What stands in for the result of an exercise without one: skipped, or
/// not recorded yet while the workout goes on.
class _MissingMark extends StatelessWidget {
  const _MissingMark(this.exercise, {required this.completed});

  final WorkoutExercise exercise;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return completed || exercise.skipped
        ? PbChip(l10n.historySkippedMark, color: context.pb.warning)
        : Text(
            l10n.workoutPendingMark,
            style: PbText.caption.copyWith(color: context.pb.warning),
          );
  }
}

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  /// The workout shown in full; the newest one until the user picks another.
  String? _openId;
  bool _selectedWorkout = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final workouts = ref.watch(completedWorkoutsProvider).value;
    final openId = _selectedWorkout ? _openId : workouts?.firstOrNull?.id;
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
                  l10n.tabHistory,
                  style: PbText.title.copyWith(color: c.ink),
                ),
                if (workouts == null)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (workouts.isEmpty) ...[
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: PbSpace.s3,
                          children: [
                            Barbell(
                              plates: List.filled(5, Plate.waiting),
                              label: l10n.historyEmptyTitle,
                            ),
                            Text(
                              l10n.historyEmptyTitle,
                              style: PbText.heading.copyWith(color: c.ink),
                            ),
                            Text(
                              l10n.historyEmptyText,
                              style: PbText.body.copyWith(color: c.inkMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => context.go(Routes.home),
                    child: Text(l10n.historyToPrograms),
                  ),
                ] else
                  Expanded(
                    child: ListView.separated(
                      itemCount: workouts.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: PbSpace.s2),
                      itemBuilder: (context, index) {
                        final workout = workouts[index];
                        void toggle() => setState(() {
                          _selectedWorkout = true;
                          _openId = openId == workout.id ? null : workout.id;
                        });
                        return workout.id == openId
                            ? _OpenWorkout(workout, onCollapse: toggle)
                            : _WorkoutCard(workout, onTap: toggle);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WorkoutHeading extends StatelessWidget {
  const WorkoutHeading(this.workout, {super.key});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          workoutTitle(context, workout),
          style: PbText.bodyStrong.copyWith(color: c.ink),
        ),
        Text(
          workout.programName ?? l10n.historyNoProgram,
          style: PbText.caption.copyWith(color: c.inkMuted),
        ),
        Text(
          workout.supervisorCoachId == null
              ? l10n.workoutSolo
              : workout.supervisorCoachName == null
              ? l10n.workoutCoachUnknown
              : l10n.workoutCoach(workout.supervisorCoachName!),
          style: PbText.caption.copyWith(color: c.inkMuted),
        ),
      ],
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard(this.workout, {required this.onTap});

  final Workout workout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PbSpace.s2,
      children: [
        WorkoutHeading(workout),
        if (workoutOrderInfo(workout).changed) WorkoutOrderBlock(workout),
        Wrap(
          spacing: PbSpace.s2,
          runSpacing: PbSpace.s2,
          children: verdictChips(context, workout),
        ),
      ],
    ),
  );
}

class _OpenWorkout extends StatelessWidget {
  const _OpenWorkout(this.workout, {required this.onCollapse});

  final Workout workout;
  final VoidCallback onCollapse;

  String _groupResult(BuildContext context, List<WorkoutExercise> group) {
    final l10n = AppLocalizations.of(context)!;
    final exercise = group.first;
    final recorded = group
        .expand((e) => e.sets)
        .where((s) => s.fact != null)
        .length;
    if (recorded == 0) return l10n.historySkippedMark;
    if (exercise.executionMode == ExecutionMode.superset) {
      // Counted in rounds, as the line above: a round of two exercises is
      // one round, not two sets.
      final rounds = group.fold(
        0,
        (n, e) => n > e.sets.length ? n : e.sets.length,
      );
      final done = [
        for (var i = 0; i < rounds; i++)
          if (group.any((e) => i < e.sets.length && e.sets[i].fact != null)) i,
      ].length;
      return '${l10n.entryFact}: ${l10n.executionRoundCount(done)}';
    }
    if (exercise.executionMode == ExecutionMode.dropSet &&
        recorded == exercise.sets.length &&
        canSummarizeExecution(group)) {
      final set = exercise.sets.first;
      return [set.fact, ...set.drops.map((d) => d.fact)]
          .map(
            (value) => value == null
                ? '—'
                : setLine(
                    context,
                    value,
                    measure: exercise.measure,
                    usesBodyWeight: exercise.usesBodyWeight,
                  ).text,
          )
          .join(' → ');
    }
    return '${l10n.entryFact}: ${l10n.setsCount(recorded)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PbSpace.s2,
        children: [
          Row(
            spacing: PbSpace.s3,
            children: [
              Expanded(child: WorkoutHeading(workout)),
              StepButton(
                icon: Icons.edit_outlined,
                label: l10n.historyEdit,
                size: PbSize.touchMin,
                onTap: () =>
                    context.push('${Routes.workoutEdit}/${workout.id}'),
              ),
            ],
          ),
          WorkoutOrderBlock(workout),
          for (final group in executionGroups(workout.exercises))
            if (group.first.executionMode != ExecutionMode.ordinary)
              ExpansionTile(
                key: PageStorageKey((
                  'history-group',
                  workout.id,
                  group.first.id,
                )),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: PbSpace.s3),
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text(
                  group.map((e) => e.name).join(' + '),
                  style: PbText.bodyStrong.copyWith(color: c.ink),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${executionLabel(l10n, group.first.executionMode)} · ${group.first.executionMode == ExecutionMode.superset ? l10n.executionRounds : l10n.entrySets}: ${group.first.sets.length}',
                      style: PbText.caption.copyWith(color: c.inkMuted),
                    ),
                    Text(
                      _groupResult(context, group),
                      style: PbText.caption.copyWith(color: c.inkMuted),
                    ),
                  ],
                ),
                children: [
                  for (final exercise in group)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: PbSpace.s2),
                      child: PlanFactRow(
                        exercise,
                        workout: workout,
                        showHeading: group.length > 1,
                      ),
                    ),
                ],
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.line)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: PbSpace.s3),
                  child: PlanFactRow(group.single, workout: workout),
                ),
              ),
          if (workout.comment case final comment?)
            Text(comment, style: PbText.body.copyWith(color: c.inkMuted)),
          Wrap(
            spacing: PbSpace.s2,
            runSpacing: PbSpace.s2,
            children: verdictChips(context, workout),
          ),
          TextButton.icon(
            key: ValueKey('collapse-workout-${workout.id}'),
            onPressed: onCollapse,
            icon: const Icon(Icons.expand_less),
            label: Text(l10n.historyHideDetails),
          ),
        ],
      ),
    );
  }
}
