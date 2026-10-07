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
  query,
  where,
  setDoc,
  serverTimestamp,
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

// --- Coach and trainee ------------------------------------------------------

const soon = () => Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 3600 * 1000));
const invitation = (inviterId, inviterRole, overrides = {}) => ({
  inviterId,
  inviterName: inviterId,
  inviterRole,
  createdAt: Timestamp.now(),
  expiresAt: soon(),
  ...overrides,
});
const link = (coachId, traineeId, inviteCode, overrides = {}) => ({
  coachId,
  traineeId,
  status: 'active',
  coachName: coachId,
  traineeName: traineeId,
  inviteCode,
  createdAt: Timestamp.now(),
  ...overrides,
});
const invite = (uid, role, code = 'K7M42Q', overrides = {}) =>
  setDoc(doc(dbOf(uid), `invitations/${code}`), invitation(uid, role, overrides));
// The acceptor writes the link and uses the invitation up in one batch.
const accept = (uid, coachId, traineeId, code = 'K7M42Q', overrides = {}) => {
  const db = dbOf(uid);
  return writeBatch(db)
    .set(doc(db, `links/${coachId}_${traineeId}`), link(coachId, traineeId, code, overrides))
    .delete(doc(db, `invitations/${code}`))
    .commit();
};
const setStatus = (uid, coachId, traineeId, status) =>
  setDoc(doc(dbOf(uid), `links/${coachId}_${traineeId}`), { status }, { merge: true });

test('an invitation is created by its author and looked up by code', async () => {
  await assertSucceeds(invite('coach', 'coach'));
  await assertSucceeds(getDoc(doc(dbOf('athlete'), 'invitations/K7M42Q')));
  await assertFails(getDoc(doc(dbOf(null), 'invitations/K7M42Q')));
  // Codes cannot be browsed, and a taken code cannot be overwritten.
  await assertFails(getDocs(collection(dbOf('athlete'), 'invitations')));
  await assertFails(invite('athlete', 'coach'));
  await assertFails(invite('coach', 'coach', 'k7m42q'));
  await assertFails(invite('coach', 'coach', 'K7M40Q'));
  await assertFails(invite('coach', 'boss', 'AAAAAA'));
  await assertFails(
    setDoc(doc(dbOf('coach'), 'invitations/AAAAAA'), invitation('other', 'coach')),
  );
  await assertFails(
    invite('coach', 'coach', 'AAAAAA', {
      expiresAt: Timestamp.fromDate(new Date(Date.now() + 30 * 24 * 3600 * 1000)),
    }),
  );
  await assertFails(deleteDoc(doc(dbOf('athlete'), 'invitations/K7M42Q')));
  await assertSucceeds(deleteDoc(doc(dbOf('coach'), 'invitations/K7M42Q')));
});

test('a link appears only by accepting an invitation, in either role', async () => {
  // No invitation, no link.
  await assertFails(
    setDoc(doc(dbOf('athlete'), 'links/coach_athlete'), link('coach', 'athlete', 'K7M42Q')),
  );
  await assertSucceeds(invite('coach', 'coach'));
  // The invitation must be used up, the roles must be the invited ones, and
  // only the two people involved take part.
  await assertFails(
    setDoc(doc(dbOf('athlete'), 'links/coach_athlete'), link('coach', 'athlete', 'K7M42Q')),
  );
  await assertFails(accept('athlete', 'athlete', 'coach'));
  await assertFails(accept('other', 'coach', 'athlete'));
  await assertFails(accept('coach', 'coach', 'athlete'));
  await assertFails(accept('athlete', 'coach', 'athlete', 'K7M42Q', { status: 'readOnly' }));
  await assertFails(accept('athlete', 'coach', 'athlete', 'K7M42Q', { coachName: 'Someone' }));
  await assertSucceeds(accept('athlete', 'coach', 'athlete'));
  // Used once.
  await assertFails(accept('other', 'coach', 'other'));

  // The trainee invites, the coach accepts.
  await assertSucceeds(invite('athlete', 'trainee', 'BBBBBB'));
  await assertFails(accept('coach2', 'athlete', 'coach2', 'BBBBBB'));
  await assertSucceeds(accept('coach2', 'coach2', 'athlete', 'BBBBBB'));

  await assertSucceeds(getDoc(doc(dbOf('coach'), 'links/coach_athlete')));
  await assertSucceeds(getDoc(doc(dbOf('athlete'), 'links/coach_athlete')));
  await assertFails(getDoc(doc(dbOf('coach2'), 'links/coach_athlete')));

  // Each side lists its own links, as the app does, and nobody else's.
  const linksOf = (uid, field, value) =>
    getDocs(query(collection(dbOf(uid), 'links'), where(field, '==', value)));
  await assertSucceeds(linksOf('athlete', 'traineeId', 'athlete'));
  await assertSucceeds(linksOf('coach2', 'coachId', 'coach2'));
  await assertFails(linksOf('other', 'traineeId', 'athlete'));
  await assertFails(linksOf('coach', 'coachId', 'coach2'));
  await assertFails(getDocs(collection(dbOf('athlete'), 'links')));
});

