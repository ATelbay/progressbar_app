import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models.dart';
import '../domain/workout_logic.dart';
import 'firestore_codec.dart';
import 'firestore_writes.dart';

/// A workout is already in progress; a second one cannot be started.
class ActiveWorkoutExists implements Exception {
  const ActiveWorkoutExists(this.workoutId);

  final String workoutId;

  @override
  String toString() => 'ActiveWorkoutExists($workoutId)';
}

/// Nothing is known yet about this user's active workout: the device has not
/// reached the server since sign-in and there is no network now.
class WorkoutStoreUnavailable implements Exception {
  const WorkoutStoreUnavailable();
}

/// Workouts belong to the trainee: `users/{traineeId}/workouts/{id}`.
///
/// `users/{traineeId}/state/activeWorkout` names the one workout in progress.
/// It changes only together with that workout, in one batch, and the access
/// rules refuse an in-progress workout it does not name — that is what keeps
/// «one active workout at a time» true on the server as well.
abstract interface class WorkoutRepository {
  /// The workout in progress, or null. Survives an app restart.
  Stream<Workout?> watchActive(String uid);

  /// Completed workouts, newest first.
  Stream<List<Workout>> watchCompleted(String uid);

  /// All workouts, including the current one, without reading private state.
  Stream<List<Workout>> watchAll(String uid);

  /// Stores a just-started workout. Throws [ActiveWorkoutExists] if another
  /// one is in progress.
  Future<void> start(Workout workout);

  /// Stores the current state: a recorded set, completion, or a correction of
  /// a completed workout.
  Future<void> save(Workout workout);

  /// Discards the workout in progress.
  Future<void> cancel(Workout workout);

  /// Removes a completed workout from history for good.
  Future<void> deleteCompleted(Workout workout);
}

class FirestoreWorkoutRepository implements WorkoutRepository {
  FirestoreWorkoutRepository(this._db, {this.onRejected = logRejectedWrite});

  final FirebaseFirestore _db;
  final WriteRejected onRejected;
  Future<void> _last = Future.value();

  /// The active workout per user as last read or written here. A write
  /// reaches the cache a moment after it is issued, so a check made right
  /// after it must not depend on the cache.
  final _known = <String, String?>{};

  CollectionReference<Map<String, dynamic>> _workouts(String uid) =>
      _db.collection('users').doc(uid).collection('workouts');

  DocumentReference<Map<String, dynamic>> _pointer(String uid) =>
      _db.collection('users').doc(uid).collection('state').doc('activeWorkout');

