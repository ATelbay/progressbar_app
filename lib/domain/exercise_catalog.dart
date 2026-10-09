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

/// Broad body areas the exercise picker filters by.
enum MuscleArea { chest, back, legs, shoulders, arms, core }

/// The catalog muscle group stored for an exercise the user files under
/// [area].
String muscleGroupFor(MuscleArea area) => switch (area) {
  MuscleArea.chest => 'chest',
  MuscleArea.back => 'lats',
  MuscleArea.legs => 'quadriceps',
  MuscleArea.shoulders => 'shoulders',
  MuscleArea.arms => 'biceps',
  MuscleArea.core => 'abdominals',
};

/// The area of a catalog muscle group; null for a group the app does not know.
MuscleArea? areaOf(String muscleGroup) => switch (muscleGroup) {
  'chest' => MuscleArea.chest,
  'middle back' || 'lats' || 'lower back' || 'traps' => MuscleArea.back,
  'quadriceps' ||
  'hamstrings' ||
  'glutes' ||
  'calves' ||
  'abductors' ||
  'adductors' => MuscleArea.legs,
  'shoulders' => MuscleArea.shoulders,
  'biceps' || 'triceps' || 'forearms' => MuscleArea.arms,
  'abdominals' => MuscleArea.core,
  _ => null,
};
