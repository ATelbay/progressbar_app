import 'models.dart';

typedef IdGenerator = String Function();

/// Weight is in kilograms, 0–999.75 in steps of 0.25.
bool isValidWeight(double kg) =>
    kg >= 0 && kg <= 999.75 && (kg * 4) == (kg * 4).roundToDouble();

/// Perceived effort is 1–10 in steps of 0.5.
bool isValidRpe(double rpe) =>
    rpe >= 1 && rpe <= 10 && (rpe * 2) == (rpe * 2).roundToDouble();

/// The coach who supervises a workout started now: the trainee's active coach.
String? activeCoachOf(String traineeId, Iterable<CoachLink> links) {
  for (final link in links) {
    if (link.traineeId == traineeId && link.status == LinkStatus.active) {
      return link.coachId;
    }
  }
  return null;
}

/// Whether [coachId] may see [workout]. An active or read-only coach sees every
/// workout of the trainee; a removed coach sees none.
bool coachCanSee(String coachId, Workout workout, Iterable<CoachLink> links) =>
    links.any(
      (l) =>
          l.coachId == coachId &&
          l.traineeId == workout.traineeId &&
          l.status != LinkStatus.removed,
    );

/// Starts a workout. With a [day] the plan is copied in full, so later changes
/// to the program do not touch this workout. Without one the workout starts
/// empty and exercises are added as the trainee goes.
Workout startWorkout({
  required String id,
  required String traineeId,
  required DateTime now,
  required IdGenerator newId,
  required Map<String, Exercise> catalog,
  required String languageCode,
  Program? program,
  ProgramDay? day,
  String? supervisorCoachId,
  double? bodyWeightKg,
}) {
  return Workout(
    id: id,
    traineeId: traineeId,
    supervisorCoachId: supervisorCoachId,
    programId: program?.id,
    programName: program?.name,
    dayName: day?.name,
    status: WorkoutStatus.inProgress,
    startedAt: now,
    bodyWeightKg: bodyWeightKg,
    exercises: [
      for (final planned in day?.exercises ?? const <ProgramExercise>[])
        _snapshot(
          catalog[planned.exerciseId]!,
          languageCode,
          newId,
          plan: planned.sets,
          note: planned.note,
        ),
    ],
  );
}

/// Adds an exercise that was not in the plan (or any exercise in a workout
/// without a program).
Workout addExercise(
  Workout workout,
  Exercise exercise, {
  required String languageCode,
  required IdGenerator newId,
  required DateTime now,
}) => _touch(workout, now).copyWith(
  exercises: [...workout.exercises, _snapshot(exercise, languageCode, newId)],
);

WorkoutExercise _snapshot(
  Exercise exercise,
  String languageCode,
  IdGenerator newId, {
  List<SetValues> plan = const [],
  String? note,
}) => WorkoutExercise(
  id: newId(),
  exerciseId: exercise.id,
  name: exercise.nameFor(languageCode),
  measure: exercise.measure,
  usesBodyWeight: exercise.usesBodyWeight,
  note: note,
  sets: [for (final p in plan) WorkoutSet(id: newId(), plan: p)],
);

/// Summary entry: «[setCount] sets of [fact]». It is only a way of typing; the
/// result is stored per set. The first [setCount] sets get [fact], planned sets
/// beyond that are left without a fact, and sets beyond the plan are added as
/// extra ones. Extra sets no longer needed are dropped.
Workout recordSummary(
  Workout workout,
  String workoutExerciseId, {
  required int setCount,
  required SetValues fact,
  required IdGenerator newId,
  required DateTime now,
}) {
  if (setCount < 1) throw ArgumentError.value(setCount, 'setCount');
  _checkValues(fact);
  return _updateExercise(workout, workoutExerciseId, now, (exercise) {
    final planned = exercise.sets.where((s) => !s.isExtra).toList();
    final extras = exercise.sets.where((s) => s.isExtra).toList();
    return [
      for (var i = 0; i < planned.length; i++)
        planned[i].withFact(i < setCount ? fact : null),
      for (var i = planned.length; i < setCount; i++)
        WorkoutSet(
          id: i - planned.length < extras.length
              ? extras[i - planned.length].id
              : newId(),
          fact: fact,
        ),
    ];
  });
}

