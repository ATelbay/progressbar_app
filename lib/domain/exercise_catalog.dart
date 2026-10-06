import 'models.dart';

/// Shared catalog indexing for programs and workout snapshots.
/// Reject duplicate IDs rather than silently replacing an exercise.
Map<String, Exercise> indexExercises(Iterable<Exercise> exercises) {
  final result = <String, Exercise>{};
  for (final exercise in exercises) {
    if (exercise.id.trim().isEmpty || result.containsKey(exercise.id)) {
      throw ArgumentError('Exercise IDs must be non-empty and unique.');
    }
    result[exercise.id] = exercise;
  }
  return Map.unmodifiable(result);
}
