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
}