test('an expired or own invitation makes no link', async () => {
  await env.withSecurityRulesDisabled((context) =>
    setDoc(
      doc(context.firestore(), 'invitations/CCCCCC'),
      invitation('coach', 'coach', { expiresAt: Timestamp.fromDate(new Date(Date.now() - 1000)) }),
    ),
  );
  await assertFails(accept('athlete', 'coach', 'athlete', 'CCCCCC'));
  await assertSucceeds(invite('coach', 'coach', 'DDDDDD'));
  await assertFails(accept('coach', 'coach', 'coach', 'DDDDDD'));
});

test('only the trainee changes a link, and only downwards', async () => {
  await assertSucceeds(invite('coach', 'coach'));
  await assertSucceeds(accept('athlete', 'coach', 'athlete'));
  await assertFails(setStatus('coach', 'coach', 'athlete', 'removed'));
  await assertFails(setStatus('other', 'coach', 'athlete', 'removed'));
  await assertSucceeds(setStatus('athlete', 'coach', 'athlete', 'readOnly'));
  // Back to active only through a new invitation.
  await assertFails(setStatus('athlete', 'coach', 'athlete', 'active'));
  await assertFails(
    setDoc(doc(dbOf('athlete'), 'links/coach_athlete'), { coachName: 'X' }, { merge: true }),
  );
  await assertSucceeds(setStatus('athlete', 'coach', 'athlete', 'removed'));
  await assertFails(deleteDoc(doc(dbOf('athlete'), 'links/coach_athlete')));

  await assertSucceeds(invite('coach', 'coach', 'EEEEEE'));
  await assertSucceeds(accept('athlete', 'coach', 'athlete', 'EEEEEE'));
});

test('a coach sees a trainee\'s workouts until removed', async () => {
  await assertSucceeds(invite('coach', 'coach'));
  await assertSucceeds(accept('athlete', 'coach', 'athlete'));
  const own = dbOf('athlete');
  await assertSucceeds(start(own, 'w1', workout({ supervisorCoachId: 'coach' })));

  const coach = dbOf('coach');
  await assertSucceeds(getDoc(workoutRef(coach, 'w1')));
  await assertSucceeds(getDocs(collection(coach, 'users/athlete/workouts')));
  // Seeing is all: no writing, and nothing else of the trainee's.
  await assertFails(setDoc(workoutRef(coach, 'w1'), workout({ supervisorCoachId: 'coach' })));
  await assertFails(deleteDoc(workoutRef(coach, 'w1')));
  await assertFails(getDoc(doc(coach, 'users/athlete')));
  await assertFails(getDocs(collection(coach, 'users/athlete/programs')));
  await assertFails(getDoc(pointerRef(coach)));
  // The trainee does not see the coach's workouts.
  await assertFails(getDocs(collection(own, 'users/coach/workouts')));

  await assertSucceeds(setStatus('athlete', 'coach', 'athlete', 'readOnly'));
  await assertSucceeds(getDocs(collection(coach, 'users/athlete/workouts')));
  await assertSucceeds(setStatus('athlete', 'coach', 'athlete', 'removed'));
  await assertFails(getDoc(workoutRef(coach, 'w1')));
  await assertFails(getDocs(collection(coach, 'users/athlete/workouts')));
});

test('a workout names only the active coach, once', async () => {
  const own = dbOf('athlete');
  await assertFails(start(own, 'w1', workout({ supervisorCoachId: 'coach' })));
  await assertSucceeds(invite('coach', 'coach'));
  await assertSucceeds(accept('athlete', 'coach', 'athlete'));
  await assertSucceeds(start(own, 'w1', workout({ supervisorCoachId: 'coach' })));
  await assertFails(setDoc(workoutRef(own, 'w1'), workout({ supervisorCoachId: null })));
  await assertFails(setDoc(workoutRef(own, 'w1'), workout({ supervisorCoachId: 'other' })));
  // History keeps its supervisor even after the coach is removed.
  await assertSucceeds(setStatus('athlete', 'coach', 'athlete', 'removed'));
  await assertSucceeds(
    writeBatch(own)
      .set(workoutRef(own, 'w1'), completed({ supervisorCoachId: 'coach' }))
      .set(pointerRef(own), { workoutId: null })
      .commit(),
  );
  await assertFails(start(own, 'w2', workout({ supervisorCoachId: 'coach' })));
  await assertSucceeds(start(own, 'w2'));
});

