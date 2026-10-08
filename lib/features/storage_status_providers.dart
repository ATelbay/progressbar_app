import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firestore_writes.dart';
import '../data/workout_sync_repository.dart';
import '../domain/storage_status.dart';
import 'auth/auth_controller.dart';
import 'firestore_provider.dart';

class StorageWriteFailures extends Notifier<StorageWriteFailure?> {
  @override
  StorageWriteFailure? build() => null;

  void report(String userId, StorageArea area) =>
      state = StorageWriteFailure(userId: userId, area: area);

  void clear() => state = null;
}

final storageWriteFailuresProvider =
    NotifierProvider<StorageWriteFailures, StorageWriteFailure?>(
      StorageWriteFailures.new,
    );

/// Bind the callback to the repository's session. Late refusals after sign-out
/// must not display an error to a different user, or touch a disposed scope.
WriteRejected rejectedWriteHandler(Ref ref, StorageArea area) {
  final failures = ref.watch(storageWriteFailuresProvider.notifier);
  final uid = ref.watch(uidProvider).value;
  return (error, stack) {
    logRejectedWrite(error, stack);
    if (ref.mounted && uid != null) failures.report(uid, area);
  };
}

final workoutSyncRepositoryProvider = Provider<WorkoutSyncRepository>(
  (ref) => FirestoreWorkoutSyncRepository(ref.watch(firestoreProvider)),
);

final workoutSyncProvider = StreamProvider.autoDispose
    .family<WorkoutSyncState, String>((ref, workoutId) {
      final uid = ref.watch(uidProvider).value;
      if (uid == null) return const Stream.empty();
      return ref.watch(workoutSyncRepositoryProvider).watch(uid, workoutId);
    });
