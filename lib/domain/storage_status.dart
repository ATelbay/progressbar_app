import 'models.dart';

/// A local snapshot does not confirm a connection to the server. Pending
/// writes are safely queued on the device, but have not been acknowledged.
class WorkoutSyncState {
  const WorkoutSyncState({
    required this.fromCache,
    required this.hasPendingWrites,
  });

  final bool fromCache;
  final bool hasPendingWrites;

  /// A workout is sent as one document: until that version is acknowledged,
  /// its recorded results carry the same pending status, including after a
  /// restart. A skipped exercise has no result to send.
  Set<String> pendingExercises(Workout workout) => {
    if (hasPendingWrites)
      for (final exercise in workout.exercises)
        if (exercise.hasFact) exercise.id,
  };
}

enum StorageArea { workout, program, exercise }

class StorageWriteFailure {
  const StorageWriteFailure({required this.userId, required this.area});

  final String userId;
  final StorageArea area;
}