// --- Program assignments ----------------------------------------------------
const programRef = (db, coach = 'coach', id = 'p1') => doc(db, 'users/' + coach + '/programs/' + id);
const assignmentRef = (db, coach = 'coach', id = 'p1') => doc(db, 'users/athlete/assignments/' + coach + '_' + id);
const assignment = (overrides = {}) => ({
  coachId: 'coach', traineeId: 'athlete', programId: 'p1',
  assignedAt: serverTimestamp(), ...overrides,
});
async function setupAssignment() {
  await invite('coach', 'coach');
  await accept('athlete', 'coach', 'athlete');
  await setDoc(programRef(dbOf('coach')), { authorId: 'coach', name: 'Plan', days: [] });
  await setDoc(doc(dbOf('coach'), 'users/coach/exercises/custom~one'), {
    id: 'custom/one', names: { ru: 'Тяга' }, muscleGroup: 'lats',
    measure: 'reps', usesBodyWeight: false,
  });
}

test('only the active coach assigns their existing program to a linked trainee', async () => {
  await setupAssignment();
  const coach = dbOf('coach');
  for (const uid of ['athlete', 'other', null]) {
    await assertFails(setDoc(assignmentRef(dbOf(uid)), assignment()));
  }
  await assertFails(setDoc(assignmentRef(coach, 'coach', 'missing'), assignment({ programId: 'missing' })));
  await assertFails(setDoc(assignmentRef(coach), assignment({ traineeId: 'other' })));
  await assertFails(setDoc(assignmentRef(coach), assignment({ coachId: 'other' })));
  await assertFails(setDoc(assignmentRef(coach), assignment({ extra: true })));
  await assertFails(setDoc(doc(coach, 'users/athlete/assignments/wrong'), assignment()));
  await assertFails(setDoc(assignmentRef(coach), assignment({ assignedAt: startedAt })));
  await assertSucceeds(setDoc(assignmentRef(coach), assignment()));
  await assertSucceeds(setDoc(assignmentRef(coach), assignment()));
  await setStatus('athlete', 'coach', 'athlete', 'readOnly');
  await assertFails(setDoc(assignmentRef(coach), assignment()));
  await setStatus('athlete', 'coach', 'athlete', 'removed');
  await assertFails(setDoc(assignmentRef(coach), assignment()));
});

test('assignment allows only the selected program, without write access', async () => {
  await setupAssignment();
  const athlete = dbOf('athlete');
  await assertFails(getDoc(programRef(athlete)));
  await setDoc(assignmentRef(dbOf('coach')), assignment());
  await assertSucceeds(getDoc(programRef(athlete)));
  await assertSucceeds(getDocs(collection(athlete, 'users/coach/exercises')));
  await assertSucceeds(getDocs(collection(athlete, 'users/athlete/assignments')));
  await assertFails(getDocs(collection(athlete, 'users/coach/programs')));
  await assertFails(getDoc(programRef(athlete, 'coach', 'p2')));
  await assertFails(setDoc(programRef(athlete), { authorId: 'coach', name: 'Changed', days: [] }));
  await assertFails(deleteDoc(programRef(athlete)));
  await assertFails(setDoc(doc(athlete, 'users/coach/exercises/custom~one'), { names: { ru: 'X' } }, { merge: true }));
  await assertFails(deleteDoc(doc(athlete, 'users/coach/exercises/custom~one')));
  await assertFails(deleteDoc(assignmentRef(athlete)));
  for (const uid of ['other', null]) {
    await assertFails(getDoc(programRef(dbOf(uid))));
    await assertFails(getDoc(assignmentRef(dbOf(uid))));
    await assertFails(getDocs(collection(dbOf(uid), 'users/coach/exercises')));
  }
  // Coach may list only their assignments, not those by a different coach.
  await assertSucceeds(getDocs(query(collection(dbOf('coach'), 'users/athlete/assignments'), where('coachId', '==', 'coach'))));
  await assertFails(getDocs(collection(dbOf('coach'), 'users/athlete/assignments')));
});

test('deactivation keeps program access; removal revokes program and exercises', async () => {
  await setupAssignment();
  const athlete = dbOf('athlete');
  const coach = dbOf('coach');
  await setDoc(assignmentRef(coach), assignment());
  await setStatus('athlete', 'coach', 'athlete', 'readOnly');
  await assertSucceeds(getDoc(programRef(athlete)));
  await assertSucceeds(getDocs(collection(athlete, 'users/coach/exercises')));
  await assertSucceeds(getDocs(query(collection(coach, 'users/athlete/assignments'), where('coachId', '==', 'coach'))));
  await setStatus('athlete', 'coach', 'athlete', 'removed');
  await assertFails(getDoc(programRef(athlete)));
  await assertFails(getDocs(collection(athlete, 'users/coach/exercises')));
  await assertFails(getDoc(assignmentRef(coach)));
});

