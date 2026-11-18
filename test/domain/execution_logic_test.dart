import 'package:flutter_test/flutter_test.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/domain/program_logic.dart';
import 'package:progressbar_app/domain/progress_logic.dart';
import 'package:progressbar_app/domain/workout_logic.dart';
import 'package:progressbar_app/domain/execution_logic.dart';
import 'package:progressbar_app/data/firestore_codec.dart';

const initial = SetValues(reps: 10, weightKg: 60);
const reduction = SetValues(reps: 8, weightKg: 45);
const catalog = {
  'a': Exercise(id: 'a', names: {'en': 'Lunges'}, muscleGroup: 'legs'),
  'b': Exercise(id: 'b', names: {'en': 'Squats'}, muscleGroup: 'legs'),
};
final now = DateTime(2026, 10, 13);
void main() {
  var id = 0;
  String newId() => '${id++}';
  Workout start(List<ProgramExercise> exercises) => startWorkout(
    id: 'w',
    traineeId: 'me',
    now: now,
    newId: newId,
    catalog: catalog,
    languageCode: 'en',
    day: ProgramDay(id: 'd', name: 'Legs', exercises: exercises),
  );
  test(
    'supersets snapshot metadata and advance round by round after reload',
    () {
      var w = start([
        for (final key in ['a', 'b'])
          ProgramExercise(
            id: key,
            exerciseId: key,
            sets: [initial, initial],
            executionMode: ExecutionMode.superset,
            groupId: 'pair',
          ),
      ]);
      final order = <String>[];
      for (var i = 0; i < 4; i++) {
        final position = nextGroupSet(executionGroups(w.exercises).single)!;
        order.add(position.exercise.exerciseId);
        w = recordSet(
          w,
          position.exercise.id,
          position.set.id,
          fact: initial,
          now: now,
        );
        w = workoutFromMap(w.id, Map<String, dynamic>.from(workoutToMap(w)));
      }
      expect(order, ['a', 'b', 'a', 'b']);
      expect(nextExercise(w), isNull);
      expect(nextGroupSet(w.exercises), isNull);
    },
  );
  test('a drop set resumes at the missing stage, supports extra stages and early finish', () {
    var w = start([
      const ProgramExercise(
        id: 'a',
        exerciseId: 'a',
        sets: [initial, initial],
        executionMode: ExecutionMode.dropSet,
        dropStages: [reduction, reduction],
      ),
    ]);
    final e = w.exercises.single;
    w = recordDropStage(
      w,
      e.id,
      e.sets.first.id,
      stage: 0,
      fact: initial,
      newId: newId,
      now: now,
    );
    w = workoutFromMap(w.id, Map<String, dynamic>.from(workoutToMap(w)));
    expect(nextDropStage(w.exercises.single.sets.first), 1);
    w = recordDropStage(
      w,
      e.id,
      e.sets.first.id,
      stage: 1,
      fact: reduction,
      newId: newId,
      now: now,
      finish: true,
    );
    expect(w.exercises.single.sets.first.drops.last.fact, isNull);
    expect(compareExercise(w, w.exercises.single), DeviationKind.below);
    expect(nextGroupSet(w.exercises)!.set.id, e.sets.last.id);
    w = recordDropSummary(
      w,
      e.id,
      setCount: 2,
      stages: [initial, reduction, reduction, initial],
      newId: newId,
      now: now,
    );
    expect(w.exercises.single.sets.length, 2);
    expect(w.exercises.single.sets.first.drops.length, 3);
    expect(w.exercises.single.sets.first.drops.last.plan, isNull);
    expect(nextExercise(w), isNull);
  });
  test('different results cannot be flattened by switching to summary', () {
    var w = start([
      const ProgramExercise(
        id: 'a',
        exerciseId: 'a',
        sets: [initial, initial],
        executionMode: ExecutionMode.dropSet,
      ),
    ]);
    final e = w.exercises.single;
    w = recordDropStage(
      w,
      e.id,
      e.sets.first.id,
      stage: 0,
      fact: initial,
      newId: newId,
      now: now,
      finish: true,
    );
    w = recordDropStage(
      w,
      e.id,
      e.sets.last.id,
      stage: 0,
      fact: reduction,
      newId: newId,
      now: now,
      finish: true,
    );
    expect(canSummarizeExecution(w.exercises), isFalse);
    expect(
      () => recordSummary(
        w,
        e.id,
        setCount: 2,
        fact: initial,
        newId: newId,
        now: now,
      ),
      throwsStateError,
    );
    expect(
      () => configureExecution(
        w,
        [e.id],
        ExecutionMode.ordinary,
        newId: newId,
        now: now,
      ),
      throwsStateError,
    );
  });
  test(
    'planning a group replaces it in place and round trips with reductions',
    () {
      const p = Program(
        id: 'p',
        authorId: 'me',
        name: 'Plan',
        days: [
          ProgramDay(
            id: 'd',
            name: 'Day',
            exercises: [
              ProgramExercise(id: 'old', exerciseId: 'a', sets: [initial]),
              ProgramExercise(id: 'keep', exerciseId: 'b', sets: [initial]),
            ],
          ),
        ],
      );
      final updated = putExecutionPlan(
        p,
        'd',
        replacedIds: ['old'],
        members: [
          const ProgramExercise(
            id: 'old',
            exerciseId: 'a',
            sets: [initial],
            executionMode: ExecutionMode.dropSet,
            dropStages: [reduction],
          ),
        ],
      );
      final decoded = programFromMap(
        p.id,
        Map<String, dynamic>.from(programToMap(updated)),
      );
      expect(decoded.days.single.exercises.map((e) => e.id), ['old', 'keep']);
      expect(decoded.days.single.exercises.first.dropStages, [reduction]);
      expect(p.days.single.exercises.first.dropStages, isEmpty);
    },
  );
  test('version one documents remain ordinary exercises', () {
    final map = Map<String, dynamic>.from(
      workoutToMap(
        start([
          const ProgramExercise(id: 'a', exerciseId: 'a', sets: [initial]),
        ]),
      ),
    );
    final exercise = (map['exercises'] as List).single as Map;
    exercise.remove('executionMode');
    exercise.remove('groupId');
    exercise.remove('planExecutionMode');
    exercise.remove('planGroupId');
    exercise.remove('executionComplete');
    map['schemaVersion'] = 1;
    final set = (exercise['sets'] as List).single as Map;
    set.remove('dropComplete');
    set.remove('drops');
    final old = workoutFromMap('w', map);
    expect(old.exercises.single.executionMode, ExecutionMode.ordinary);
    expect(old.exercises.single.sets.single.fact, isNull);
  });
  test('shortening a recorded drop clears later facts and keeps the plan', () {
    var w = start([
      const ProgramExercise(
        id: 'a',
        exerciseId: 'a',
        sets: [initial],
        executionMode: ExecutionMode.dropSet,
        dropStages: [reduction],
      ),
    ]);
    final e = w.exercises.single;
    w = recordDropSummary(
      w,
      e.id,
      setCount: 1,
      stages: [initial, reduction, reduction],
      newId: newId,
      now: now,
    );
    w = recordDropStage(
      w,
      e.id,
      e.sets.single.id,
      stage: 0,
      fact: initial,
      newId: newId,
      now: now,
      finish: true,
    );
    expect(w.exercises.single.sets.single.drops.length, 1);
    expect(w.exercises.single.sets.single.drops.single.fact, isNull);
    expect(w.exercises.single.sets.single.drops.single.plan, reduction);
  });
  test('a shorter summary finishes entry and preserves the missing plan', () {
    var w = start([
      const ProgramExercise(
        id: 'a',
        exerciseId: 'a',
        sets: [initial, initial, initial],
        executionMode: ExecutionMode.dropSet,
        dropStages: [reduction],
      ),
    ]);
    w = recordDropSummary(
      w,
      w.exercises.single.id,
      setCount: 1,
      stages: [initial, reduction],
      newId: newId,
      now: now,
    );
    expect(nextExercise(w), isNull);
    expect(w.exercises.single.sets.length, 3);
    expect(w.exercises.single.sets.last.plan, initial);
    expect(w.exercises.single.sets.last.fact, isNull);
    expect(compareExercise(w, w.exercises.single), DeviationKind.below);
    w = workoutFromMap(w.id, Map<String, dynamic>.from(workoutToMap(w)));
    expect(nextExercise(w), isNull);
  });
  test(
    'configuring a workout preserves the original execution plan metadata',
    () {
      final w = start([
        const ProgramExercise(id: 'a', exerciseId: 'a', sets: [initial]),
      ]);
      final changed = configureExecution(
        w,
        [w.exercises.single.id],
        ExecutionMode.dropSet,
        newId: newId,
        now: now,
      );
      expect(changed.exercises.single.executionMode, ExecutionMode.dropSet);
      expect(
        changed.exercises.single.planExecutionMode,
        ExecutionMode.ordinary,
      );
      expect(changed.exercises.single.sets.single.plan, initial);
    },
  );
  test('progress includes all reductions, not only the initial stage', () {
    var w = start([
      const ProgramExercise(
        id: 'a',
        exerciseId: 'a',
        sets: [initial],
        executionMode: ExecutionMode.dropSet,
      ),
    ]);
    w = recordDropSummary(
      w,
      w.exercises.single.id,
      setCount: 1,
      stages: [reduction, initial],
      newId: newId,
      now: now,
    );
    final done = completeWorkout(w, now: now);
    expect(
      progressFor('a', [done], metric: ProgressMetric.weight).single.value,
      60,
    );
    // The estimate takes the first load only: 45 kg × 8, not the 60 kg stage.
    expect(
      progressFor('a', [done], metric: ProgressMetric.estimatedMax).single.best,
      reduction,
    );
  });
  test('a superset with different round counts cannot switch to summary', () {
    var w = start([
      for (final key in ['a', 'b'])
        ProgramExercise(
          id: key,
          exerciseId: key,
          sets: [initial, initial, initial],
          executionMode: ExecutionMode.superset,
          groupId: 'pair',
        ),
    ]);
    void record(int count) {
      for (var i = 0; i < count; i++) {
        final next = nextGroupSet(executionGroups(w.exercises).single)!;
        w = recordSet(
          w,
          next.exercise.id,
          next.set.id,
          fact: initial,
          now: now,
        );
      }
    }

    // Nothing recorded yet, and the first exercise alone: summary is fine.
    expect(canSummarizeExecution(w.exercises), isTrue);
    record(1);
    expect(canSummarizeExecution(w.exercises), isTrue);
    // Equal results, but three rounds of one and two of the other: a summary
    // of three rounds would add a round to the second that was never done.
    record(4);
    expect(w.exercises.map((e) => e.sets.where((s) => s.fact != null).length), [
      3,
      2,
    ]);
    expect(canSummarizeExecution(w.exercises), isFalse);
    record(1);
    expect(canSummarizeExecution(w.exercises), isTrue);
  });
  test('correcting a finished drop set keeps it finished', () {
    var w = start([
      const ProgramExercise(
        id: 'a',
        exerciseId: 'a',
        sets: [initial],
        executionMode: ExecutionMode.dropSet,
        dropStages: [reduction],
      ),
    ]);
    final e = w.exercises.single, set = e.sets.single.id;
    Workout stage(
      Workout w,
      int stage,
      SetValues fact, {
      bool finish = false,
    }) => recordDropStage(
      w,
      e.id,
      set,
      stage: stage,
      fact: fact,
      newId: newId,
      now: now,
      finish: finish,
    );
    w = stage(w, 0, initial);
    expect(w.exercises.single.sets.single.dropComplete, isFalse);
    w = stage(w, 1, reduction, finish: true);
    expect(nextExercise(w), isNull);

    // Only the first load is corrected, the reduction stays as it was.
    const corrected = SetValues(reps: 10, weightKg: 62.5);
    w = stage(w, 0, corrected);
    final done = w.exercises.single.sets.single;
    expect(done.fact, corrected);
    expect(done.drops.single.fact, reduction);
    expect(done.dropComplete, isTrue);
    expect(nextExercise(w), isNull);

    // A summary that deliberately recorded fewer sets than planned stays
    // complete after a correction too.
    var shorter = start([
      const ProgramExercise(
        id: 'a',
        exerciseId: 'a',
        sets: [initial, initial],
        executionMode: ExecutionMode.dropSet,
        dropStages: [reduction],
      ),
    ]);
    final planned = shorter.exercises.single;
    shorter = recordDropSummary(
      shorter,
      planned.id,
      setCount: 1,
      stages: [initial, reduction],
      newId: newId,
      now: now,
    );
    expect(nextExercise(shorter), isNull);
    shorter = recordDropStage(
      shorter,
      planned.id,
      planned.sets.first.id,
      stage: 0,
      fact: corrected,
      newId: newId,
      now: now,
    );
    expect(shorter.exercises.single.executionComplete, isTrue);
    expect(shorter.exercises.single.sets.first.dropComplete, isTrue);
    expect(nextExercise(shorter), isNull);

    // Recording a set that had no result yet resumes entry as before.
    shorter = recordDropStage(
      shorter,
      planned.id,
      planned.sets.last.id,
      stage: 0,
      fact: initial,
      newId: newId,
      now: now,
    );
    expect(shorter.exercises.single.executionComplete, isFalse);
    expect(nextExercise(shorter)?.id, planned.id);
  });
}
