import 'package:flutter_test/flutter_test.dart';
import 'package:progressbar_app/data/firestore_codec.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/domain/progress_logic.dart';
import 'package:progressbar_app/domain/strength_estimate.dart' as strength;
import 'package:progressbar_app/domain/workout_logic.dart';

final now = DateTime(2026, 11, 16);
WorkoutExercise ex(
  String id, {
  List<WorkoutSet>? sets,
  bool body = false,
  Measure measure = Measure.reps,
  String? group,
  String? planGroup,
  ExecutionMode? planMode,
}) => WorkoutExercise(
  id: id,
  exerciseId: 'same',
  name: 'Snapshot $id',
  measure: measure,
  usesBodyWeight: body,
  executionMode: group == null
      ? ExecutionMode.ordinary
      : ExecutionMode.superset,
  groupId: group,
  planExecutionMode: planMode,
  planGroupId: planGroup,
  sets:
      sets ??
      const [WorkoutSet(id: 's', plan: SetValues(reps: 12, weightKg: 60))],
);
Workout workout(
  List<WorkoutExercise> exercises, {
  List<String>? order,
  double? body,
}) => Workout(
  id: 'w',
  traineeId: 'me',
  status: WorkoutStatus.inProgress,
  startedAt: now,
  exercises: exercises,
  originalOrder: order,
  bodyWeightKg: body,
);
WorkoutSet pair(int pr, double pw, int fr, double fw) => WorkoutSet(
  id: 's',
  plan: SetValues(reps: pr, weightKg: pw),
  fact: SetValues(reps: fr, weightKg: fw),
);
void main() {
  group('comparison with explicit snapshot context', () {
    final cases = <(int, double, int, double, DeviationKind)>[
      (12, 60, 10, 80, DeviationKind.above),
      (12, 60, 3, 80, DeviationKind.above),
      (8, 60, 6, 65, DeviationKind.above),
      (10, 60, 12, 57.5, DeviationKind.above),
      (10, 60, 6, 60, DeviationKind.below),
      (1, 60, 1, 60.25, DeviationKind.above),
      (2, 60, 1, 64, DeviationKind.asPlanned),
      (10, 0, 12, 0, DeviationKind.above),
      (10, 60, 0, 80, DeviationKind.below),
      (10, 60, 20, 0, DeviationKind.below),
      (0, 60, 0, 80, DeviationKind.asPlanned),
      (10, 0, 1, 60, DeviationKind.above),
    ];
    for (final c in cases) {
      test('$c', () {
        final set = pair(c.$1, c.$2, c.$3, c.$4);
        final e = ex('a', sets: [set]);
        final w = workout([e], body: 80);
        final result = compareSet(set, workout: w, exercise: e);
        expect(result.kind, c.$5);
        expect(result.weightKg, c.$4 - c.$2);
        expect(result.count, c.$3 - c.$1);
        expect(compareExercise(w, e), c.$5);
      });
    }
    test('body snapshot adds body weight to the estimate', () {
      final s = pair(10, 0, 8, 10);
      final e = ex('a', body: true, sets: [s]);
      final w = workout([e], body: 80);
      expect(compareSet(s, workout: w, exercise: e).kind, DeviationKind.above);
      expect(planComparisonEstimate(w, e), (factKg: 114.0, planKg: 106.5));
    });
    for (final body in <double?>[null, 0]) {
      test('without body snapshot $body a shortfall is below, no estimate', () {
        final cases = <(int, double, int, double, DeviationKind)>[
          // More extra weight, fewer reps: the load is unknown.
          (10, 0, 8, 10, DeviationKind.below),
          (10, 0, 5, 2.5, DeviationKind.below),
          (8, 10, 12, 0, DeviationKind.below),
          (10, 0, 10, 10, DeviationKind.above),
          (10, 0, 12, 0, DeviationKind.above),
          (10, 5, 10, 5, DeviationKind.asPlanned),
        ];
        for (final c in cases) {
          final s = pair(c.$1, c.$2, c.$3, c.$4);
          final e = ex('a', body: true, sets: [s]);
          final w = workout([e], body: body);
          expect(
            compareSet(s, workout: w, exercise: e).kind,
            c.$5,
            reason: '$c',
          );
          expect(compareExercise(w, e), c.$5, reason: '$c');
          expect(planComparisonEstimate(w, e), isNull, reason: '$c');
        }
      });
    }
    test(
      'time keeps conservative count and weight comparison including zero',
      () {
        for (final s in [
          const WorkoutSet(
            id: 's',
            plan: SetValues(seconds: 60),
            fact: SetValues(seconds: 45),
          ),
          const WorkoutSet(
            id: 's',
            plan: SetValues(seconds: 60, weightKg: 10),
            fact: SetValues(seconds: 70, weightKg: 5),
          ),
          const WorkoutSet(
            id: 's',
            plan: SetValues(seconds: 60),
            fact: SetValues(seconds: 0),
          ),
        ]) {
          final e = ex('a', measure: Measure.time, body: true, sets: [s]);
          final w = workout([e], body: 80);
          expect(compareExercise(w, e), DeviationKind.below);
          expect(planComparisonEstimate(w, e), isNull);
        }
      },
    );
    test('extra, missing, drops, and deciding set for explanation', () {
      final strong = pair(12, 60, 10, 80);
      final weak = pair(12, 60, 20, 30);
      final missing = const WorkoutSet(
        id: 'm',
        plan: SetValues(reps: 12, weightKg: 60),
      );
      for (final sets in [
        [strong, missing],
        [strong, weak],
        [
          strong,
          WorkoutSet(
            id: 'drop',
            plan: strong.plan,
            fact: strong.fact,
            drops: [DropStage(id: 'd', plan: weak.plan, fact: weak.fact)],
          ),
        ],
      ]) {
        final e = ex('a', sets: sets);
        final w = workout([e]);
        expect(compareExercise(w, e), DeviationKind.below);
        expect(
          planComparisonEstimate(w, e),
          sets.contains(missing) ? isNull : (factKg: 50.0, planKg: 84.0),
        );
      }
      // A missing first set is skipped: the first set that is itself below
      // decides and explains.
      final skippedThenWeak = ex('a', sets: [missing, weak]);
      final sw = workout([skippedThenWeak]);
      expect(compareExercise(sw, skippedThenWeak), DeviationKind.below);
      expect(planComparisonEstimate(sw, skippedThenWeak), (
        factKg: 50.0,
        planKg: 84.0,
      ));
      for (final sets in [
        <WorkoutSet>[],
        [const WorkoutSet(id: 'x')],
        [missing],
        [pair(8, 60, 6, 60)],
        [pair(8, 60, 10, 65)],
        [pair(2, 60, 1, 64)],
      ]) {
        final e = ex('a', sets: sets);
        expect(planComparisonEstimate(workout([e]), e), isNull);
      }
      final e = ex('a', sets: [strong]);
      expect(planComparisonEstimate(workout([e]), e), (
        factKg: 106.5,
        planKg: 84.0,
      ));
    });
    test(
      'progress shares the exact numerical kernel and nullable contract',
      () {
        for (final s in [
          const SetValues(reps: 10, weightKg: 80),
          const SetValues(reps: 1, weightKg: 60.25),
          const SetValues(reps: 0, weightKg: 80),
          const SetValues(seconds: 60),
        ]) {
          expect(estimatedMaxKg(s), strength.estimatedMaxKg(s));
        }
      },
    );
  });
  group('order snapshots are read without rewriting', () {
    List<List<String>> ids(List<List<WorkoutExercise>> groups) => [
      for (final g in groups) [for (final e in g) e.id],
    ];
    test('absent and empty snapshots cannot prove change', () {
      for (final order in <List<String>?>[null, []]) {
        final info = workoutOrderInfo(
          workout([ex('b'), ex('a')], order: order),
        );
        expect(info.available, isFalse);
        expect(info.changed, isFalse);
      }
    });
    test('instances, unknown ids, duplicates, late additions and return', () {
      final a = ex('a'), b = ex('b'), late = ex('late', sets: []);
      final w = workout([b, late, a], order: ['a', 'gone', 'a', 'b']);
      final info = workoutOrderInfo(w);
      expect(info.changed, isTrue);
      expect(info.incomplete, isTrue);
      expect(info.hasAddedLater, isTrue);
      expect(ids(info.originalGroups), [
        ['a'],
        ['b'],
      ]);
      expect(ids(info.plannedGroups), [
        ['a'],
        ['b'],
      ]);
      expect(
        workoutOrderInfo(w.copyWith(exercises: [a, late, b])).changed,
        isFalse,
      );
      final loaded = workoutFromMap(w.id, workoutToMap(w));
      expect(loaded.originalOrder, w.originalOrder);
      expect(workoutOrderInfo(loaded).changed, isTrue);
      expect(w.originalOrder, ['a', 'gone', 'a', 'b']);
    });
    test('late planned ids mean incomplete; one known id proves nothing', () {
      final info = workoutOrderInfo(
        workout([ex('b'), ex('a')], order: ['a', 'gone']),
      );
      expect(info.incomplete, isTrue);
      expect(info.changed, isFalse);
    });
    test('canonical actual groups and distinct saved plan groups', () {
      final a = ex(
        'a',
        group: 'actual',
        planMode: ExecutionMode.superset,
        planGroup: 'plan',
      );
      final b = ex('b', planMode: ExecutionMode.superset, planGroup: 'plan');
      final c = ex('c', group: 'actual');
      final w = workout([a, c, b], order: ['a', 'b', 'c']);
      final info = workoutOrderInfo(w);
      expect(info.changed, isFalse);
      expect(ids(info.originalGroups), [
        ['a', 'c'],
        ['b'],
      ]);
      expect(ids(info.plannedGroups), [
        ['a', 'b'],
        ['c'],
      ]);
      final moved = w.copyWith(exercises: [b, a, c]);
      expect(workoutOrderInfo(moved).changed, isTrue);
    });
    test('skip and edits preserve first snapshot; added outside plan needs full list', () {
      final a = ex('a'), b = ex('b'), extra = ex('extra', sets: []);
      final w = workout([a, b, extra]);
      final moved = moveExerciseGroup(w, 2, 0, now: now);
      final info = workoutOrderInfo(moved);
      expect(info.changed, isTrue);
      expect(info.showOriginal, isTrue);
      final skipped = skipExercise(moved, a.id, now: now);
      expect(workoutOrderInfo(skipped).changed, isTrue);
      final completed = completeWorkout(skipped, now: now);
      final edited = setWorkoutDay(completed, DateTime(2026, 11, 15), now: now);
      expect(edited.originalOrder, ['a', 'b', 'extra']);
      final returned = moveExerciseGroup(moved, 0, 2, now: now);
      expect(workoutOrderInfo(returned).changed, isFalse);
      expect(returned.originalOrder, ['a', 'b', 'extra']);
    });
  });
}
