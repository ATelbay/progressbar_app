import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:progressbar_app/data/firestore_codec.dart';
import 'package:progressbar_app/data/firestore_writes.dart';
import 'package:progressbar_app/data/personal_exercise_repository.dart';
import 'package:progressbar_app/data/program_repository.dart';
import 'package:progressbar_app/data/workout_repository.dart';
import 'package:progressbar_app/domain/exercise_catalog.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/domain/workout_logic.dart';

const uid = 'athlete';
const bench = Exercise(
  id: 'free-exercise-db/Bench',
  names: {'en': 'Bench press', 'ru': 'Жим лёжа'},
  muscleGroup: 'chest',
  equipment: 'barbell',
);
const pullup = Exercise(
  id: 'free-exercise-db/Pullups',
  names: {'en': 'Pull-up', 'ru': 'Подтягивания'},
  muscleGroup: 'lats',
  usesBodyWeight: true,
);
const plank = Exercise(
  id: 'custom/plank',
  names: {'ru': 'Планка'},
  muscleGroup: 'abdominals',
  measure: Measure.time,
  ownerId: uid,
);
final catalog = indexExercises([bench, pullup, plank]);

const program = Program(
  id: 'p1',
  authorId: uid,
  name: 'Верх',
  days: [
    ProgramDay(
      id: 'd1',
      name: 'День 1',
      exercises: [
        ProgramExercise(
          id: 'pe1',
          exerciseId: 'free-exercise-db/Bench',
          note: 'Пауза внизу',
          sets: [
            SetValues(reps: 8, weightKg: 60),
            SetValues(reps: 8, weightKg: 62.5),
          ],
        ),
        ProgramExercise(
          id: 'pe2',
          exerciseId: 'custom/plank',
          sets: [SetValues(seconds: 45)],
        ),
      ],
    ),
  ],
);

final startedAt = DateTime.utc(2026, 10, 6, 18);
var _counter = 0;
String nextId() => 'id${_counter++}';

Workout started(String id, {Program? from = program}) => startWorkout(
  id: id,
  traineeId: uid,
  now: startedAt,
  newId: nextId,
  catalog: catalog,
  languageCode: 'ru',
  program: from,
  day: from?.days.first,
  bodyWeightKg: 80,
);

