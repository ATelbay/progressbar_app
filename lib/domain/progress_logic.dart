import 'models.dart';
import 'strength_estimate.dart';

export 'strength_estimate.dart' show estimatedMaxKg;
import 'workout_logic.dart';

/// What a progress line follows.
enum ProgressMetric {
  /// The weight one could lift once, estimated from the weight and reps of
  /// the best set, so that more reps at the same weight count as progress.
  estimatedMax,

  /// The heaviest weight; more reps break a tie.
  weight,

  /// The reps of that heaviest set.
  reps,

  /// The longest time.
  time,

  /// A body-weight exercise: the most reps at the heaviest extra weight.
  bodyReps,
}

enum ProgressUnit { kilograms, seconds, reps }

ProgressUnit unitOf(ProgressMetric metric) => switch (metric) {
  ProgressMetric.estimatedMax ||
  ProgressMetric.weight => ProgressUnit.kilograms,
  ProgressMetric.reps || ProgressMetric.bodyReps => ProgressUnit.reps,
  ProgressMetric.time => ProgressUnit.seconds,
};

/// The metrics an exercise measured this way can be followed by, the main
/// one first.
List<ProgressMetric> metricsFor(
  Measure measure, {
  required bool usesBodyWeight,
}) => measure == Measure.time
    ? const [ProgressMetric.time]
    : usesBodyWeight
    ? const [ProgressMetric.bodyReps]
    : const [
        ProgressMetric.estimatedMax,
        ProgressMetric.weight,
        ProgressMetric.reps,
      ];

/// One point per completed workout.
class ProgressPoint {
  const ProgressPoint({
    required this.at,
    required this.workoutId,
    required this.metric,
    required this.value,
    required this.best,
  });

  final DateTime at;
  final String workoutId;
  final ProgressMetric metric;
  final double value;

  /// The set the value comes from, as recorded. For a body-weight exercise
  /// its weight is the extra weight.
  final SetValues best;

  ProgressUnit get unit => unitOf(metric);

  /// For a body-weight exercise: the extra weight the best set was done with.
  double get extraKg => metric == ProgressMetric.bodyReps ? best.weightKg : 0;
}

/// Whether a snapshot of the exercise was measured the way [metric] needs:
/// an exercise of one's own may have been changed between workouts, and
/// seconds are not mixed with kilograms. A timed exercise is also kept apart
/// by body weight when [usesBodyWeight] is given.
bool _fits(
  WorkoutExercise exercise,
  ProgressMetric metric,
  bool? usesBodyWeight,
) => switch (metric) {
  ProgressMetric.time =>
    exercise.measure == Measure.time &&
        (usesBodyWeight == null || exercise.usesBodyWeight == usesBodyWeight),
  ProgressMetric.bodyReps =>
    exercise.measure == Measure.reps && exercise.usesBodyWeight,
  _ => exercise.measure == Measure.reps && !exercise.usesBodyWeight,
};

/// The value of [set] for [metric]; null when the set says nothing about it.
double? _value(SetValues set, ProgressMetric metric) => switch (metric) {
  ProgressMetric.estimatedMax => estimatedMaxKg(set),
  ProgressMetric.weight =>
    set.weightKg > 0 && set.reps != null ? set.weightKg : null,
  ProgressMetric.reps ||
  ProgressMetric.bodyReps => (set.reps ?? 0) >= 1 ? set.reps!.toDouble() : null,
  ProgressMetric.time =>
    (set.seconds ?? 0) >= 1 ? set.seconds!.toDouble() : null,
};

/// Whether [a] is a better set than [b] for [metric].
bool _better(SetValues a, SetValues b, ProgressMetric metric) {
  int by(num x, num y) => x.compareTo(y);
  final order = switch (metric) {
    // Ties go to the heavier weight, then to more reps.
    ProgressMetric.estimatedMax => [
      by(estimatedMaxKg(a)!, estimatedMaxKg(b)!),
      by(a.weightKg, b.weightKg),
      by(a.reps ?? 0, b.reps ?? 0),
    ],
    // The heaviest set; at the same weight, the one with more reps. For
    // body weight the weight is the extra weight.
    ProgressMetric.weight || ProgressMetric.reps || ProgressMetric.bodyReps => [
      by(a.weightKg, b.weightKg),
      by(a.reps ?? 0, b.reps ?? 0),
    ],
    ProgressMetric.time => [by(a.seconds ?? 0, b.seconds ?? 0)],
  };
  return (order.firstWhere((c) => c != 0, orElse: () => 0)) > 0;
}

