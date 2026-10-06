// Access rules, checked against the local Firestore emulator:
//   npx -y firebase-tools@latest emulators:exec --only firestore \
//     --project demo-progressbar "npm --prefix firestore_tests test"
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  collection,
  setDoc,
  Timestamp,
  writeBatch,
} from 'firebase/firestore';

let env;
const startedAt = Timestamp.fromDate(new Date('2026-10-06T18:00:00Z'));

const workout = (overrides = {}) => ({
  schemaVersion: 1,
  traineeId: 'athlete',
  supervisorCoachId: null,
  status: 'inProgress',
  startedAt,
  completedAt: null,
  exercises: [],
  ...overrides,
});
const completed = (overrides = {}) =>
  workout({ status: 'completed', completedAt: startedAt, ...overrides });

const dbOf = (uid) =>
  (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();
const workoutRef = (db, id, uid = 'athlete') => doc(db, `users/${uid}/workouts/${id}`);
const pointerRef = (db, uid = 'athlete') => doc(db, `users/${uid}/state/activeWorkout`);

const start = (db, id, data = workout()) =>
  writeBatch(db).set(workoutRef(db, id), data).set(pointerRef(db), { workoutId: id }).commit();
const complete = (db, id) =>
  writeBatch(db).set(workoutRef(db, id), completed()).set(pointerRef(db), { workoutId: null }).commit();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-progressbar',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});
beforeEach(() => env.clearFirestore());
after(() => env.cleanup());

test('a user reads and writes only their own profile', async () => {
  const own = dbOf('athlete');
  await assertSucceeds(setDoc(doc(own, 'users/athlete'), { name: 'A', phone: '+7' }));
  await assertSucceeds(getDoc(doc(own, 'users/athlete')));
  await assertFails(getDoc(doc(dbOf('other'), 'users/athlete')));
  await assertFails(setDoc(doc(dbOf('other'), 'users/athlete'), { name: 'X' }));
  await assertFails(getDoc(doc(dbOf(null), 'users/athlete')));
});

test('programs, exercises and workouts are closed to everyone else', async () => {
  const own = dbOf('athlete');
  await assertSucceeds(
    setDoc(doc(own, 'users/athlete/programs/p1'), { authorId: 'athlete', name: 'A', days: [] }),
  );
  await assertSucceeds(
    setDoc(doc(own, 'users/athlete/exercises/custom~1'), {
      id: 'custom/1',
      names: { ru: 'Планка' },
      muscleGroup: 'abdominals',
      measure: 'time',
      usesBodyWeight: false,
    }),
  );
  await assertSucceeds(start(own, 'w1'));

  for (const uid of ['other', null]) {
    const db = dbOf(uid);
    for (const name of ['programs', 'exercises', 'workouts', 'state']) {
      await assertFails(getDocs(collection(db, `users/athlete/${name}`)));
    }
    await assertFails(getDoc(doc(db, 'users/athlete/programs/p1')));
    await assertFails(getDoc(workoutRef(db, 'w1')));
    await assertFails(setDoc(workoutRef(db, 'w1'), workout()));
    await assertFails(deleteDoc(doc(db, 'users/athlete/programs/p1')));
    await assertFails(
      setDoc(doc(db, 'users/athlete/programs/p2'), { authorId: 'athlete', name: 'B', days: [] }),
    );
  }
  await assertSucceeds(getDocs(collection(own, 'users/athlete/workouts')));
  await assertSucceeds(getDocs(collection(own, 'users/athlete/programs')));
});

test('malformed programs and exercises are refused', async () => {
  const own = dbOf('athlete');
  await assertFails(
    setDoc(doc(own, 'users/athlete/programs/p1'), { authorId: 'coach', name: 'A', days: [] }),
  );
  await assertFails(setDoc(doc(own, 'users/athlete/programs/p1'), { authorId: 'athlete', name: 'A' }));
  await assertFails(
    setDoc(doc(own, 'users/athlete/exercises/custom~1'), {
      id: 'custom/1',
      names: { ru: 'Планка' },
      muscleGroup: 'abdominals',
      measure: 'distance',
      usesBodyWeight: false,
    }),
  );
  await assertFails(setDoc(doc(own, 'users/athlete/unknown/x'), { a: 1 }));
});

test('a workout starts only together with the pointer', async () => {
  const db = dbOf('athlete');
  await assertFails(setDoc(workoutRef(db, 'w1'), workout()));
  await assertFails(setDoc(pointerRef(db), { workoutId: 'w1' }));
  await assertSucceeds(start(db, 'w1'));
});

test('a second workout cannot start while one is in progress', async () => {
  const db = dbOf('athlete');
  await assertSucceeds(start(db, 'w1'));
  await assertFails(start(db, 'w2'));
  await assertFails(setDoc(workoutRef(db, 'w2'), workout()));
  // Not even by pretending the first one never existed.
  await assertFails(setDoc(pointerRef(db), { workoutId: null }));
  await assertFails(deleteDoc(pointerRef(db)));
  await assertFails(deleteDoc(workoutRef(db, 'w1')));
});

test('recording, completing and starting the next one', async () => {
  const db = dbOf('athlete');
  await assertSucceeds(start(db, 'w1'));
  await assertSucceeds(setDoc(workoutRef(db, 'w1'), workout({ exercises: [{ id: 'e1' }] })));
  // Completion must free the slot in the same batch.
  await assertFails(setDoc(workoutRef(db, 'w1'), completed()));
  await assertSucceeds(complete(db, 'w1'));
  await assertSucceeds(start(db, 'w2'));
  // Correcting history does not touch the workout in progress.
  await assertSucceeds(setDoc(workoutRef(db, 'w1'), completed({ comment: 'fix', editedAt: startedAt })));
  // A completed workout cannot be reopened, with or without the pointer.
  await assertFails(setDoc(workoutRef(db, 'w1'), workout()));
  await assertSucceeds(complete(db, 'w2'));
  await assertFails(start(db, 'w1'));
});

test('a workout written straight into history is refused', async () => {
  const db = dbOf('athlete');
  await assertFails(setDoc(workoutRef(db, 'w1'), completed()));
});

test('cancelling removes the workout and the pointer together', async () => {
  const db = dbOf('athlete');
  await assertSucceeds(start(db, 'w1'));
  await assertSucceeds(
    writeBatch(db).delete(workoutRef(db, 'w1')).set(pointerRef(db), { workoutId: null }).commit(),
  );
  await assertSucceeds(start(db, 'w2'));
});

test('workout fields that must not change are protected', async () => {
  const db = dbOf('athlete');
  await assertFails(start(db, 'w1', workout({ traineeId: 'other' })));
  await assertFails(start(db, 'w1', workout({ supervisorCoachId: 'coach' })));
  await assertFails(start(db, 'w1', workout({ status: 'cancelled' })));
  await assertFails(start(db, 'w1', workout({ startedAt: 'yesterday' })));
  await assertSucceeds(start(db, 'w1'));
  await assertFails(
    setDoc(workoutRef(db, 'w1'), workout({ startedAt: Timestamp.fromDate(new Date('2026-01-01')) })),
  );
  await assertFails(setDoc(pointerRef(db), { workoutId: 'w1', extra: true }));
});

test('queued offline writes are accepted in the order they were made', async () => {
  // Start, record, complete, start again, cancel — as the app replays them.
  const db = dbOf('athlete');
  await assertSucceeds(start(db, 'w1'));
  await assertSucceeds(setDoc(workoutRef(db, 'w1'), workout({ exercises: [{ id: 'e1' }] })));
  await assertSucceeds(complete(db, 'w1'));
  await assertSucceeds(start(db, 'w2'));
  await assertSucceeds(
    writeBatch(db).delete(workoutRef(db, 'w2')).set(pointerRef(db), { workoutId: null }).commit(),
  );
  await assertSucceeds(start(db, 'w3'));
});