/// Per-set entry: records or corrects one set. A null [fact] clears it.
Workout recordSet(
  Workout workout,
  String workoutExerciseId,
  String setId, {
  required SetValues? fact,
  required DateTime now,
  double? rpe,
}) {
  if (fact != null) _checkValues(fact);
  if (rpe != null && !isValidRpe(rpe)) throw ArgumentError.value(rpe, 'rpe');
  return _updateExercise(workout, workoutExerciseId, now, (exercise) {
    if (!exercise.sets.any((s) => s.id == setId)) {
      throw StateError('No set $setId in exercise $workoutExerciseId');
    }
    return [
      for (final s in exercise.sets)
        s.id == setId ? s.withFact(fact, rpe: rpe) : s,
    ];
  });
}

/// Adds a set that was not in the plan.
Workout addExtraSet(
  Workout workout,
  String workoutExerciseId, {
  required SetValues fact,
  required IdGenerator newId,
  required DateTime now,
  double? rpe,
}) {
  _checkValues(fact);
  return _updateExercise(
    workout,
    workoutExerciseId,
    now,
    (exercise) => [
      ...exercise.sets,
      WorkoutSet(id: newId(), fact: fact, rpe: rpe),
    ],
  );
}

/// Removes an extra set. Planned sets cannot be removed, only left empty.
Workout removeExtraSet(
  Workout workout,
  String workoutExerciseId,
  String setId, {
  required DateTime now,
}) => _updateExercise(workout, workoutExerciseId, now, (exercise) {
  final target = exercise.sets.firstWhere((s) => s.id == setId);
  if (!target.isExtra) throw StateError('Set $setId is part of the plan');
  return exercise.sets.where((s) => s.id != setId).toList();
});

Workout completeWorkout(Workout workout, {required DateTime now}) {
  if (workout.isCompleted) throw StateError('Workout is already completed');
  return workout.copyWith(status: WorkoutStatus.completed, completedAt: now);
}

void _checkValues(SetValues v) {
  if (!isValidWeight(v.weightKg)) throw ArgumentError.value(v.weightKg, 'kg');
  if ((v.reps == null) == (v.seconds == null)) {
    throw ArgumentError('A set has either reps or seconds');
  }
  if ((v.reps ?? v.seconds)! < 0) throw ArgumentError('Negative value');
}

/// A change to a completed workout marks it as edited after completion.
Workout _touch(Workout workout, DateTime now) =>
    workout.isCompleted ? workout.copyWith(editedAt: now) : workout;

Workout _updateExercise(
  Workout workout,
  String workoutExerciseId,
  DateTime now,
  List<WorkoutSet> Function(WorkoutExercise) update,
) {
  if (!workout.exercises.any((e) => e.id == workoutExerciseId)) {
    throw StateError('No exercise $workoutExerciseId in workout ${workout.id}');
  }
  return _touch(workout, now).copyWith(
    exercises: [
      for (final e in workout.exercises)
        e.id == workoutExerciseId ? e.withSets(update(e)) : e,
    ],
  );
}

enum DeviationKind { asPlanned, below, above, extra, missing }

/// Difference between plan and fact for one set.
class SetDeviation {
  const SetDeviation(this.kind, {this.weightKg = 0, this.count = 0});

  final DeviationKind kind;

  /// Fact minus plan, in kilograms.
  final double weightKg;

  /// Fact minus plan, in reps or seconds.
  final int count;
}

/// Below plan if either weight or count fell short, even when the other one
/// went up; above plan only when nothing fell short and something went up.
SetDeviation compareSet(WorkoutSet set) {
  final plan = set.plan, fact = set.fact;
  if (plan == null) return const SetDeviation(DeviationKind.extra);
  if (fact == null) return const SetDeviation(DeviationKind.missing);
  final weight = fact.weightKg - plan.weightKg;
  final count =
      (fact.reps ?? fact.seconds ?? 0) - (plan.reps ?? plan.seconds ?? 0);
  final kind = weight < 0 || count < 0
      ? DeviationKind.below
      : weight > 0 || count > 0
      ? DeviationKind.above
      : DeviationKind.asPlanned;
  return SetDeviation(kind, weightKg: weight, count: count);
}