  /// One operation at a time, so a double tap on «start» cannot pass the
  /// check twice before the first write lands.
  Future<T> _serially<T>(Future<T> Function() action) {
    final result = _last.then((_) => action());
    _last = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Read from the local cache first: it is instant, works offline and, with
  /// one device per user, is never behind the server.
  Future<String?> _activeId(String uid) async {
    if (_known.containsKey(uid)) return _known[uid];
    DocumentSnapshot<Map<String, dynamic>> snap;
    try {
      snap = await _pointer(uid).get(const GetOptions(source: Source.cache));
    } on FirebaseException {
      try {
        snap = await _pointer(uid).get(const GetOptions(source: Source.server));
      } on FirebaseException {
        throw const WorkoutStoreUnavailable();
      }
    }
    return _known[uid] = snap.data()?['workoutId'] as String?;
  }

  void _setPointer(WriteBatch batch, String uid, String? workoutId) {
    _known[uid] = workoutId;
    batch.set(_pointer(uid), {
      'workoutId': workoutId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// A refused write is rolled back in the cache, so what is remembered here
  /// may be wrong: read it again next time.
  ///
  /// Every batch here sets or deletes [workout]'s document, and the pointer
  /// changes in the same batch, so the workout shows that the batch is in
  /// the cache. [writeId] is null when the batch deletes the workout.
  Future<void> _send(WriteBatch batch, Workout workout, String? writeId) =>
      sendWrite(
        landsIn: _workouts(workout.traineeId).doc(workout.id),
        writeId: writeId,
        write: batch.commit,
        onRejected: (error, stack) {
          _known.remove(workout.traineeId);
          onRejected(error, stack);
        },
      );

  /// Returns the ID of the write, for [_send].
  String _setWorkout(WriteBatch batch, Workout workout) {
    final writeId = newFirestoreId(_db);
    batch.set(_workouts(workout.traineeId).doc(workout.id), {
      ...workoutToMap(workout),
      'updatedAt': FieldValue.serverTimestamp(),
      writeIdField: writeId,
    });
    return writeId;
  }

  @override
  Stream<Workout?> watchActive(String uid) {
    late final StreamController<Workout?> out;
    StreamSubscription<String?>? pointer;
    StreamSubscription<Workout?>? workout;
    out = StreamController(
      onListen: () {
        pointer = _pointer(uid)
            .snapshots()
            .map((snap) => snap.data()?['workoutId'] as String?)
            .distinct()
            .listen((id) {
              workout?.cancel();
              workout = null;
              if (id == null) return out.add(null);
              workout = _workouts(uid)
                  .doc(id)
                  .snapshots()
                  .map((snap) {
                    final data = snap.data();
                    if (data == null) return null;
                    final found = workoutFromMap(snap.id, data);
                    return found.isCompleted ? null : found;
                  })
                  .listen(out.add, onError: out.addError);
            }, onError: out.addError);
      },
      onCancel: () async {
        await workout?.cancel();
        await pointer?.cancel();
      },
    );
    return out.stream;
  }

  @override
  Stream<List<Workout>> watchCompleted(String uid) => _workouts(uid)
      .where('status', isEqualTo: WorkoutStatus.completed.name)
      .snapshots()
      .map(
        (snap) =>
            [for (final doc in snap.docs) workoutFromMap(doc.id, doc.data())]
              ..sort((a, b) => performedAt(b).compareTo(performedAt(a))),
      );

  @override
  Stream<List<Workout>> watchAll(String uid) => _workouts(uid).snapshots().map(
    (snap) =>
        [for (final doc in snap.docs) workoutFromMap(doc.id, doc.data())]
          ..sort((a, b) => performedAt(b).compareTo(performedAt(a))),
  );

  @override
  Future<void> start(Workout workout) => _serially(() async {
    if (workout.isCompleted) throw StateError('Workout is already completed');
    final active = await _activeId(workout.traineeId);
    if (active != null) throw ActiveWorkoutExists(active);
    final batch = _db.batch();
    final writeId = _setWorkout(batch, workout);
    _setPointer(batch, workout.traineeId, workout.id);
    await _send(batch, workout, writeId);
  });

  @override
  Future<void> save(Workout workout) => _serially(() async {
    final active = await _activeId(workout.traineeId);
    final batch = _db.batch();
    final writeId = _setWorkout(batch, workout);
    if (workout.isCompleted) {
      if (active == workout.id) _setPointer(batch, workout.traineeId, null);
    } else if (active != workout.id) {
      throw StateError('Workout ${workout.id} is not the one in progress');
    }
    await _send(batch, workout, writeId);
  });

  @override
  Future<void> cancel(Workout workout) => _serially(() async {
    if (await _activeId(workout.traineeId) != workout.id) {
      throw StateError('Workout ${workout.id} is not the one in progress');
    }
    final batch = _db.batch()
      ..delete(_workouts(workout.traineeId).doc(workout.id));
    _setPointer(batch, workout.traineeId, null);
    await _send(batch, workout, null);
  });

  @override
  Future<void> deleteCompleted(Workout workout) => _serially(() async {
    if (!workout.isCompleted) {
      throw StateError('Workout ${workout.id} is still in progress');
    }
    final batch = _db.batch()
      ..delete(_workouts(workout.traineeId).doc(workout.id));
    await _send(batch, workout, null);
  });
}
