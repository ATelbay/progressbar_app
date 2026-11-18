import 'models.dart';
import 'workout_logic.dart';

/// Groups keep their first position; repeated catalog exercises remain distinct.
List<List<WorkoutExercise>> executionGroups(List<WorkoutExercise> exercises) {
  final groups = <List<WorkoutExercise>>[];
  final supersets = <String, List<WorkoutExercise>>{};
  for (final e in exercises) {
    if (e.executionMode == ExecutionMode.superset && e.groupId != null) {
      final group = supersets[e.groupId];
      if (group != null) {
        group.add(e);
        continue;
      }
      final created = <WorkoutExercise>[e];
      supersets[e.groupId!] = created;
      groups.add(created);
    } else {
      groups.add([e]);
    }
  }
  return groups;
}

bool executionFinished(WorkoutExercise e) =>
    e.executionComplete ||
    (e.sets.isNotEmpty &&
        e.sets.every(
          (s) => e.executionMode == ExecutionMode.dropSet
              ? s.dropComplete
              : s.fact != null,
        ));

/// Full supersets are entered round by round, including uneven old plans.
({WorkoutExercise exercise, WorkoutSet set})? nextGroupSet(
  List<WorkoutExercise> group,
) {
  final count = group.fold(0, (n, e) => n > e.sets.length ? n : e.sets.length);
  for (var round = 0; round < count; round++) {
    for (final e in group) {
      if (round >= e.sets.length) continue;
      final s = e.sets[round];
      if (e.executionMode == ExecutionMode.dropSet
          ? !s.dropComplete
          : s.fact == null) {
        return (exercise: e, set: s);
      }
    }
  }
  return null;
}

int nextDropStage(WorkoutSet set) {
  if (set.fact == null) return 0;
  final missing = set.drops.indexWhere((d) => d.fact == null);
  return missing < 0 ? set.drops.length + 1 : missing + 1;
}

/// Summary entry is available only for equal results. Merely switching views
/// must never flatten different loads or reductions into one template.
///
/// A superset is summarized with one number of rounds, so its exercises that
/// have results must have the same number of them: otherwise the summary
/// would add a round to one of them that was never done, or drop one that was.
bool canSummarizeExecution(List<WorkoutExercise> group) {
  final counts = {
    for (final e in group)
      if (e.hasFact) e.sets.where((s) => s.fact != null).length,
  };
  return counts.length <= 1 && group.every(_uniformResults);
}

bool _uniformResults(WorkoutExercise e) {
  final recorded = e.sets.where((s) => s.fact != null).toList();
  if (recorded.isEmpty) return true;
  final first = recorded.first;
  return recorded.every(
    (s) =>
        s.fact == first.fact &&
        s.drops.where((d) => d.fact != null).length ==
            first.drops.where((d) => d.fact != null).length &&
        _sameValues(
          s.drops.map((d) => d.fact).toList(),
          first.drops.map((d) => d.fact).toList(),
        ),
  );
}

bool _sameValues(List<SetValues?> a, List<SetValues?> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => a[i] == b[i]).every((v) => v);

Workout _replace(Workout workout, WorkoutExercise exercise, DateTime now) =>
    workout.copyWith(
      editedAt: workout.isCompleted ? now : null,
      exercises: [
        for (final e in workout.exercises) e.id == exercise.id ? exercise : e,
      ],
    );

void _validate(SetValues value) {
  final count = value.reps ?? value.seconds;
  if (count == null ||
      count < 1 ||
      count > 999 ||
      !isValidWeight(value.weightKg) ||
      (value.reps != null && value.seconds != null)) {
    throw ArgumentError.value(value);
  }
}

Workout recordDropStage(
  Workout workout,
  String exerciseId,
  String setId, {
  required int stage,
  required SetValues fact,
  required IdGenerator newId,
  required DateTime now,
  bool finish = false,
  double? rpe,
}) {
  _validate(fact);
  if (rpe != null && !isValidRpe(rpe)) throw ArgumentError.value(rpe);
  final e = workout.exercises.firstWhere((e) => e.id == exerciseId);
  if (e.executionMode != ExecutionMode.dropSet) {
    throw StateError('Not a drop set');
  }
  final set = e.sets.firstWhere((s) => s.id == setId);
  if (stage < 0 || stage > set.drops.length + 1) throw RangeError.value(stage);
  if (stage > 0 &&
      (set.fact == null ||
          set.drops.take(stage - 1).any((d) => d.fact == null))) {
    throw StateError('Record the preceding stage first');
  }
  // Correcting a stage of a drop set that was already finished leaves it
  // finished: only recording a new stage or ending early changes that.
  final correcting = stage == 0
      ? set.fact != null
      : stage <= set.drops.length && set.drops[stage - 1].fact != null;
  final stillDone = !finish && correcting && set.dropComplete;
  final drops = [...set.drops];
  if (stage > 0) {
    if (stage > drops.length) {
      drops.add(DropStage(id: newId(), fact: fact));
    } else {
      final old = drops[stage - 1];
      drops[stage - 1] = DropStage(id: old.id, plan: old.plan, fact: fact);
    }
  }
  if (finish) {
    for (var i = drops.length - 1; i >= stage; i--) {
      final later = drops[i];
      if (later.plan == null) {
        drops.removeAt(i);
      } else {
        drops[i] = DropStage(id: later.id, plan: later.plan);
      }
    }
  }
  final updated = WorkoutSet(
    id: set.id,
    plan: set.plan,
    fact: stage == 0 ? fact : set.fact,
    rpe: rpe ?? set.rpe,
    drops: drops,
    dropComplete: finish || stillDone,
  );
  return _replace(
    workout,
    e.withSets([
      for (final s in e.sets) s.id == setId ? updated : s,
    ], executionComplete: stillDone && e.executionComplete),
    now,
  );
}

