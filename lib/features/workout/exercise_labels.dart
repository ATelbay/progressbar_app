import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/workout_logic.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../format.dart';

/// Recording, comparison and sending are independent states. In particular,
/// an exercise beyond the plan still gets a clear recorded-result label.
class ExerciseLabels extends StatelessWidget {
  const ExerciseLabels({
    super.key,
    required this.workout,
    required this.exercise,
    this.pending = false,
    this.showComparison = false,
  });

  final Workout workout;
  final WorkoutExercise exercise;
  final bool pending;
  final bool showComparison;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final comparison = showComparison && exercise.hasFact
        ? deviationChip(context, compareExercise(exercise))
        : null;
    return Wrap(
      spacing: PbSpace.s2,
      runSpacing: PbSpace.s1,
      children: [
        if (isOutsidePlan(workout, exercise))
          PbChip(l10n.workoutOutsidePlan, color: c.accentText),
        if (exercise.hasFact)
          PbChip(l10n.workoutExerciseRecorded, color: c.success),
        ?comparison,
        if (pending) PbChip(l10n.workoutNotSent, color: c.warning),
      ],
    );
  }
}
