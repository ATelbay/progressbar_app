import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/firestore_writes.dart';
import '../../data/workout_repository.dart';
import '../../domain/models.dart';
import '../../domain/workout_logic.dart';
import '../auth/auth_controller.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => FirestoreWorkoutRepository(FirebaseFirestore.instance),
);

/// IDs for new programs, workouts, exercises and sets.
final newIdProvider = Provider<IdGenerator>(
  (ref) =>
      () => newFirestoreId(FirebaseFirestore.instance),
);

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
