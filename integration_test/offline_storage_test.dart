// Offline workout storage on a real device SDK, against the local Firebase
// emulators only — production is never contacted. Two runs, the second one
// standing for the app after a restart; see CLAUDE.md for the commands.
//   PHASE=first    start, record and complete without a network, then sync;
//                  ends offline with an unsent change.
//   PHASE=restart  the workout in progress and the unsent change are back.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:progressbar_app/data/firestore_codec.dart';
import 'package:progressbar_app/data/firestore_writes.dart';
import 'package:progressbar_app/data/workout_repository.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/domain/workout_logic.dart';
import 'package:progressbar_app/firebase_options.dart';

const phase = String.fromEnvironment('PHASE', defaultValue: 'first');
const server = GetOptions(source: Source.server);
const fact = SetValues(reps: 8, weightKg: 60);

const bench = Exercise(
  id: 'free-exercise-db/Barbell_Bench_Press_-_Medium_Grip',
  names: {'en': 'Bench press'},
  muscleGroup: 'chest',
);
const program = Program(
  id: 'p1',
  authorId: 'unused',
  name: 'Upper',
  days: [
    ProgramDay(
      id: 'd1',
      name: 'Day 1',
      exercises: [
        ProgramExercise(
          id: 'pe1',
          exerciseId: 'free-exercise-db/Barbell_Bench_Press_-_Medium_Grip',
          sets: [SetValues(reps: 8, weightKg: 57.5)],
        ),
      ],
    ),
  ],
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseFirestore db;
  late FirebaseAuth auth;
  final rejected = <Object>[];
  FirestoreWorkoutRepository repository() =>
      FirestoreWorkoutRepository(db, onRejected: (e, _) => rejected.add(e));

  Workout started(String id, String uid) => startWorkout(
    id: id,
    traineeId: uid,
    now: DateTime.now(),
    newId: () => newFirestoreId(db),
    catalog: {bench.id: bench},
    languageCode: 'en',
    program: program,
    day: program.days.first,
  );

  Workout withFact(Workout workout) => recordSummary(
    workout,
    workout.exercises.first.id,
    setCount: 1,
    fact: fact,
    newId: () => newFirestoreId(db),
    now: DateTime.now(),
  );

  Future<Workout?> onServer(String uid, String id) async {
    final snap = await db.doc('users/$uid/workouts/$id').get(server);
    return snap.exists ? workoutFromMap(id, snap.data()!) : null;
  }

  Future<String?> pointerOnServer(String uid) async =>
      (await db.doc('users/$uid/state/activeWorkout').get(server))
              .data()?['workoutId']
          as String?;

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Before anything else touches Firebase: from here on only the emulators.
    db = FirebaseFirestore.instance..useFirestoreEmulator('localhost', 8080);
    auth = FirebaseAuth.instance;
    await auth.useAuthEmulator('localhost', 9099);
  });

  testWidgets('offline workout is stored, guarded and synced', (tester) async {
    await auth.signOut();
    final uid = (await auth.signInAnonymously()).user!.uid;
    final repo = repository();
    // Online once after sign-in, as the home screen does.
    expect(await repo.watchActive(uid).first, isNull);

    await db.disableNetwork();
    var first = started('w1', uid);
    await repo.start(first);
    await expectLater(
      repo.start(started('w2', uid)),
      throwsA(isA<ActiveWorkoutExists>()),
    );
    first = withFact(first);
    await repo.save(first);

    // A fresh repository knows only what the device cache holds.
    final cached = await repository().watchActive(uid).first;
    expect(cached?.id, 'w1');
    expect(cached!.exercises.single.sets.single.fact, fact);
    expect(
      cached.exercises.single.sets.single.plan,
      const SetValues(reps: 8, weightKg: 57.5),
    );
    await expectLater(
      repository().start(started('w2', uid)),
      throwsA(isA<ActiveWorkoutExists>()),
    );

    await repo.save(completeWorkout(first, now: DateTime.now()));
    expect(await repository().watchActive(uid).first, isNull);
    expect((await repo.watchCompleted(uid).first).single.id, 'w1');
    var second = started('w2', uid);
    await repo.start(second);

    // Four queued writes go out in order once the network is back.
    await db.enableNetwork();
    await db.waitForPendingWrites();
    expect(rejected, isEmpty);
    final synced = await onServer(uid, 'w1');
    expect(synced!.isCompleted, isTrue);
    expect(synced.exercises.single.sets.single.fact, fact);
    expect((await onServer(uid, 'w2'))!.isCompleted, isFalse);
    expect(await pointerOnServer(uid), 'w2');

    // The server itself refuses a second workout in progress.
    await expectLater(
      db
          .doc('users/$uid/workouts/rogue')
          .set(workoutToMap(started('rogue', uid))),
      throwsA(
        isA<FirebaseException>().having(
          (e) => e.code,
          'code',
          'permission-denied',
        ),
      ),
    );
    expect(await onServer(uid, 'rogue'), isNull);

    // Leave an unsent change behind for the restart run.
    await db.disableNetwork();
    second = withFact(second);
    await repo.save(second);
    expect(
      (await repository().watchActive(uid).first)!
          .exercises
          .single
          .sets
          .single
          .fact,
      fact,
    );
    // ignore: avoid_print
    print('OFFLINE_STORAGE first run done for $uid');
  }, skip: phase != 'first');

  testWidgets('after a restart the workout and unsent change are back', (
    tester,
  ) async {
    final uid = auth.currentUser?.uid;
    expect(uid, isNotNull, reason: 'Run PHASE=first before PHASE=restart.');
    final repo = repository();

    final restored = await repo.watchActive(uid!).first;
    expect(restored?.id, 'w2');
    expect(restored!.exercises.single.sets.single.fact, fact);
    await expectLater(
      repo.start(started('w3', uid)),
      throwsA(isA<ActiveWorkoutExists>()),
    );

    // The change made offline before the restart reaches the server.
    await db.waitForPendingWrites();
    expect(rejected, isEmpty);
    final synced = await onServer(uid, 'w2');
    expect(synced!.isCompleted, isFalse);
    expect(synced.exercises.single.sets.single.fact, fact);

    await repo.cancel(restored);
    await db.waitForPendingWrites();
    expect(rejected, isEmpty);
    expect(await onServer(uid, 'w2'), isNull);
    expect(await pointerOnServer(uid), isNull);
    expect((await onServer(uid, 'w1'))!.isCompleted, isTrue);
  }, skip: phase != 'restart');
}