/// Everything a stored workout must give back, as comparable values.
List<Object?> fingerprint(Workout w) => [
  w.id,
  w.traineeId,
  w.supervisorCoachId,
  w.programId,
  w.programName,
  w.dayName,
  w.status,
  w.startedAt.toUtc(),
  w.completedAt?.toUtc(),
  w.editedAt?.toUtc(),
  w.comment,
  w.bodyWeightKg,
  for (final e in w.exercises) ...[
    e.id,
    e.exerciseId,
    e.name,
    e.measure,
    e.usesBodyWeight,
    e.note,
    for (final s in e.sets) ...[s.id, s.plan, s.fact, s.rpe],
  ],
];

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreWorkoutRepository workouts;

  setUp(() {
    db = FakeFirebaseFirestore();
    workouts = FirestoreWorkoutRepository(db);
  });

  Future<Map<String, dynamic>?> pointer() async =>
      (await db.doc('users/$uid/state/activeWorkout').get()).data();

  group('codec', () {
    test('a workout comes back exactly, with plan and fact kept apart', () {
      var workout = started('w1');
      final benchId = workout.exercises.first.id;
      workout = recordSet(
        workout,
        benchId,
        workout.exercises.first.sets.first.id,
        fact: const SetValues(reps: 7, weightKg: 62.5),
        rpe: 8.5,
        now: startedAt,
      );
      workout = addExtraSet(
        workout,
        benchId,
        fact: const SetValues(reps: 5, weightKg: 65),
        newId: nextId,
        now: startedAt,
      );
      workout = completeWorkout(
        workout,
        now: startedAt.add(const Duration(hours: 1)),
      ).copyWith(comment: 'Тяжело', editedAt: startedAt);

      final restored = workoutFromMap('w1', workoutToMap(workout));
      expect(fingerprint(restored), fingerprint(workout));
      final first = restored.exercises.first.sets.first;
      expect(first.plan, const SetValues(reps: 8, weightKg: 60));
      expect(first.fact, const SetValues(reps: 7, weightKg: 62.5));
      expect(restored.exercises.first.sets.last.isExtra, isTrue);
      expect(restored.exercises.last.measure, Measure.time);
    });

    test('a program and a personal exercise come back exactly', () {
      final restored = programFromMap('p1', programToMap(program));
      expect(restored.authorId, uid);
      expect(restored.name, 'Верх');
      final day = restored.days.single;
      expect(day.name, 'День 1');
      expect(day.exercises.map((e) => e.exerciseId), [bench.id, plank.id]);
      expect(day.exercises.first.note, 'Пауза внизу');
      expect(day.exercises.first.sets, program.days.first.exercises.first.sets);
      expect(day.exercises.last.sets, [const SetValues(seconds: 45)]);

      final exercise = exerciseFromMap(uid, exerciseToMap(plank));
      expect(exercise.id, plank.id);
      expect(exercise.names, plank.names);
      expect(exercise.measure, Measure.time);
      expect(exercise.ownerId, uid);
    });
  });

  group('workouts', () {
    test('a started workout is restored as the active one', () async {
      final workout = started('w1');
      await workouts.start(workout);
      await pumpEventQueue();
      // A fresh repository stands for the app after a restart.
      final restored = await FirestoreWorkoutRepository(db)
          .watchActive(uid)
          .first;
      expect(fingerprint(restored!), fingerprint(workout));
      expect((await pointer())?['workoutId'], 'w1');
    });

    test('a second workout cannot be started while one is active', () async {
      await workouts.start(started('w1'));
      await pumpEventQueue();
      await expectLater(
        workouts.start(started('w2')),
        throwsA(
          isA<ActiveWorkoutExists>().having((e) => e.workoutId, 'id', 'w1'),
        ),
      );
      // Tapping «start» again for the same workout is refused as well.
      await expectLater(
        workouts.start(started('w1')),
        throwsA(isA<ActiveWorkoutExists>()),
      );
      expect((await db.collection('users/$uid/workouts').get()).docs.length, 1);
    });

    test('two starts at the same moment leave one workout', () async {
      final results = await Future.wait([
        for (final id in ['w1', 'w2'])
          workouts
              .start(started(id))
              .then<String?>((_) => id, onError: (_) => null),
      ]);
      await pumpEventQueue();
      expect(results, ['w1', null]);
      expect((await workouts.watchActive(uid).first)?.id, 'w1');
      expect((await db.collection('users/$uid/workouts').get()).docs.length, 1);
    });

    test(
      'recorded sets are stored per set, also after summary entry',
      () async {
        var workout = started('w1');
        await workouts.start(workout);
        await pumpEventQueue();
        workout = recordSummary(
          workout,
          workout.exercises.first.id,
          setCount: 3,
          fact: const SetValues(reps: 8, weightKg: 60),
          newId: nextId,
          now: startedAt,
        );
        await workouts.save(workout);
        await pumpEventQueue();

        final restored = await workouts.watchActive(uid).first;
        final sets = restored!.exercises.first.sets;
        expect(sets.length, 3);
        expect(sets.map((s) => s.fact), everyElement(isNotNull));
        expect(sets.map((s) => s.plan != null), [true, true, false]);
      },
    );

    test(
      'completing frees the slot and moves the workout to history',
      () async {
        final first = started('w1');
        await workouts.start(first);
        await pumpEventQueue();
        final done = completeWorkout(
          first,
          now: startedAt.add(const Duration(hours: 1)),
        );
        await workouts.save(done);
        await pumpEventQueue();

        expect(await workouts.watchActive(uid).first, isNull);
        expect((await pointer())?['workoutId'], isNull);
        expect((await workouts.watchCompleted(uid).first).single.id, 'w1');

        await workouts.start(started('w2', from: null));
        await pumpEventQueue();
        expect((await workouts.watchActive(uid).first)?.id, 'w2');
      },
    );

    test(
      'correcting a completed workout leaves the active one alone',
      () async {
        final first = started('w1');
        await workouts.start(first);
        await pumpEventQueue();
        var done = completeWorkout(first, now: startedAt);
        await workouts.save(done);
        await pumpEventQueue();
        await workouts.start(started('w2'));
        await pumpEventQueue();

        final later = startedAt.add(const Duration(days: 1));
        done = recordSet(
          done,
          done.exercises.first.id,
          done.exercises.first.sets.first.id,
          fact: const SetValues(reps: 6, weightKg: 60),
          now: later,
        );
        await workouts.save(done);
        await pumpEventQueue();

        expect((await pointer())?['workoutId'], 'w2');
        final history = await workouts.watchCompleted(uid).first;
        expect(history.single.editedAfterCompletion, isTrue);
        expect(history.single.editedAt!.toUtc(), later);
      },
    );

    test('history is newest first', () async {
      for (final (id, day) in [('w1', 1), ('w2', 3), ('w3', 2)]) {
        final workout = started(id);
        await workouts.start(workout);
        await pumpEventQueue();
        await workouts.save(
          completeWorkout(workout, now: startedAt.add(Duration(days: day))),
        );
        await pumpEventQueue();
      }
      final history = await workouts.watchCompleted(uid).first;
      expect(history.map((w) => w.id), ['w2', 'w3', 'w1']);
    });

    test('cancelling removes the workout and frees the slot', () async {
      final workout = started('w1');
      await workouts.start(workout);
      await pumpEventQueue();
      await workouts.cancel(workout);
      await pumpEventQueue();
      expect(await workouts.watchActive(uid).first, isNull);
      expect((await db.collection('users/$uid/workouts').get()).docs, isEmpty);
      await workouts.start(started('w2'));
      await pumpEventQueue();
    });

    test(
      'a workout that is not active can be neither saved nor cancelled',
      () async {
        final stale = started('w1');
        await workouts.start(stale);
        await pumpEventQueue();
        await workouts.cancel(stale);
        await pumpEventQueue();
        await expectLater(workouts.save(stale), throwsStateError);
        await expectLater(workouts.cancel(stale), throwsStateError);
        expect(
          (await db.collection('users/$uid/workouts').get()).docs,
          isEmpty,
        );
      },
    );

    test(
      'the active workout stream follows start, record and finish',
      () async {
        final seen = <String?>[];
        final sub = workouts
            .watchActive(uid)
            .listen(
              (w) => seen.add(w == null ? null : '${w.id}:${w.status.name}'),
            );
        await pumpEventQueue();
        final workout = started('w1');
        await workouts.start(workout);
        await pumpEventQueue();
        await pumpEventQueue();
        await workouts.save(completeWorkout(workout, now: startedAt));
        await pumpEventQueue();
        await pumpEventQueue();
        await sub.cancel();
        expect(seen.first, isNull);
        expect(seen, contains('w1:inProgress'));
        expect(seen.last, isNull);
      },
    );
  });

  group('programs', () {
    test(
      'editing a program does not rewrite a workout started from it',
      () async {
        final programs = FirestoreProgramRepository(db);
        await programs.save(program);
        await pumpEventQueue();
        final workout = started('w1');
        await workouts.start(workout);
        await pumpEventQueue();

        await programs.save(
          const Program(id: 'p1', authorId: uid, name: 'Низ', days: []),
        );
        await pumpEventQueue();
        expect((await programs.watchOwn(uid).first).single.name, 'Низ');
        final active = await workouts.watchActive(uid).first;
        expect(active!.programName, 'Верх');
        expect(active.exercises.length, 2);

        await programs.delete(program);
        await pumpEventQueue();
        expect(await programs.watchOwn(uid).first, isEmpty);
        expect((await workouts.watchActive(uid).first)!.exercises.length, 2);
      },
    );

    test('each user sees only the programs they wrote', () async {
      final programs = FirestoreProgramRepository(db);
      await programs.save(program);
      await pumpEventQueue();
      await programs.save(
        const Program(id: 'p2', authorId: 'coach', name: 'Чужая', days: []),
      );
      await pumpEventQueue();
      expect((await programs.watchOwn(uid).first).single.id, 'p1');
    });
  });

  group('personal exercises', () {
    test('own exercises are added and edits replace built-in ones', () async {
      final exercises = FirestorePersonalExerciseRepository(db);
      await exercises.save(plank);
      await pumpEventQueue();
      await exercises.save(
        const Exercise(
          id: 'free-exercise-db/Bench',
          names: {'ru': 'Жим'},
          muscleGroup: 'chest',
          ownerId: uid,
        ),
      );
      await pumpEventQueue();
      final builtIn = indexExercises([bench, pullup]);
      var merged = mergeCatalog(builtIn, await exercises.watch(uid).first);
      expect(merged.keys, containsAll([bench.id, pullup.id, plank.id]));
      expect(merged[bench.id]!.nameFor('ru'), 'Жим');
      expect(merged[bench.id]!.ownerId, uid);
      expect(merged[pullup.id]!.ownerId, isNull);

      await exercises.restoreBuiltIn(uid, bench.id);
      await pumpEventQueue();
      merged = mergeCatalog(builtIn, await exercises.watch(uid).first);
      expect(merged[bench.id]!.nameFor('ru'), 'Жим лёжа');
      expect(merged, contains(plank.id));
    });

    test(
      'an exercise without an owner or a known ID kind is refused',
      () async {
        final exercises = FirestorePersonalExerciseRepository(db);
        await expectLater(exercises.save(bench), throwsArgumentError);
        await expectLater(
          exercises.save(
            const Exercise(
              id: 'plank',
              names: {'ru': 'Планка'},
              muscleGroup: 'abdominals',
              ownerId: uid,
            ),
          ),
          throwsArgumentError,
        );
        await expectLater(
          exercises.restoreBuiltIn(uid, plank.id),
          throwsArgumentError,
        );
      },
    );
  });

  test('the day set by hand is stored and orders history', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreWorkoutRepository(db);
    final now = DateTime(2026, 10, 7, 19);
    Future<void> done(String id, {DateTime? day}) async {
      final workout = startWorkout(
        id: id,
        traineeId: uid,
        now: now,
        newId: () => newFirestoreId(db),
        catalog: catalog,
        languageCode: 'ru',
        program: program,
        day: program.days.first,
      );
      await repo.start(workout);
      await repo.save(completeWorkout(workout, now: now, day: day));
    }

    await done('today');
    await done('lastWeek', day: DateTime(2026, 9, 30));
    await done('yesterday', day: DateTime(2026, 10, 6));
    expect(
      (await db.doc('users/$uid/workouts/lastWeek').get())
          .data()!['performedOn'],
      '2026-09-30',
    );
    final history = await repo.watchCompleted(uid).first;
    expect(history.map((w) => w.id), ['today', 'yesterday', 'lastWeek']);
    expect(history.last.performedOn, DateTime(2026, 9, 30));

    await repo.deleteCompleted(history.last);
    expect((await repo.watchCompleted(uid).first).map((w) => w.id), [
      'today',
      'yesterday',
    ]);
  });

  group('the order of writes', () {
    test(
      'a write is issued only after the previous one is in the cache',
      () async {
        final db = FakeFirebaseFirestore();
        final doc = db.doc('users/$uid/programs/p1');
        final events = <String>[];
        // Like the Android plugin, the first write reaches the cache late.
        final first = sendWrite(
          landsIn: doc,
          writeId: 'a',
          write: () async {
            events.add('first issued');
            await Future<void>.delayed(const Duration(milliseconds: 50));
            await doc.set({'name': 'old', writeIdField: 'a'});
            events.add('first in cache');
          },
          onRejected: (_, _) {},
        );
        final second = sendWrite(
          landsIn: doc,
          writeId: 'b',
          write: () {
            events.add('second issued');
            return doc.set({'name': 'new', writeIdField: 'b'});
          },
          onRejected: (_, _) {},
        );
        final removed = sendWrite(
          landsIn: doc,
          writeId: null,
          write: () {
            events.add('delete issued');
            return doc.delete();
          },
          onRejected: (_, _) {},
        );
        await Future.wait([first, second, removed]);
        expect((await doc.get()).exists, isFalse);
        expect(events, [
          'first issued',
          'first in cache',
          'second issued',
          'delete issued',
        ]);
      },
    );

    test(
      'a refused write is reported and does not stop the next one',
      () async {
        final db = FakeFirebaseFirestore();
        final doc = db.doc('users/$uid/programs/p1');
        final rejected = <Object>[];
        await doc.set({writeIdField: 'a'});
        await sendWrite(
          landsIn: doc,
          writeId: 'a',
          write: () async => throw StateError('refused'),
          onRejected: (e, _) => rejected.add(e),
        );
        await sendWrite(
          landsIn: doc,
          writeId: 'b',
          write: () => doc.set({writeIdField: 'b'}),
          onRejected: (e, _) => rejected.add(e),
        );
        expect(rejected.single, isStateError);
        expect((await doc.get()).data()![writeIdField], 'b');
      },
    );

    test('results recorded right after the start are kept in order', () async {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreWorkoutRepository(db);
      var workout = startWorkout(
        id: 'w1',
        traineeId: uid,
        now: DateTime.utc(2026, 10, 7, 18),
        newId: () => newFirestoreId(db),
        catalog: catalog,
        languageCode: 'ru',
        program: program,
        day: program.days.first,
      );
      // Nothing is awaited between the two, as a quick double action does.
      final started = repo.start(workout);
      workout = recordSummary(
        workout,
        workout.exercises.first.id,
        setCount: 1,
        fact: const SetValues(reps: 8, weightKg: 60),
        newId: () => newFirestoreId(db),
        now: DateTime.utc(2026, 10, 7, 18, 5),
      );
      await Future.wait([started, repo.save(workout)]);
      final stored = workoutFromMap(
        'w1',
        (await db.doc('users/$uid/workouts/w1').get()).data()!,
      );
      expect(
        stored.exercises.first.sets.first.fact,
        const SetValues(reps: 8, weightKg: 60),
      );
    });
  });
}
