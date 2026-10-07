import 'package:flutter_test/flutter_test.dart';

import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/domain/workout_logic.dart';

const bench = Exercise(
  id: 'bench',
  names: {'ru': 'Жим лёжа', 'en': 'Bench press'},
  muscleGroup: 'chest',
);
const plank = Exercise(
  id: 'plank',
  names: {'ru': 'Планка', 'en': 'Plank'},
  muscleGroup: 'core',
  measure: Measure.time,
);
const pullUp = Exercise(
  id: 'pullup',
  names: {'ru': 'Подтягивания', 'en': 'Pull-up'},
  muscleGroup: 'back',
  usesBodyWeight: true,
);
const catalog = {'bench': bench, 'plank': plank, 'pullup': pullUp};

const plan60x8 = SetValues(reps: 8, weightKg: 60);

Program programWith(List<SetValues> benchSets) => Program(
  id: 'p1',
  authorId: 'coach',
  name: 'Сила, 3 дня',
  days: [
    ProgramDay(
      id: 'd1',
      name: 'Грудь и трицепс',
      exercises: [
        ProgramExercise(
          id: 'pe1',
          exerciseId: 'bench',
          sets: benchSets,
          note: 'Пауза внизу',
        ),
        const ProgramExercise(
          id: 'pe2',
          exerciseId: 'plank',
          sets: [SetValues(seconds: 60)],
        ),
      ],
    ),
  ],
);

IdGenerator counter() {
  var n = 0;
  return () => 'id${n++}';
}

final monday = DateTime.utc(2026, 9, 28, 10);

Workout start({Program? program, IdGenerator? newId, String? coach}) {
  final p = program ?? programWith(const [plan60x8, plan60x8, plan60x8]);
  return startWorkout(
    id: 'w1',
    traineeId: 'arman',
    now: monday,
    newId: newId ?? counter(),
    catalog: catalog,
    languageCode: 'ru',
    program: p,
    day: p.days.first,
    supervisorCoachId: coach,
  );
}

