import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/storage_status.dart';

abstract interface class WorkoutSyncRepository {
  Stream<WorkoutSyncState> watch(String uid, String workoutId);
}

/// Metadata belongs to storage, rather than to the workout's historical data.
/// Including metadata changes also delivers the server acknowledgement when
/// no workout fields changed, and the transition to local data without a
/// connection. Firestore restores pending writes from its disk cache.
class FirestoreWorkoutSyncRepository implements WorkoutSyncRepository {
  FirestoreWorkoutSyncRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Stream<WorkoutSyncState> watch(String uid, String workoutId) => _db
      .doc('users/$uid/workouts/$workoutId')
      .snapshots(includeMetadataChanges: true)
      .map(
        (snapshot) => WorkoutSyncState(
          fromCache: snapshot.metadata.isFromCache,
          hasPendingWrites: snapshot.metadata.hasPendingWrites,
        ),
      );
}
