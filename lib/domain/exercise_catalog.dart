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

const builtInExercisePrefix = 'free-exercise-db/';

/// IDs of exercises a user adds themselves; never collides with a built-in one.
const customExercisePrefix = 'custom/';

bool isBuiltInExercise(String id) => id.startsWith(builtInExercisePrefix);

/// The catalog a user actually sees: a personal entry with a built-in ID
/// replaces that exercise, any other personal entry is added.
Map<String, Exercise> mergeCatalog(
  Map<String, Exercise> builtIn,
  Iterable<Exercise> personal,
) => Map.unmodifiable({...builtIn, ...indexExercises(personal)});