void main() {
  group('startWorkout', () {
    test('copies the plan and leaves every fact empty', () {
      final w = start(coach: 'coach');

      expect(w.status, WorkoutStatus.inProgress);
      expect(w.programName, 'Сила, 3 дня');
      expect(w.dayName, 'Грудь и трицепс');
      expect(w.supervisorCoachId, 'coach');
      expect(w.exercises, hasLength(2));
      final b = w.exercises.first;
      expect(b.name, 'Жим лёжа');
      expect(b.note, 'Пауза внизу');
      expect(b.sets.map((s) => s.plan), everyElement(plan60x8));
      expect(b.sets.map((s) => s.fact), everyElement(isNull));
      expect(w.exercises.last.measure, Measure.time);
    });

    test('later program changes do not rewrite the workout', () {
      final w = start();
      // The coach now wants 4 × 10: a new program object, the workout keeps 3 × 8.
      programWith(List.filled(4, const SetValues(reps: 10, weightKg: 60)));

      expect(w.exercises.first.sets, hasLength(3));
      expect(w.exercises.first.sets.first.plan, plan60x8);
    });

    test('without a program starts empty and takes exercises as they come', () {
      final ids = counter();
      var w = startWorkout(
        id: 'w2',
        traineeId: 'arman',
        now: monday,
        newId: ids,
        catalog: catalog,
        languageCode: 'ru',
      );
      expect(w.programId, isNull);
      expect(w.exercises, isEmpty);

      w = addExercise(w, bench, languageCode: 'ru', newId: ids, now: monday);
      w = recordSummary(
        w,
        w.exercises.single.id,
        setCount: 2,
        fact: plan60x8,
        newId: ids,
        now: monday,
      );
      expect(w.exercises.single.sets, hasLength(2));
      expect(w.exercises.single.sets.every((s) => s.isExtra), isTrue);
    });
  });

  group('recordSummary', () {
    test('writes the same fact into each planned set', () {
      final ids = counter();
      var w = start(newId: ids);
      const fact = SetValues(reps: 6, weightKg: 55);
      w = recordSummary(
        w,
        w.exercises.first.id,
        setCount: 3,
        fact: fact,
        newId: ids,
        now: monday,
      );

      final sets = w.exercises.first.sets;
      expect(sets.map((s) => s.fact), everyElement(fact));
      expect(sets.map((s) => s.plan), everyElement(plan60x8));
    });

    test('fewer sets than planned leaves the rest without a fact', () {
      final ids = counter();
      var w = start(newId: ids);
      w = recordSummary(
        w,
        w.exercises.first.id,
        setCount: 2,
        fact: plan60x8,
        newId: ids,
        now: monday,
      );

      final facts = w.exercises.first.sets.map((s) => s.fact).toList();
      expect(facts, [plan60x8, plan60x8, null]);
    });

    test(
      'more sets than planned adds extra sets, and re-entry keeps them stable',
      () {
        final ids = counter();
        var w = start(newId: ids);
        final exId = w.exercises.first.id;
        w = recordSummary(
          w,
          exId,
          setCount: 5,
          fact: plan60x8,
          newId: ids,
          now: monday,
        );
        expect(w.exercises.first.sets, hasLength(5));
        expect(w.exercises.first.sets.where((s) => s.isExtra), hasLength(2));
        final extraIds = w.exercises.first.sets
            .skip(3)
            .map((s) => s.id)
            .toList();

        // Typing the same summary again must not create new sets.
        w = recordSummary(
          w,
          exId,
          setCount: 5,
          fact: plan60x8,
          newId: ids,
          now: monday,
        );
        expect(w.exercises.first.sets.skip(3).map((s) => s.id), extraIds);

        // Going back to 3 drops the extras.
        w = recordSummary(
          w,
          exId,
          setCount: 3,
          fact: plan60x8,
          newId: ids,
          now: monday,
        );
        expect(w.exercises.first.sets, hasLength(3));
      },
    );

    test('rejects a weight that is not a multiple of 0.25', () {
      final ids = counter();
      final w = start(newId: ids);
      expect(
        () => recordSummary(
          w,
          w.exercises.first.id,
          setCount: 3,
          fact: const SetValues(reps: 8, weightKg: 60.1),
          newId: ids,
          now: monday,
        ),
        throwsArgumentError,
      );
    });
  });

  group('per-set entry', () {
    test('records one set with effort and leaves the others alone', () {
      var w = start();
      final ex = w.exercises.first;
      w = recordSet(
        w,
        ex.id,
        ex.sets[1].id,
        fact: const SetValues(reps: 7, weightKg: 60),
        rpe: 8.5,
        now: monday,
      );

      final sets = w.exercises.first.sets;
      expect(sets[0].fact, isNull);
      expect(sets[1].fact, const SetValues(reps: 7, weightKg: 60));
      expect(sets[1].rpe, 8.5);
      expect(sets[2].fact, isNull);
    });

    test(
      'extra set can be added and removed, planned set cannot be removed',
      () {
        final ids = counter();
        var w = start(newId: ids);
        final exId = w.exercises.first.id;
        w = addExtraSet(w, exId, fact: plan60x8, newId: ids, now: monday);
        expect(w.exercises.first.sets, hasLength(4));

        final extra = w.exercises.first.sets.last;
        final planned = w.exercises.first.sets.first;
        expect(
          () => removeExtraSet(w, exId, planned.id, now: monday),
          throwsStateError,
        );
        w = removeExtraSet(w, exId, extra.id, now: monday);
        expect(w.exercises.first.sets, hasLength(3));
      },
    );
  });

  group('completion', () {
    test('completes once', () {
      final done = completeWorkout(start(), now: monday);
      expect(done.isCompleted, isTrue);
      expect(done.completedAt, monday);
      expect(done.editedAfterCompletion, isFalse);
      expect(() => completeWorkout(done, now: monday), throwsStateError);
    });

    test('a correction after completion is allowed and marked', () {
      var w = completeWorkout(start(), now: monday);
      final later = monday.add(const Duration(hours: 3));
      final ex = w.exercises.first;
      w = recordSet(w, ex.id, ex.sets.first.id, fact: plan60x8, now: later);

      expect(w.isCompleted, isTrue);
      expect(w.editedAt, later);
      expect(w.editedAfterCompletion, isTrue);
    });
  });

  group('plan against fact', () {
    WorkoutSet set(SetValues? plan, SetValues? fact) =>
        WorkoutSet(id: 's', plan: plan, fact: fact);

    test('names the deviation', () {
      expect(compareSet(set(plan60x8, plan60x8)).kind, DeviationKind.asPlanned);
      expect(compareSet(set(plan60x8, null)).kind, DeviationKind.missing);
      expect(compareSet(set(null, plan60x8)).kind, DeviationKind.extra);

      final below = compareSet(
        set(plan60x8, const SetValues(reps: 6, weightKg: 55)),
      );
      expect(below.kind, DeviationKind.below);
      expect(below.weightKg, -5);
      expect(below.count, -2);

      final above = compareSet(
        set(plan60x8, const SetValues(reps: 8, weightKg: 62.5)),
      );
      expect(above.kind, DeviationKind.above);
      expect(above.weightKg, 2.5);
    });

    test('heavier but fewer reps still counts as below plan', () {
      final mixed = compareSet(
        set(plan60x8, const SetValues(reps: 6, weightKg: 65)),
      );
      expect(mixed.kind, DeviationKind.below);
    });

    test('an exercise is below plan when any planned set is missing', () {
      final ids = counter();
      var w = start(newId: ids);
      expect(compareExercise(w.exercises.first), DeviationKind.missing);

      w = recordSummary(
        w,
        w.exercises.first.id,
        setCount: 2,
        fact: plan60x8,
        newId: ids,
        now: monday,
      );
      expect(compareExercise(w.exercises.first), DeviationKind.below);

      w = recordSummary(
        w,
        w.exercises.first.id,
        setCount: 3,
        fact: plan60x8,
        newId: ids,
        now: monday,
      );
      expect(compareExercise(w.exercises.first), DeviationKind.asPlanned);
    });
  });

  group('progress and prefill', () {
    Workout finished(DateTime at, List<SetValues> benchFacts, {int? plankSec}) {
      final ids = counter();
      var w = start(newId: ids);
      final b = w.exercises.first;
      for (var i = 0; i < benchFacts.length; i++) {
        w = recordSet(w, b.id, b.sets[i].id, fact: benchFacts[i], now: at);
      }
      if (plankSec != null) {
        final p = w.exercises.last;
        w = recordSet(
          w,
          p.id,
          p.sets.first.id,
          fact: SetValues(seconds: plankSec),
          now: at,
        );
      }
      return completeWorkout(w, now: at);
    }

    test('one point per completed workout: the heaviest weight', () {
      final first = finished(monday, const [
        SetValues(reps: 8, weightKg: 55),
        SetValues(reps: 8, weightKg: 57.5),
      ]);
      final second = finished(monday.add(const Duration(days: 2)), const [
        SetValues(reps: 8, weightKg: 60),
      ]);
      final unfinished = start();
      final nothingRecorded = finished(
        monday.add(const Duration(days: 4)),
        const [],
      );

      final points = progressFor('bench', [
        second,
        unfinished,
        nothingRecorded,
        first,
      ]);
      expect(points.map((p) => p.value), [57.5, 60]);
      expect(points.first.at, monday);
    });

    test('a timed exercise is tracked by its longest time', () {
      final w = finished(monday, const [], plankSec: 75);
      expect(progressFor('plank', [w]).single.value, 75);
    });

    Workout pullUps(DateTime at, List<SetValues> facts, {double body = 78}) {
      final ids = counter();
      var w = startWorkout(
        id: 'w${at.day}',
        traineeId: 'arman',
        now: at,
        newId: ids,
        catalog: catalog,
        languageCode: 'ru',
        bodyWeightKg: body,
      );
      w = addExercise(w, pullUp, languageCode: 'ru', newId: ids, now: at);
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

    test('a body-weight exercise is tracked by reps', () {
      final first = pullUps(monday, const [
        SetValues(reps: 7),
        SetValues(reps: 6),
      ]);
      final second = pullUps(monday.add(const Duration(days: 2)), const [
        SetValues(reps: 9),
      ]);

      final points = progressFor('pullup', [first, second]);
      expect(points.map((p) => p.value), [7, 9]);
      expect(points.map((p) => p.unit), everyElement(ProgressUnit.reps));
      expect(points.map((p) => p.extraKg), everyElement(0));
    });

    test('with extra weight the point is the reps at the heaviest weight', () {
      final w = pullUps(monday, const [
        SetValues(reps: 10),
        SetValues(reps: 5, weightKg: 10),
        SetValues(reps: 4, weightKg: 10),
      ]);

      final point = progressFor('pullup', [w]).single;
      expect(point.value, 5);
      expect(point.extraKg, 10);
    });

    test('body weight adds to the load only where the exercise uses it', () {
      final w = pullUps(monday, const [SetValues(reps: 5, weightKg: 10)]);
      final ex = w.exercises.single;
      expect(totalLoadKg(w, ex, ex.sets.single.fact!), 88);

      final benchWorkout = finished(monday, const [plan60x8]);
      final b = benchWorkout.exercises.first;
      expect(totalLoadKg(benchWorkout, b, b.sets.first.fact!), 60);
    });

    test('prefill takes the latest result, then the plan', () {
      final fresh = start().exercises.first;
      expect(prefillFor(fresh, const []), plan60x8);

      final older = finished(monday, const [SetValues(reps: 8, weightKg: 55)]);
      final newer = finished(monday.add(const Duration(days: 2)), const [
        SetValues(reps: 8, weightKg: 57.5),
      ]);
      expect(
        prefillFor(fresh, [older, newer]),
        const SetValues(reps: 8, weightKg: 57.5),
      );
    });
  });

  group('coach access', () {
    CoachLink link(String coach, LinkStatus status) => CoachLink(
      id: coach,
      coachId: coach,
      traineeId: 'arman',
      status: status,
      createdAt: monday,
    );

    test('the supervisor is the active coach, and only one is active', () {
      final links = [
        link('madina', LinkStatus.readOnly),
        link('sergey', LinkStatus.active),
      ];
      expect(activeCoachOf('arman', links), 'sergey');
      expect(activeCoachOf('arman', [links.first]), isNull);
    });

    test(
      'active and read-only coaches see workouts, a removed one does not',
      () {
        final w = start(coach: 'sergey');
        final links = [
          link('sergey', LinkStatus.active),
          link('madina', LinkStatus.readOnly),
          link('daniyar', LinkStatus.removed),
        ];
        expect(coachCanSee('sergey', w, links), isTrue);
        expect(coachCanSee('madina', w, links), isTrue);
        expect(coachCanSee('daniyar', w, links), isFalse);
        expect(coachCanSee('stranger', w, links), isFalse);
      },
    );
  });

  test('weight and effort steps', () {
    expect(isValidWeight(61.25), isTrue);
    expect(isValidWeight(0), isTrue);
    expect(isValidWeight(61.3), isFalse);
    expect(isValidWeight(1000), isFalse);
    expect(isValidRpe(8.5), isTrue);
    expect(isValidRpe(8.3), isFalse);
    expect(isValidRpe(0.5), isFalse);
  });

  group('entry panel', () {
    Workout done(Workout w, SetValues fact, {int sets = 3, int day = 1}) =>
        completeWorkout(
          recordSummary(
            w,
            w.exercises.first.id,
            setCount: sets,
            fact: fact,
            newId: counter(),
            now: monday,
          ),
          now: monday.add(Duration(days: day)),
        );

    test('the next exercise is the first one without a result', () {
      var w = start();
      expect(recordedCount(w), 0);
      expect(nextExercise(w)!.exerciseId, 'bench');
      w = recordSummary(
        w,
        w.exercises.first.id,
        setCount: 1,
        fact: plan60x8,
        newId: counter(),
        now: monday,
      );
      expect(recordedCount(w), 1);
      expect(nextExercise(w)!.exerciseId, 'plank');
    });

    test('alike sets fold into one line, different ones only count', () {
      var w = start();
      final bench = w.exercises.first;
      expect(planSummary(bench)!.count, 3);
      expect(planSummary(bench)!.values, plan60x8);
      expect(factSummary(bench), isNull);
      w = recordSet(w, bench.id, bench.sets[0].id, fact: plan60x8, now: monday);
      w = recordSet(
        w,
        bench.id,
        bench.sets[1].id,
        fact: const SetValues(reps: 6, weightKg: 60),
        now: monday,
      );
      final fact = factSummary(w.exercises.first)!;
      expect(fact.count, 2);
      expect(fact.values, isNull);
    });

    test('summary entry opens with last time, set count from the plan', () {
      const last = SetValues(reps: 8, weightKg: 57.5);
      final earlier = [done(start(), last, sets: 4)];
      final draft = summaryDraft(start().exercises.first, earlier);
      expect(draft.setCount, 3);
      expect(draft.values, last);
      expect(lastResult(start().exercises.first, earlier)!.count, 4);
      expect(lastResult(start().exercises.first, earlier)!.values, last);
      expect(lastResult(start().exercises.last, earlier), isNull);
    });

    test('without history summary entry opens with the plan', () {
      final draft = summaryDraft(start().exercises.first, const []);
      expect(draft.setCount, 3);
      expect(draft.values, plan60x8);
      final timed = summaryDraft(start().exercises.last, const []);
      expect(timed.setCount, 1);
      expect(timed.values, const SetValues(seconds: 60));
    });

    test('without a plan the remembered set count is used', () {
      final free = addExercise(
        startWorkout(
          id: 'w',
          traineeId: 'me',
          now: monday,
          newId: counter(),
          catalog: catalog,
          languageCode: 'ru',
        ),
        plank,
        languageCode: 'ru',
        newId: counter(),
        now: monday,
      ).exercises.single;
      expect(summaryDraft(free, const [], lastSetCount: 5).setCount, 5);
      final draft = summaryDraft(free, const []);
      expect(draft.setCount, 3);
      expect(draft.values.seconds, isNotNull);
      expect(draft.values.reps, isNull);
    });

    test('a recorded exercise reopens with its own result', () {
      final w = recordSummary(
        start(),
        start().exercises.first.id,
        setCount: 2,
        fact: const SetValues(reps: 5, weightKg: 70),
        newId: counter(),
        now: monday,
      );
      final draft = summaryDraft(w.exercises.first, const []);
      expect(draft.setCount, 2);
      expect(draft.values, const SetValues(reps: 5, weightKg: 70));
    });

    test('per-set entry follows the previous set, then the plan', () {
      var w = start();
      final bench = w.exercises.first;
      expect(nextSet(bench)!.id, bench.sets.first.id);
      expect(setDraft(bench, bench.sets.first, const []), plan60x8);
      const fact = SetValues(reps: 6, weightKg: 62.5);
      w = recordSet(w, bench.id, bench.sets.first.id, fact: fact, now: monday);
      final after = w.exercises.first;
      expect(nextSet(after)!.id, bench.sets[1].id);
      expect(setDraft(after, after.sets[1], const []), fact);
      expect(setDraft(after, after.sets[0], const []), fact);
    });

    test('effort is three answers stored on the 1–10 scale', () {
      expect(Effort.values.map((e) => e.rpe), [7, 8.5, 10]);
      expect(Effort.values.map((e) => isValidRpe(e.rpe)), everyElement(true));
      expect(Effort.of(5), Effort.more);
      expect(Effort.of(7), Effort.more);
      expect(Effort.of(7.5), Effort.some);
      expect(Effort.of(9.5), Effort.some);
      expect(Effort.of(10), Effort.none);
    });

    test('weight steps stay in range and typed weights are checked', () {
      expect(stepWeight(0, -weightStepKg), 0);
      expect(stepWeight(57.5, weightStepKg), 60);
      expect(stepWeight(maxWeightKg, weightStepKg), maxWeightKg);
      expect(parseWeight('42,5'), 42.5);
      expect(parseWeight('42.25'), 42.25);
      expect(parseWeight('42,3'), isNull);
      expect(parseWeight(''), isNull);
      expect(parseWeight('1000'), isNull);
    });
  });

  test('history verdict counts short and skipped exercises', () {
    var w = start();
    expect(hasPlan(w), isTrue);
    expect(planVerdict(w), (below: 0, skipped: 2));
    w = recordSummary(
      w,
      w.exercises.first.id,
      setCount: 2,
      fact: plan60x8,
      newId: counter(),
      now: monday,
    );
    expect(planVerdict(w), (below: 1, skipped: 1));
    w = recordSummary(
      w,
      w.exercises.first.id,
      setCount: 3,
      fact: plan60x8,
      newId: counter(),
      now: monday,
    );
    w = recordSummary(
      w,
      w.exercises.last.id,
      setCount: 1,
      fact: const SetValues(seconds: 70),
      newId: counter(),
      now: monday,
    );
    expect(planVerdict(w), (below: 0, skipped: 0));
    final free = startWorkout(
      id: 'f',
      traineeId: 'me',
      now: monday,
      newId: counter(),
      catalog: catalog,
      languageCode: 'ru',
    );
    expect(hasPlan(free), isFalse);
  });

  test('progress offers only exercises with results, latest first', () {
    Workout done(String id, int day, {required bool plankToo}) {
      var w = startWorkout(
        id: id,
        traineeId: 'arman',
        now: monday,
        newId: counter(),
        catalog: catalog,
        languageCode: 'ru',
        program: programWith(const [plan60x8]),
        day: programWith(const [plan60x8]).days.first,
      );
      w = recordSummary(
        w,
        w.exercises.first.id,
        setCount: 1,
        fact: plan60x8,
        newId: counter(),
        now: monday,
      );
      if (plankToo) {
        w = recordSummary(
          w,
          w.exercises.last.id,
          setCount: 1,
          fact: const SetValues(seconds: 60),
          newId: counter(),
          now: monday,
        );
      }
      return completeWorkout(w, now: monday.add(Duration(days: day)));
    }

    final found = exercisesWithResults([
      done('a', 1, plankToo: true),
      done('b', 2, plankToo: false),
      start(),
    ]);
    expect(found.map((e) => e.exerciseId), ['bench', 'plank']);
    expect(found.first.name, 'Жим лёжа');
    expect(exercisesWithResults([start()]), isEmpty);
  });

  group('the day of a workout', () {
    final now = DateTime(2026, 10, 7, 19, 30);

    test('is the day it was completed unless another one is given', () {
      final today = completeWorkout(start(), now: now, day: now);
      expect(today.performedOn, isNull);
      expect(performedAt(today), now);

      final earlier = completeWorkout(
        start(),
        now: now,
        day: DateTime(2026, 10, 3, 23, 59),
      );
      expect(earlier.performedOn, DateTime(2026, 10, 3));
      expect(earlier.completedAt, now);
      // Finishing is not a correction.
      expect(earlier.editedAfterCompletion, isFalse);
      expect(performedAt(earlier), DateTime(2026, 10, 3, 19, 30));
    });

    test('cannot be in the future', () {
      expect(
        () => completeWorkout(start(), now: now, day: DateTime(2026, 10, 8)),
        throwsArgumentError,
      );
      final done = completeWorkout(start(), now: now);
      expect(
        () => setWorkoutDay(done, DateTime(2026, 10, 8), now: now),
        throwsArgumentError,
      );
      expect(
        () => setWorkoutDay(start(), DateTime(2026, 10, 1), now: now),
        throwsStateError,
      );
    });

    test(
      'moving a completed workout marks it edited and reorders progress',
      () {
        Workout with_(double kg) {
          final w = start();
          return recordSummary(
            w,
            w.exercises.first.id,
            setCount: 1,
            fact: SetValues(reps: 8, weightKg: kg),
            newId: counter(),
            now: now,
          );
        }

        final older = completeWorkout(
          with_(60),
          now: now.subtract(const Duration(days: 1)),
        );
        final newer = completeWorkout(with_(70), now: now);
        List<double> values(List<Workout> workouts) => [
          for (final point in progressFor('bench', workouts)) point.value,
        ];
        expect(values([older, newer]), [60, 70]);

        // The newer one is said to have happened a week earlier.
        final moved = setWorkoutDay(newer, DateTime(2026, 9, 30), now: now);
        expect(moved.editedAfterCompletion, isTrue);
        expect(moved.performedOn, DateTime(2026, 9, 30));
        expect(values([older, moved]), [70, 60]);
      },
    );
  });
}