/// One template is expanded into logical sets. Missing planned stages stay
/// present without a fact, so ending early is visible in plan/fact history.
Workout recordDropSummary(
  Workout workout,
  String exerciseId, {
  required int setCount,
  required List<SetValues> stages,
  required IdGenerator newId,
  required DateTime now,
}) {
  if (setCount < 1 || setCount > 20 || stages.isEmpty) {
    throw ArgumentError('Empty drop set');
  }
  stages.forEach(_validate);
  final e = workout.exercises.firstWhere((e) => e.id == exerciseId);
  if (e.executionMode != ExecutionMode.dropSet) {
    throw StateError('Not a drop set');
  }
  final planned = e.sets.where((s) => s.plan != null).toList();
  final extras = e.sets.where((s) => s.plan == null).toList();
  final old = [...planned, ...extras];
  final count = planned.length > setCount ? planned.length : setCount;
  return _replace(
    workout,
    e.withSets([
      for (var i = 0; i < count; i++)
        _dropTemplate(
          i < old.length ? old[i] : WorkoutSet(id: newId()),
          i < setCount ? stages : const [],
          newId,
        ),
    ], executionComplete: true),
    now,
  );
}

WorkoutSet _dropTemplate(
  WorkoutSet old,
  List<SetValues> stages,
  IdGenerator newId,
) {
  final planned = old.drops.where((d) => d.plan != null).toList();
  final extra = old.drops.where((d) => d.plan == null).toList();
  final all = [...planned, ...extra];
  final length = planned.length > stages.length - 1
      ? planned.length
      : stages.length - 1;
  return WorkoutSet(
    id: old.id,
    plan: old.plan,
    fact: stages.firstOrNull,
    dropComplete: stages.isNotEmpty,
    drops: [
      for (var i = 0; i < length; i++)
        DropStage(
          id: i < all.length ? all[i].id : newId(),
          plan: i < all.length ? all[i].plan : null,
          fact: i + 1 < stages.length ? stages[i + 1] : null,
        ),
    ],
  );
}

Workout addExecutionRound(
  Workout workout,
  List<WorkoutExercise> group, {
  required IdGenerator newId,
  required DateTime now,
}) => workout.copyWith(
  editedAt: workout.isCompleted ? now : null,
  exercises: [
    for (final e in workout.exercises)
      group.any((g) => g.id == e.id)
          ? e.withSets([
              ...e.sets,
              WorkoutSet(id: newId()),
            ], executionComplete: false)
          : e,
  ],
);

Workout finishExecutionGroup(Workout workout, List<WorkoutExercise> group) =>
    workout.copyWith(
      exercises: [
        for (final e in workout.exercises)
          group.any((member) => member.id == e.id)
              ? e.withSets(e.sets, executionComplete: true)
              : e,
      ],
    );

/// Changing execution style is possible before entry. Results cannot be
/// silently erased by regrouping or converting a recorded drop set.
Workout configureExecution(
  Workout workout,
  List<String> ids,
  ExecutionMode mode, {
  required IdGenerator newId,
  required DateTime now,
  int setCount = 3,
}) {
  if (ids.isEmpty ||
      ids.toSet().length != ids.length ||
      setCount < 1 ||
      setCount > 20 ||
      (mode == ExecutionMode.superset && ids.length < 2) ||
      (mode != ExecutionMode.superset && ids.length != 1)) {
    throw ArgumentError('Invalid group');
  }
  final selected = workout.exercises.where((e) => ids.contains(e.id)).toList();
  if (selected.length != ids.length ||
      selected.any(
        (e) => e.hasFact || e.executionMode == ExecutionMode.superset,
      )) {
    throw StateError('Only unrecorded, ungrouped exercises can be configured');
  }
  final groupId = mode == ExecutionMode.superset ? newId() : null;
  return workout.copyWith(
    editedAt: workout.isCompleted ? now : null,
    exercises: [
      for (final e in workout.exercises)
        !ids.contains(e.id)
            ? e
            : WorkoutExercise(
                id: e.id,
                exerciseId: e.exerciseId,
                name: e.name,
                measure: e.measure,
                usesBodyWeight: e.usesBodyWeight,
                note: e.note,
                executionMode: mode,
                groupId: groupId,
                planExecutionMode: e.planExecutionMode,
                planGroupId: e.planGroupId,
                sets: e.sets.isNotEmpty
                    ? e.sets
                    : [
                        for (var i = 0; i < setCount; i++)
                          WorkoutSet(id: newId()),
                      ],
              ),
    ],
  );
}
