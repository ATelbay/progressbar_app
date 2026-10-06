import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models.dart';

abstract interface class AssignmentRepository {
  Stream<List<Assignment>> watch(String traineeId, {String? coachId});
  Future<void> assign(Assignment assignment);
}

/// References only: the program and its exercises stay under the author.
/// Assignment needs the server to confirm active-coach access.
class FirestoreAssignmentRepository implements AssignmentRepository {
  FirestoreAssignmentRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _assignments(String uid) =>
      _db.collection('users').doc(uid).collection('assignments');

  @override
  Stream<List<Assignment>> watch(String traineeId, {String? coachId}) {
    Query<Map<String, dynamic>> query = _assignments(traineeId);
    if (coachId != null) query = query.where('coachId', isEqualTo: coachId);
    return query.snapshots().map(
      (snap) => [
        for (final doc in snap.docs)
          Assignment(
            id: doc.id,
            traineeId: traineeId,
            programId: doc.data()['programId'] as String,
            coachId: doc.data()['coachId'] as String,
            assignedAt:
                (doc.data()['assignedAt'] as Timestamp?)?.toDate() ??
                DateTime.fromMillisecondsSinceEpoch(0),
          ),
      ]..sort((a, b) => b.assignedAt.compareTo(a.assignedAt)),
    );
  }

  @override
  Future<void> assign(Assignment assignment) =>
      _assignments(assignment.traineeId)
          .doc(assignment.id)
          .set({
            'programId': assignment.programId,
            'coachId': assignment.coachId,
            'traineeId': assignment.traineeId,
            'assignedAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 15));
}