/// Worst case across the planned sets of an exercise: any missing or
/// below-plan set makes the whole exercise below plan.
DeviationKind compareExercise(WorkoutExercise exercise) {
  final kinds = exercise.sets
      .where((s) => !s.isExtra)
      .map((s) => compareSet(s).kind)
      .toSet();
  if (kinds.isEmpty) return DeviationKind.extra;
  if (kinds.every((k) => k == DeviationKind.missing)) {
    return DeviationKind.missing;
  }
  if (kinds.contains(DeviationKind.below) ||
      kinds.contains(DeviationKind.missing)) {
    return DeviationKind.below;
  }
  if (kinds.contains(DeviationKind.above)) return DeviationKind.above;
  return DeviationKind.asPlanned;
}

enum ProgressUnit { kilograms, seconds, reps }

class ProgressPoint {
  const ProgressPoint(this.at, this.value, this.unit, {this.extraKg = 0});

  final DateTime at;
  final double value;
  final ProgressUnit unit;

  /// For a body-weight exercise: the extra weight the best set was done with.
  final double extraKg;
}

/// Load actually moved in a set. Body weight counts only for exercises that
/// use it (pull-ups, dips); for everything else it is just the bar weight.
double totalLoadKg(Workout workout, WorkoutExercise exercise, SetValues set) =>
    set.weightKg + (exercise.usesBodyWeight ? workout.bodyWeightKg ?? 0 : 0);

/// One point per completed workout that has a recorded set of the exercise.
/// A weighted exercise is tracked by its heaviest weight and a timed one by
/// its longest time. A body-weight exercise is tracked by reps: the most reps
/// done at the heaviest extra weight of that workout.
List<ProgressPoint> progressFor(String exerciseId, Iterable<Workout> workouts) {
  final points = <ProgressPoint>[];
  for (final workout in workouts.where((w) => w.isCompleted)) {
    ProgressPoint? best;
    for (final exercise in workout.exercises) {
      if (exercise.exerciseId != exerciseId) continue;
      for (final fact in exercise.sets.map((s) => s.fact).nonNulls) {
        final point = _pointFor(workout.completedAt!, exercise, fact);
        if (best == null ||
            point.extraKg > best.extraKg ||
            (point.extraKg == best.extraKg && point.value > best.value)) {
          best = point;
        }
      }
    }
    if (best != null) points.add(best);
  }
  return points..sort((a, b) => a.at.compareTo(b.at));
}

ProgressPoint _pointFor(DateTime at, WorkoutExercise exercise, SetValues fact) {
  if (exercise.measure == Measure.time) {
    return ProgressPoint(
      at,
      (fact.seconds ?? 0).toDouble(),
      ProgressUnit.seconds,
    );
  }
  if (exercise.usesBodyWeight) {
    return ProgressPoint(
      at,
      (fact.reps ?? 0).toDouble(),
      ProgressUnit.reps,
      extraKg: fact.weightKg,
    );
  }
  return ProgressPoint(at, fact.weightKg, ProgressUnit.kilograms);
}

/// What to pre-fill in the entry panel: the latest recorded result for the
/// exercise, falling back to the plan.
SetValues? prefillFor(
  WorkoutExercise exercise,
  Iterable<Workout> earlierWorkouts,
) {
  final sorted = earlierWorkouts.where((w) => w.isCompleted).toList()
    ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
  for (final workout in sorted) {
    for (final past in workout.exercises) {
      if (past.exerciseId != exercise.exerciseId) continue;
      final facts = past.sets.map((s) => s.fact).nonNulls;
      if (facts.isNotEmpty) return facts.last;
    }
  }
  return exercise.sets.where((s) => !s.isExtra).firstOrNull?.plan;
}

/// How hard a set felt, as the user picks it: three answers instead of the
/// full 1–10 scale. Each is stored as one number on that scale.
enum Effort {
  /// 7 or less: could have done more.
  more(7),

  /// 8–9: a rep or two left.
  some(8.5),

  /// 10: nothing left.
  none(10);

  const Effort(this.rpe);

  final double rpe;

  /// The answer a stored value falls under, also one typed on the full scale.
  static Effort of(double rpe) => rpe >= 10
      ? none
      : rpe > 7
      ? some
      : more;
}

/// Steps of the entry panel buttons; finer weights are typed on the keypad.
const weightStepKg = 2.5;
const secondsStep = 5;
const maxWeightKg = 999.75;

/// Exercises that already have at least one recorded set.
int recordedCount(Workout workout) =>
    workout.exercises.where((e) => e.hasFact).length;