test('same program ID from different coaches keeps separate assignments', async () => {
  await setupAssignment();
  await setDoc(assignmentRef(dbOf('coach')), assignment());
  await invite('coach2', 'coach', 'BBBBBB');
  await accept('athlete', 'coach2', 'athlete', 'BBBBBB');
  await setStatus('athlete', 'coach', 'athlete', 'readOnly');
  const coach2 = dbOf('coach2');
  await setDoc(programRef(coach2, 'coach2'), { authorId: 'coach2', name: 'Other', days: [] });
  await assertSucceeds(setDoc(assignmentRef(coach2, 'coach2'), assignment({ coachId: 'coach2' })));
  await assertFails(setDoc(assignmentRef(coach2), assignment({ coachId: 'coach2' })));
  await assertSucceeds(getDoc(programRef(dbOf('athlete'))));
  await assertSucceeds(getDoc(programRef(dbOf('athlete'), 'coach2')));
  await assertFails(getDoc(programRef(dbOf('coach2'))));
});

test('supervisor name is retained when a workout is edited', async () => {
  await setupAssignment();
  const db = dbOf('athlete');
  await start(db, 'w', workout({ supervisorCoachId: 'coach', supervisorCoachName: 'Сергей' }));
  await assertFails(setDoc(workoutRef(db, 'w'), workout({ supervisorCoachId: 'coach', supervisorCoachName: 'Другой' })));
  await assertSucceeds(setDoc(workoutRef(db, 'w'), workout({ supervisorCoachId: 'coach', supervisorCoachName: 'Сергей', exercises: [{ id: 'e' }] })));
});

test('a removed coach who is added again sees the earlier workouts and plans', async () => {
  await setupAssignment();
  const own = dbOf('athlete');
  const coach = dbOf('coach');
  await setDoc(assignmentRef(coach), assignment());
  await start(own, 'w1', workout({ supervisorCoachId: 'coach', supervisorCoachName: 'coach' }));
  await writeBatch(own)
    .set(workoutRef(own, 'w1'), completed({ supervisorCoachId: 'coach', supervisorCoachName: 'coach' }))
    .set(pointerRef(own), { workoutId: null })
    .commit();

  await setStatus('athlete', 'coach', 'athlete', 'removed');
  await assertFails(getDoc(workoutRef(coach, 'w1')));
  // The trainee keeps the workout, the coach's name on it and the assignment.
  const kept = await assertSucceeds(getDoc(workoutRef(own, 'w1')));
  if (kept.data().supervisorCoachId !== 'coach') throw new Error('supervisor lost');
  await assertSucceeds(getDoc(assignmentRef(own)));
  await assertFails(getDoc(programRef(own)));

  await assertSucceeds(invite('coach', 'coach', 'EEEEEE'));
  await assertSucceeds(accept('athlete', 'coach', 'athlete', 'EEEEEE'));
  const again = await assertSucceeds(getDocs(collection(coach, 'users/athlete/workouts')));
  if (again.docs.length !== 1 || again.docs[0].data().supervisorCoachId !== 'coach') {
    throw new Error('earlier workout not returned');
  }
  await assertSucceeds(getDoc(programRef(own)));
  await assertSucceeds(getDocs(query(collection(coach, 'users/athlete/assignments'), where('coachId', '==', 'coach'))));
  await assertSucceeds(setDoc(assignmentRef(coach), assignment()));
});

test('a completed workout is deleted only by its owner, with the day it counts for kept free', async () => {
  await assertSucceeds(invite('coach', 'coach'));
  await assertSucceeds(accept('athlete', 'coach', 'athlete'));
  const own = dbOf('athlete');
  await start(own, 'w1');
  // Still in progress: it goes only together with the pointer.
  await assertFails(deleteDoc(workoutRef(own, 'w1')));
  await assertSucceeds(
    writeBatch(own)
      .set(workoutRef(own, 'w1'), completed({ performedOn: '2026-09-30' }))
      .set(pointerRef(own), { workoutId: null })
      .commit(),
  );
  await assertSucceeds(setDoc(workoutRef(own, 'w1'), completed({ performedOn: '2026-10-01' })));
  await assertFails(deleteDoc(workoutRef(dbOf('coach'), 'w1')));
  await assertFails(deleteDoc(workoutRef(dbOf('other'), 'w1')));
  await assertSucceeds(deleteDoc(workoutRef(own, 'w1')));
  await assertSucceeds(start(own, 'w2'));
});

