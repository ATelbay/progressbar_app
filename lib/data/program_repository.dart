import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models.dart';
import 'firestore_codec.dart';
import 'firestore_writes.dart';

/// Programs live under their author: `users/{authorId}/programs/{id}`.
abstract interface class ProgramRepository {
  /// Programs written by [uid], by name.
  Stream<List<Program>> watchOwn(String uid);

  /// Creates or replaces the program. Workouts already started from it keep
  /// their own copy of the plan.
  Future<void> save(Program program);

  Future<void> delete(Program program);
}

class FirestoreProgramRepository implements ProgramRepository {
  FirestoreProgramRepository(this._db, {this.onRejected = logRejectedWrite});

  final FirebaseFirestore _db;
  final WriteRejected onRejected;

  CollectionReference<Map<String, dynamic>> _programs(String uid) =>
      _db.collection('users').doc(uid).collection('programs');

  @override
  Stream<List<Program>> watchOwn(String uid) => _programs(uid).snapshots().map(
    (snap) =>
        [for (final doc in snap.docs) programFromMap(doc.id, doc.data())]
          ..sort((a, b) => a.name.compareTo(b.name)),
  );

  @override
  Future<void> save(Program program) async => sendWrite(
    _programs(program.authorId).doc(program.id).set({
      ...programToMap(program),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
    onRejected,
  );

  @override
  Future<void> delete(Program program) async => sendWrite(
    _programs(program.authorId).doc(program.id).delete(),
    onRejected,
  );
}
