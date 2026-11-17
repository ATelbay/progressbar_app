import 'package:flutter_test/flutter_test.dart';
import 'package:progressbar_app/data/firestore_codec.dart';
import 'package:progressbar_app/domain/execution_logic.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/domain/progress_logic.dart';
import 'package:progressbar_app/domain/workout_logic.dart';

const bench = Exercise(
  id: 'bench',
  names: {'en': 'Bench press'},
  muscleGroup: 'chest',
);
const squat = Exercise(
  id: 'squat',
  names: {'en': 'Squat'},
  muscleGroup: 'legs',
);
const row = Exercise(id: 'row', names: {'en': 'Row'}, muscleGroup: 'back');
const curl = Exercise(id: 'curl', names: {'en': 'Curl'}, muscleGroup: 'arms');
const catalog = {'bench': bench, 'squat': squat, 'row': row, 'curl': curl};
const plan = SetValues(reps: 8, weightKg: 60);
final now = DateTime(2026, 11, 15, 18);

IdGenerator counter() {
  var n = 0;
  return () => 'id${n++}';
}

ProgramExercise planned(
  String exerciseId, {
  ExecutionMode mode = ExecutionMode.ordinary,
  String? groupId,
}) => ProgramExercise(
  id: 'pe-$exerciseId',
  exerciseId: exerciseId,
  sets: const [plan, plan],
  executionMode: mode,
  groupId: groupId,
);

Workout start(List<ProgramExercise> exercises, {IdGenerator? newId}) {
  final program = Program(
    id: 'p',
    authorId: 'me',
    name: 'Strength',
    days: [ProgramDay(id: 'd', name: 'Day', exercises: exercises)],
  );
  return startWorkout(
    id: 'w',
    traineeId: 'me',
    now: now,
    newId: newId ?? counter(),
    catalog: catalog,
    languageCode: 'en',
    program: program,
    day: program.days.single,
  );
}

Workout reload(Workout w) =>
    workoutFromMap(w.id, Map<String, dynamic>.from(workoutToMap(w)));

List<String> names(Workout w) => [for (final e in w.exercises) e.exerciseId];

