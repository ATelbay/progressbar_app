import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../../domain/workout_logic.dart';
import '../../l10n/app_localizations.dart';
import '../../router.dart';
import '../../theme.dart';
import '../../widgets/barbell.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/step_button.dart';
import '../format.dart';
import '../workout/workout_providers.dart';

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
    this.action,
    this.completed = true,
  });

  final WorkoutExercise exercise;
  final Widget? action;
  final bool completed;

  @override
  Widget build(BuildContext context) {
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
      style: PbText.bodyStrong.copyWith(color: c.ink),
    );
    final planText = plan == null
        ? null
        : Text(
            l10n.historyPlanPrefix(line(plan).text),
            style: PbText.numSm.copyWith(color: c.inkMuted),
          );
    final result = fact != null
        ? NumberText(line(fact), style: PbText.numMd, beside: true)
        : Text(
            completed ? l10n.historySkippedMark : l10n.workoutPendingMark,
            style: PbText.caption.copyWith(color: c.warning),
          );
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: PbSpace.s3,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [name, ?planText],
          ),
        ),
        result,
      ],
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final workouts = ref.watch(completedWorkoutsProvider).value;
    final openId = _openId ?? workouts?.firstOrNull?.id;
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
                        return workout.id == openId
                            ? _OpenWorkout(workout)
                            : _WorkoutCard(
                                workout,
                                onTap: () =>
                                    setState(() => _openId = workout.id),
                              );
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
    child: Row(
      spacing: PbSpace.s3,
      children: [
        Expanded(child: WorkoutHeading(workout)),
        verdictChips(context, workout).first,
      ],
    ),
  );
}

class _OpenWorkout extends StatelessWidget {
  const _OpenWorkout(this.workout);

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    return GlassPanel(
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
          for (final (index, exercise) in workout.exercises.indexed)
            DecoratedBox(
              decoration: BoxDecoration(
                border: index == 0
                    ? null
                    : Border(top: BorderSide(color: c.line)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: PbSpace.s2),
                child: PlanFactRow(exercise),
              ),
            ),
          if (workout.comment case final comment?)
            Text(comment, style: PbText.body.copyWith(color: c.inkMuted)),
          Wrap(
            spacing: PbSpace.s2,
            runSpacing: PbSpace.s2,
            children: verdictChips(context, workout),
          ),
        ],
      ),
    );
  }
}
