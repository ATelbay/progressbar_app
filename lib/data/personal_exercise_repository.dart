import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/exercise_catalog.dart';
import '../domain/models.dart';
import 'firestore_codec.dart';
import 'firestore_writes.dart';

/// A user's own exercises and their edits of built-in ones, under
/// `users/{uid}/exercises`. The bundled catalog itself is never written.
abstract interface class PersonalExerciseRepository {
  Stream<List<Exercise>> watch(String uid);

  /// Adds or changes an exercise of its [Exercise.ownerId]. With a built-in ID
  /// it replaces that exercise for this user only.
  Future<void> save(Exercise exercise);

  /// Drops the user's edit of a built-in exercise. Own exercises are not
  /// deleted: programs refer to them by ID.
  Future<void> restoreBuiltIn(String uid, String exerciseId);
}

class FirestorePersonalExerciseRepository
    implements PersonalExerciseRepository {
  FirestorePersonalExerciseRepository(
    this._db, {
    this.onRejected = logRejectedWrite,
  });

  final FirebaseFirestore _db;
  final WriteRejected onRejected;

  CollectionReference<Map<String, dynamic>> _exercises(String uid) =>
      _db.collection('users').doc(uid).collection('exercises');

  /// Exercise IDs contain a slash, which a document ID cannot.
  DocumentReference<Map<String, dynamic>> _doc(String uid, String id) =>
      _exercises(uid).doc(id.replaceAll('/', '~'));

  @override
  Stream<List<Exercise>> watch(String uid) => _exercises(uid).snapshots().map(
    (snap) => [for (final doc in snap.docs) exerciseFromMap(uid, doc.data())],
  );

  @override
  Future<void> save(Exercise exercise) async {
    final uid = exercise.ownerId;
    if (uid == null) throw ArgumentError('A personal exercise needs an owner');
    if (!isBuiltInExercise(exercise.id) &&
        !exercise.id.startsWith(customExercisePrefix)) {
      throw ArgumentError.value(exercise.id, 'id');
    }
    final doc = _doc(uid, exercise.id);
    final writeId = newFirestoreId(_db);
    await sendWrite(
      landsIn: doc,
      writeId: writeId,
      write: () => doc.set({
        ...exerciseToMap(exercise),
        'updatedAt': FieldValue.serverTimestamp(),
        writeIdField: writeId,
      }),
      onRejected: onRejected,
    );
  }

  @override
  Future<void> restoreBuiltIn(String uid, String exerciseId) async {
    if (!isBuiltInExercise(exerciseId)) {
      throw ArgumentError.value(exerciseId, 'exerciseId');
    }
    final doc = _doc(uid, exerciseId);
    await sendWrite(
      landsIn: doc,
      writeId: null,
      write: doc.delete,
      onRejected: onRejected,
    );
  }
}