void main() {
  group('skipping an exercise', () {
    test('moves on to the next one and keeps the plan', () {
      final w = start([planned('bench'), planned('squat')]);
      final skipped = skipExercise(w, w.exercises.first.id, now: now);

      expect(skipped.exercises.first.skipped, isTrue);
      expect(skipped.exercises.first.sets.map((s) => s.plan), [plan, plan]);
      expect(nextExercise(skipped)!.exerciseId, 'squat');
      expect(recordedCount(skipped), 0);
      expect(skippedCount(skipped), 1);
      // In history it is skipped, the same as one left without a result.
      expect(
        compareExercise(skipped, skipped.exercises.first),
        DeviationKind.missing,
      );
      expect(planVerdict(skipped).skipped, 2);
    });

    test('recording a result takes the skip off', () {
      final ids = counter();
      var w = start([planned('bench')], newId: ids);
      final id = w.exercises.single.id;
      w = skipExercise(w, id, now: now);
      w = recordSummary(w, id, setCount: 2, fact: plan, newId: ids, now: now);
      expect(w.exercises.single.skipped, isFalse);

      w = recordSet(
        w,
        id,
        w.exercises.single.sets.first.id,
        fact: null,
        now: now,
      );
      w = recordSet(
        w,
        id,
        w.exercises.single.sets.last.id,
        fact: null,
        now: now,
      );
      w = skipExercise(w, id, now: now);
      w = recordSet(
        w,
        id,
        w.exercises.single.sets.first.id,
        fact: plan,
        now: now,
      );
      expect(w.exercises.single.skipped, isFalse);
    });

    test('is only for an exercise without a result', () {
      final ids = counter();
      var w = start([planned('bench')], newId: ids);
      final id = w.exercises.single.id;
      w = recordSet(
        w,
        id,
        w.exercises.single.sets.first.id,
        fact: plan,
        now: now,
      );
      expect(() => skipExercise(w, id, now: now), throwsStateError);
    });

    test('can be taken back without recording anything', () {
      final w = start([planned('bench'), planned('squat')]);
      final id = w.exercises.first.id;
      final back = unskipExercise(skipExercise(w, id, now: now), id, now: now);
      expect(back.exercises.first.skipped, isFalse);
      expect(nextExercise(back)!.id, id);
    });

    test('skips a superset as a whole and its first result clears it all', () {
      final ids = counter();
      var w = start([
        planned('bench', mode: ExecutionMode.superset, groupId: 'pair'),
        planned('row', mode: ExecutionMode.superset, groupId: 'pair'),
        planned('squat'),
      ], newId: ids);
      w = skipExercise(w, w.exercises[1].id, now: now);
      expect(w.exercises.take(2).map((e) => e.skipped), [true, true]);
      expect(nextExercise(w)!.exerciseId, 'squat');

      final first = w.exercises.first;
      w = recordSet(w, first.id, first.sets.first.id, fact: plan, now: now);
      expect(w.exercises.map((e) => e.skipped), [false, false, false]);
    });

    test('a recorded superset member keeps the group from being skipped', () {
      var w = start([
        planned('bench', mode: ExecutionMode.superset, groupId: 'pair'),
        planned('row', mode: ExecutionMode.superset, groupId: 'pair'),
      ]);
      final row = w.exercises.last;
      w = recordSet(w, row.id, row.sets.first.id, fact: plan, now: now);
      expect(
        () => skipExercise(w, w.exercises.first.id, now: now),
        throwsStateError,
      );
    });

    test('choosing how to do it means it will be done', () {
      final ids = counter();
      var w = startWorkout(
        id: 'free',
        traineeId: 'me',
        now: now,
        newId: ids,
        catalog: catalog,
        languageCode: 'en',
      );
      w = addExercise(w, bench, languageCode: 'en', newId: ids, now: now);
      final id = w.exercises.single.id;
      w = skipExercise(w, id, now: now);
      w = configureExecution(
        w,
        [id],
        ExecutionMode.dropSet,
        newId: ids,
        now: now,
      );
      expect(w.exercises.single.skipped, isFalse);
    });

    test('survives storage; old documents have nothing skipped', () {
      final w = start([planned('bench'), planned('squat')]);
      final skipped = skipExercise(w, w.exercises.first.id, now: now);
      expect(reload(skipped).exercises.map((e) => e.skipped), [true, false]);

      final old = workoutToMap(skipped);
      for (final exercise in old['exercises']! as List) {
        (exercise as Map).remove('skipped');
      }
      old.remove('originalOrder');
      final read = workoutFromMap('w', Map<String, dynamic>.from(old));
      expect(read.exercises.map((e) => e.skipped), [false, false]);
      expect(read.originalOrder, isNull);
    });

    test('a stored skip next to a result is not believed', () {
      var w = start([planned('bench')]);
      final id = w.exercises.single.id;
      w = recordSet(
        w,
        id,
        w.exercises.single.sets.first.id,
        fact: plan,
        now: now,
      );
      final stored = workoutToMap(w);
      ((stored['exercises']! as List).single as Map)['skipped'] = true;
      final read = workoutFromMap('w', Map<String, dynamic>.from(stored));
      expect(read.exercises.single.skipped, isFalse);
    });
  });

  group('rearranging exercises', () {
    test('keeps the order before the first change', () {
      final w = start([planned('bench'), planned('squat'), planned('row')]);
      final once = moveExerciseGroup(w, 2, 0, now: now);
      expect(names(once), ['row', 'bench', 'squat']);
      expect(once.originalOrder, [for (final e in w.exercises) e.id]);

      final twice = moveExerciseGroup(once, 0, 2, now: now);
      expect(names(twice), ['bench', 'squat', 'row']);
      expect(twice.originalOrder, once.originalOrder);
      expect(reload(twice).originalOrder, once.originalOrder);
    });

    test('the next exercise follows the new order', () {
      final w = start([planned('bench'), planned('squat')]);
      expect(nextExercise(w)!.exerciseId, 'bench');
      expect(
        nextExercise(moveExerciseGroup(w, 1, 0, now: now))!.exerciseId,
        'squat',
      );
    });

    test('moves a superset as a whole, even one split by older plans', () {
      final w = start([
        planned('bench', mode: ExecutionMode.superset, groupId: 'pair'),
        planned('squat'),
        planned('row', mode: ExecutionMode.superset, groupId: 'pair'),
        planned('curl'),
      ]);
      expect(groupOrder(w).length, 3);
      final moved = moveExerciseGroup(w, 0, 2, now: now);
      expect(names(moved), ['squat', 'curl', 'bench', 'row']);
      expect(executionGroups(moved.exercises).last.map((e) => e.exerciseId), [
        'bench',
        'row',
      ]);
    });

    test('dropping in the same place changes nothing', () {
      final w = start([planned('bench'), planned('squat')]);
      expect(identical(moveExerciseGroup(w, 1, 1, now: now), w), isTrue);
      expect(identical(arrangeGroups(w, groupOrder(w), now: now), w), isTrue);
    });

    test('rejects places that do not exist', () {
      final w = start([planned('bench'), planned('squat')]);
      expect(() => moveExerciseGroup(w, 2, 0, now: now), throwsRangeError);
      expect(() => moveExerciseGroup(w, 0, -1, now: now), throwsRangeError);
    });

    test('an order missing a group keeps that group after the others', () {
      final w = start([planned('bench'), planned('squat'), planned('row')]);
      final keys = groupOrder(w);
      final arranged = arrangeGroups(w, [keys[2], 'gone', keys[0]], now: now);
      expect(names(arranged), ['row', 'bench', 'squat']);
    });

    test('marks a completed workout as edited', () {
      final ids = counter();
      var w = start([planned('bench'), planned('squat')], newId: ids);
      w = recordSummary(
        w,
        w.exercises.first.id,
        setCount: 1,
        fact: plan,
        newId: ids,
        now: now,
      );
      w = completeWorkout(w, now: now);
      expect(
        moveExerciseGroup(w, 1, 0, now: now).editedAfterCompletion,
        isTrue,
      );
    });
  });

  group('progress', () {
    test('estimates a one-rep max from weight and reps', () {
      expect(estimatedMaxKg(const SetValues(reps: 10, weightKg: 60)), 80);
      expect(estimatedMaxKg(const SetValues(reps: 8, weightKg: 60)), 76);
      expect(estimatedMaxKg(const SetValues(reps: 1, weightKg: 100)), 100);
      // 57.5 × 1.4 = 80.5; 62.5 × 1.2 = 75.
      expect(estimatedMaxKg(const SetValues(reps: 12, weightKg: 57.5)), 80.5);
      expect(estimatedMaxKg(const SetValues(reps: 6, weightKg: 62.5)), 75);
      expect(estimatedMaxKg(const SetValues(reps: 10)), isNull);
      expect(estimatedMaxKg(const SetValues(reps: 0, weightKg: 60)), isNull);
      expect(
        estimatedMaxKg(const SetValues(seconds: 30, weightKg: 60)),
        isNull,
      );
    });

    Workout done(
      String id,
      DateTime at,
      List<SetValues> facts, {
      Exercise exercise = bench,
    }) {
      final ids = counter();
      var w = startWorkout(
        id: id,
        traineeId: 'me',
        now: at,
        newId: ids,
        catalog: catalog,
        languageCode: 'en',
        bodyWeightKg: 80,
      );
      w = addExercise(w, exercise, languageCode: 'en', newId: ids, now: at);
      for (final fact in facts) {
        w = addExtraSet(
          w,
          w.exercises.single.id,
          fact: fact,
          newId: ids,
          now: at,
        );
      }
      return completeWorkout(w, now: at);
    }

    final day1 = DateTime(2026, 11, 5, 18);
    final day2 = DateTime(2026, 11, 8, 18);

    test('more reps at the same weight count as progress', () {
      final workouts = [
        done('a', day1, const [SetValues(reps: 8, weightKg: 60)]),
        done('b', day2, const [SetValues(reps: 10, weightKg: 60)]),
      ];
      final overview = progressOverview(workouts).single;
      expect(overview.mainMetric, ProgressMetric.estimatedMax);
      expect(overview.points.map((p) => p.value), [76, 80]);
      expect(
        overview.points.last.best,
        const SetValues(reps: 10, weightKg: 60),
      );
      expect(overview.points.last.workoutId, 'b');
      expect(overview.metrics[ProgressMetric.weight]!.map((p) => p.value), [
        60,
        60,
      ]);
      expect(overview.metrics[ProgressMetric.reps]!.map((p) => p.value), [
        8,
        10,
      ]);
    });

    test('the best set of a workout depends on the metric', () {
      final w = done('a', day1, const [
        SetValues(reps: 12, weightKg: 57.5), // ≈ 80.5
        SetValues(reps: 3, weightKg: 70), // 77
        SetValues(reps: 2, weightKg: 70), // 74.5
      ]);
      ProgressPoint point(ProgressMetric metric) =>
          progressFor('bench', [w], metric: metric).single;
      expect(point(ProgressMetric.estimatedMax).value, 80.5);
      expect(
        point(ProgressMetric.estimatedMax).best,
        const SetValues(reps: 12, weightKg: 57.5),
      );
      expect(point(ProgressMetric.weight).value, 70);
      expect(point(ProgressMetric.weight).best.reps, 3);
      expect(point(ProgressMetric.reps).value, 3);
    });

    test('an equal estimate goes to the heavier set', () {
      // 75 kg × 4 is estimated at 85 kg, the same as a single rep at 85 kg:
      // the heavier set counts.
      final w = done('a', day1, const [
        SetValues(reps: 4, weightKg: 75),
        SetValues(reps: 1, weightKg: 85),
      ]);
      final point = progressFor('bench', [
        w,
      ], metric: ProgressMetric.estimatedMax).single;
      expect(point.value, 85);
      expect(point.best, const SetValues(reps: 1, weightKg: 85));
    });

    test('without any weight only reps are followed', () {
      final overview = progressOverview([
        done('a', day1, const [SetValues(reps: 15)]),
      ]).single;
      expect(overview.metrics.keys, [ProgressMetric.reps]);
      expect(overview.points.single.value, 15);
    });

    test('body-weight and timed exercises keep their own measure', () {
      const pullUp = Exercise(
        id: 'pullup',
        names: {'en': 'Pull-up'},
        muscleGroup: 'back',
        usesBodyWeight: true,
      );
      const plank = Exercise(
        id: 'plank',
        names: {'en': 'Plank'},
        muscleGroup: 'core',
        measure: Measure.time,
      );
      final overview = progressOverview([
        done('a', day1, const [
          SetValues(reps: 10),
          SetValues(reps: 6, weightKg: 10),
        ], exercise: pullUp),
        done('b', day2, const [SetValues(seconds: 45)], exercise: plank),
      ]);
      expect(overview.map((e) => e.exerciseId), ['plank', 'pullup']);
      expect(overview.first.metrics.keys, [ProgressMetric.time]);
      expect(overview.last.metrics.keys, [ProgressMetric.bodyReps]);
      expect(overview.last.points.single.value, 6);
      expect(overview.last.points.single.extraKg, 10);
    });

    test('an exercise changed to body weight does not mix with before', () {
      const own = Exercise(
        id: 'custom/dip',
        names: {'en': 'Dip'},
        muscleGroup: 'chest',
      );
      const ownWithBody = Exercise(
        id: 'custom/dip',
        names: {'en': 'Dip'},
        muscleGroup: 'chest',
        usesBodyWeight: true,
      );
      final progress = exerciseProgress('custom/dip', [
        done('a', day1, const [
          SetValues(reps: 8, weightKg: 20),
        ], exercise: own),
        done('b', day2, const [SetValues(reps: 12)], exercise: ownWithBody),
      ])!;
      expect(progress.usesBodyWeight, isTrue);
      expect(progress.metrics.keys, [ProgressMetric.bodyReps]);
      expect(progress.points.single.workoutId, 'b');
    });

    test('a timed exercise changed to body weight does not mix either', () {
      const own = Exercise(
        id: 'custom/hang',
        names: {'en': 'Hang'},
        muscleGroup: 'back',
        measure: Measure.time,
      );
      const ownWithBody = Exercise(
        id: 'custom/hang',
        names: {'en': 'Hang'},
        muscleGroup: 'back',
        measure: Measure.time,
        usesBodyWeight: true,
      );
      final progress = exerciseProgress('custom/hang', [
        done('a', day1, const [SetValues(seconds: 90)], exercise: own),
        done('b', day2, const [SetValues(seconds: 30)], exercise: ownWithBody),
      ])!;
      expect(progress.metrics.keys, [ProgressMetric.time]);
      expect(progress.points.single.workoutId, 'b');
    });

    test('an exercise without points has no progress', () {
      expect(exerciseProgress('bench', const []), isNull);
      expect(
        exerciseProgress('bench', [
          done('a', day1, const [SetValues(reps: 0)]),
        ]),
        isNull,
      );
    });
  });
}