/// One point per completed workout that has a recorded set of the exercise
/// fitting [metric] (and, for time, [usesBodyWeight]). The estimate takes
/// only the first load of a drop set, done fresh; the heaviest weight and
/// time take every stage.
List<ProgressPoint> progressFor(
  String exerciseId,
  Iterable<Workout> workouts, {
  required ProgressMetric metric,
  bool? usesBodyWeight,
}) {
  final points = <ProgressPoint>[];
  for (final workout in workouts.where((w) => w.isCompleted)) {
    SetValues? best;
    for (final exercise in workout.exercises) {
      if (exercise.exerciseId != exerciseId ||
          !_fits(exercise, metric, usesBodyWeight)) {
        continue;
      }
      for (final set in exercise.sets) {
        final facts = metric == ProgressMetric.estimatedMax
            ? [?set.fact]
            : set.facts;
        for (final fact in facts) {
          if (_value(fact, metric) == null) continue;
          if (best == null || _better(fact, best, metric)) best = fact;
        }
      }
    }
    if (best != null) {
      points.add(
        ProgressPoint(
          at: performedAt(workout),
          workoutId: workout.id,
          metric: metric,
          value: _value(best, metric)!,
          best: best,
        ),
      );
    }
  }
  return points..sort((a, b) => a.at.compareTo(b.at));
}

/// An exercise on the progress tab.
class ExerciseProgress {
  const ExerciseProgress({
    required this.exerciseId,
    required this.name,
    required this.measure,
    required this.usesBodyWeight,
    required this.metrics,
  });

  final String exerciseId;

  /// The name it was last recorded with.
  final String name;
  final Measure measure;
  final bool usesBodyWeight;

  /// The metrics that have points, the main one first; never empty.
  final Map<ProgressMetric, List<ProgressPoint>> metrics;

  ProgressMetric get mainMetric => metrics.keys.first;
  List<ProgressPoint> get points => metrics[mainMetric]!;
}

/// The exercise as it was last recorded, with the metrics that fit it.
ExerciseProgress? _progressOf(
  WorkoutExercise latest,
  Iterable<Workout> workouts,
) {
  final metrics = {
    for (final metric in metricsFor(
      latest.measure,
      usesBodyWeight: latest.usesBodyWeight,
    ))
      metric: progressFor(
        latest.exerciseId,
        workouts,
        metric: metric,
        usesBodyWeight: latest.usesBodyWeight,
      ),
  }..removeWhere((_, points) => points.isEmpty);
  if (metrics.isEmpty) return null;
  return ExerciseProgress(
    exerciseId: latest.exerciseId,
    name: latest.name,
    measure: latest.measure,
    usesBodyWeight: latest.usesBodyWeight,
    metrics: metrics,
  );
}

/// Exercises with points, most recently done first.
List<ExerciseProgress> progressOverview(Iterable<Workout> workouts) => [
  for (final latest in _latestRecorded(workouts).values)
    ?_progressOf(latest, workouts),
];

/// One exercise's progress; null when it has no points.
ExerciseProgress? exerciseProgress(
  String exerciseId,
  Iterable<Workout> workouts,
) => switch (_latestRecorded(workouts)[exerciseId]) {
  final latest? => _progressOf(latest, workouts),
  null => null,
};

/// The latest snapshot with a result of each exercise, most recently done
/// first.
Map<String, WorkoutExercise> _latestRecorded(Iterable<Workout> workouts) {
  final sorted = workouts.where((w) => w.isCompleted).toList()
    ..sort((a, b) => performedAt(b).compareTo(performedAt(a)));
  final latest = <String, WorkoutExercise>{};
  for (final workout in sorted) {
    for (final exercise in workout.exercises) {
      if (exercise.hasFact) {
        latest.putIfAbsent(exercise.exerciseId, () => exercise);
      }
    }
  }
  return latest;
}