/// The exercise to record next: the first one without a result.
WorkoutExercise? nextExercise(Workout workout) =>
    workout.exercises.where((e) => !e.hasFact).firstOrNull;

/// The set to record next in per-set entry: the first one without a fact.
WorkoutSet? nextSet(WorkoutExercise exercise) =>
    exercise.sets.where((s) => s.fact == null).firstOrNull;

/// «3 × 8 × 60»: [count] sets and, when they are all alike, their [values].
class SetsSummary {
  const SetsSummary(this.count, this.values);

  final int count;
  final SetValues? values;
}

SetsSummary? summarizeSets(Iterable<SetValues> sets) {
  final all = sets.toList();
  if (all.isEmpty) return null;
  return SetsSummary(
    all.length,
    all.every((v) => v == all.first) ? all.first : null,
  );
}

SetsSummary? planSummary(WorkoutExercise exercise) =>
    summarizeSets(exercise.sets.map((s) => s.plan).nonNulls);

SetsSummary? factSummary(WorkoutExercise exercise) =>
    summarizeSets(exercise.sets.map((s) => s.fact).nonNulls);

/// What was recorded for this exercise in the latest completed workout.
SetsSummary? lastResult(
  WorkoutExercise exercise,
  Iterable<Workout> earlierWorkouts,
) {
  final sorted = earlierWorkouts.where((w) => w.isCompleted).toList()
    ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
  for (final workout in sorted) {
    for (final past in workout.exercises) {
      if (past.exerciseId != exercise.exerciseId) continue;
      final summary = factSummary(past);
      if (summary != null) return summary;
    }
  }
  return null;
}

/// Makes stored values fit how the exercise is measured now.
SetValues _fit(SetValues? values, Measure measure) => measure == Measure.time
    ? SetValues(seconds: values?.seconds ?? 30, weightKg: values?.weightKg ?? 0)
    : SetValues(reps: values?.reps ?? 10, weightKg: values?.weightKg ?? 0);

/// What summary entry opens with. A recorded exercise opens with its own
/// result. Otherwise the values are last time's result, falling back to the
/// plan; the number of sets is the plan's, or without a plan the one the user
/// entered last ([lastSetCount]).
({int setCount, SetValues values}) summaryDraft(
  WorkoutExercise exercise,
  Iterable<Workout> earlierWorkouts, {
  int? lastSetCount,
}) {
  final fact = factSummary(exercise);
  if (fact != null) {
    final values =
        fact.values ?? exercise.sets.map((s) => s.fact).nonNulls.last;
    return (setCount: fact.count, values: _fit(values, exercise.measure));
  }
  final planned = exercise.sets.where((s) => !s.isExtra).length;
  return (
    setCount: planned > 0 ? planned : lastSetCount ?? 3,
    values: _fit(prefillFor(exercise, earlierWorkouts), exercise.measure),
  );
}

/// What per-set entry opens with for [set]: its own fact when correcting,
/// else the previous set of this exercise, its plan, or last time's result.
SetValues setDraft(
  WorkoutExercise exercise,
  WorkoutSet set,
  Iterable<Workout> earlierWorkouts,
) {
  final before = exercise.sets
      .takeWhile((s) => s.id != set.id)
      .map((s) => s.fact)
      .nonNulls
      .lastOrNull;
  return _fit(
    set.fact ?? before ?? set.plan ?? prefillFor(exercise, earlierWorkouts),
    exercise.measure,
  );
}

double stepWeight(double kg, double by) =>
    (kg + by).clamp(0, maxWeightKg).toDouble();

/// A weight typed on the keypad, with a comma or a dot; null when it is not a
/// weight the app accepts.
double? parseWeight(String text) {
  final kg = double.tryParse(text.trim().replaceAll(',', '.'));
  return kg != null && isValidWeight(kg) ? kg : null;
}

/// Whether the workout was started from a program day.
bool hasPlan(Workout workout) =>
    workout.exercises.any((e) => e.sets.any((s) => !s.isExtra));

/// How a workout went against its plan: exercises that fell short and
/// exercises left without any result.
({int below, int skipped}) planVerdict(Workout workout) {
  final kinds = workout.exercises.map(compareExercise);
  return (
    below: kinds.where((k) => k == DeviationKind.below).length,
    skipped: kinds.where((k) => k == DeviationKind.missing).length,
  );
}
