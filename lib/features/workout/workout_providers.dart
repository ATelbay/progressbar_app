import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/firestore_writes.dart';
import '../../data/workout_repository.dart';
import '../../domain/models.dart';
import '../../domain/storage_status.dart';
import '../../domain/workout_logic.dart';
import '../auth/auth_controller.dart';
import '../firestore_provider.dart';
import '../storage_status_providers.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => FirestoreWorkoutRepository(
    ref.watch(firestoreProvider),
    onRejected: rejectedWriteHandler(ref, StorageArea.workout),
  ),
);

/// IDs for new programs, workouts, exercises and sets.
final newIdProvider = Provider<IdGenerator>((ref) {
  final db = ref.watch(firestoreProvider);
  return () => newFirestoreId(db);
});

/// The workout in progress, restored after a restart; null when there is none.
final activeWorkoutProvider = StreamProvider<Workout?>((ref) {
  final uid = ref.watch(uidProvider).value;
  if (uid == null) return const Stream.empty();
  return ref.watch(workoutRepositoryProvider).watchActive(uid);
});

/// Completed workouts, newest first: history, progress and pre-fill.
final completedWorkoutsProvider = StreamProvider<List<Workout>>((ref) {
  final uid = ref.watch(uidProvider).value;
  if (uid == null) return const Stream.empty();
  return ref.watch(workoutRepositoryProvider).watchCompleted(uid);
});
