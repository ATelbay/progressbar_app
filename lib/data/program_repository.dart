import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models.dart';
import 'firestore_codec.dart';
import 'firestore_writes.dart';

/// Programs live under their author: `users/{authorId}/programs/{id}`.
abstract interface class ProgramRepository {
  /// Programs written by [uid], by name.
  Stream<List<Program>> watchOwn(String uid);

  Stream<Program?> watchProgram(String authorId, String programId);

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
  Stream<Program?> watchProgram(String authorId, String programId) =>
      _programs(authorId)
          .doc(programId)
          .snapshots()
          .map(
            (snap) =>
                snap.exists ? programFromMap(snap.id, snap.data()!) : null,
          );

  @override
  Future<void> save(Program program) {
    final doc = _programs(program.authorId).doc(program.id);
    final writeId = newFirestoreId(_db);
    return sendWrite(
      landsIn: doc,
      writeId: writeId,
      write: () => doc.set({
        ...programToMap(program),
        'updatedAt': FieldValue.serverTimestamp(),
        writeIdField: writeId,
      }),
      onRejected: onRejected,
    );
  }

  @override
  Future<void> delete(Program program) {
    final doc = _programs(program.authorId).doc(program.id);
    return sendWrite(
      landsIn: doc,
      writeId: null,
      write: doc.delete,
      onRejected: onRejected,
    );
  }
}
