import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models.dart';

/// Shape of the documents under `users/{uid}`. Bump when a stored field
/// changes meaning, so older documents can be told apart.
const schemaVersion = 1;

Map<String, dynamic> _map(Object? value) =>
    Map<String, dynamic>.from(value! as Map);

Iterable<Map<String, dynamic>> _maps(Object? value) =>
    (value as List? ?? const []).map(_map);

Map<String, Object?> _setValuesToMap(SetValues v) => {
  'reps': v.reps,
  'seconds': v.seconds,
  'weightKg': v.weightKg,
};

SetValues _setValuesFromMap(Map<String, dynamic> m) => SetValues(
  reps: (m['reps'] as num?)?.toInt(),
  seconds: (m['seconds'] as num?)?.toInt(),
  weightKg: (m['weightKg'] as num).toDouble(),
);

SetValues? _optionalSetValues(Object? value) =>
    value == null ? null : _setValuesFromMap(_map(value));

DateTime? _date(Object? value) => (value as Timestamp?)?.toDate();

Timestamp? _timestamp(DateTime? value) =>
    value == null ? null : Timestamp.fromDate(value);

Map<String, Object?> programToMap(Program program) => {
  'schemaVersion': schemaVersion,
  'authorId': program.authorId,
  'name': program.name,
  'days': [
    for (final day in program.days)
      {
        'id': day.id,
        'name': day.name,
        'exercises': [
          for (final exercise in day.exercises)
            {
              'id': exercise.id,
              'exerciseId': exercise.exerciseId,
              'note': exercise.note,
              'sets': exercise.sets.map(_setValuesToMap).toList(),
            },
        ],
      },
  ],
};

Program programFromMap(String id, Map<String, dynamic> data) => Program(
  id: id,
  authorId: data['authorId'] as String,
  name: data['name'] as String,
  days: [
    for (final day in _maps(data['days']))
      ProgramDay(
        id: day['id'] as String,
        name: day['name'] as String,
        exercises: [
          for (final exercise in _maps(day['exercises']))
            ProgramExercise(
              id: exercise['id'] as String,
              exerciseId: exercise['exerciseId'] as String,
              note: exercise['note'] as String?,
              sets: _maps(exercise['sets']).map(_setValuesFromMap).toList(),
            ),
        ],
      ),
  ],
);

/// Plan and fact are stored side by side per set and never merged.
Map<String, Object?> workoutToMap(Workout workout) => {
  'schemaVersion': schemaVersion,
  'traineeId': workout.traineeId,
  'supervisorCoachId': workout.supervisorCoachId,
  'supervisorCoachName': workout.supervisorCoachName,
  'programId': workout.programId,
  'programName': workout.programName,
  'dayName': workout.dayName,
  'status': workout.status.name,
  'startedAt': _timestamp(workout.startedAt),
  'completedAt': _timestamp(workout.completedAt),
  'editedAt': _timestamp(workout.editedAt),
  'comment': workout.comment,
  'bodyWeightKg': workout.bodyWeightKg,
  'exercises': [
    for (final exercise in workout.exercises)
      {
        'id': exercise.id,
        'exerciseId': exercise.exerciseId,
        'name': exercise.name,
        'measure': exercise.measure.name,
        'usesBodyWeight': exercise.usesBodyWeight,
        'note': exercise.note,
        'sets': [
          for (final set in exercise.sets)
            {
              'id': set.id,
              'plan': set.plan == null ? null : _setValuesToMap(set.plan!),
              'fact': set.fact == null ? null : _setValuesToMap(set.fact!),
              'rpe': set.rpe,
            },
        ],
      },
  ],
};

Workout workoutFromMap(String id, Map<String, dynamic> data) => Workout(
  id: id,
  traineeId: data['traineeId'] as String,
  supervisorCoachId: data['supervisorCoachId'] as String?,
  supervisorCoachName: data['supervisorCoachName'] as String?,
  programId: data['programId'] as String?,
  programName: data['programName'] as String?,
  dayName: data['dayName'] as String?,
  status: WorkoutStatus.values.byName(data['status'] as String),
  startedAt: _date(data['startedAt'])!,
  completedAt: _date(data['completedAt']),
  editedAt: _date(data['editedAt']),
  comment: data['comment'] as String?,
  bodyWeightKg: (data['bodyWeightKg'] as num?)?.toDouble(),
  exercises: [
    for (final exercise in _maps(data['exercises']))
      WorkoutExercise(
        id: exercise['id'] as String,
        exerciseId: exercise['exerciseId'] as String,
        name: exercise['name'] as String,
        measure: Measure.values.byName(exercise['measure'] as String),
        usesBodyWeight: exercise['usesBodyWeight'] as bool,
        note: exercise['note'] as String?,
        sets: [
          for (final set in _maps(exercise['sets']))
            WorkoutSet(
              id: set['id'] as String,
              plan: _optionalSetValues(set['plan']),
              fact: _optionalSetValues(set['fact']),
              rpe: (set['rpe'] as num?)?.toDouble(),
            ),
        ],
      ),
  ],
);

/// A user's own exercise or their edit of a built-in one. The owner is the
/// `users/{uid}` the document sits under.
Map<String, Object?> exerciseToMap(Exercise exercise) => {
  'schemaVersion': schemaVersion,
  'id': exercise.id,
  'names': exercise.names,
  'muscleGroup': exercise.muscleGroup,
  'equipment': exercise.equipment,
  'measure': exercise.measure.name,
  'usesBodyWeight': exercise.usesBodyWeight,
};

Exercise exerciseFromMap(String ownerId, Map<String, dynamic> data) => Exercise(
  id: data['id'] as String,
  names: Map.unmodifiable(Map<String, String>.from(data['names'] as Map)),
  muscleGroup: data['muscleGroup'] as String,
  equipment: data['equipment'] as String?,
  measure: Measure.values.byName(data['measure'] as String),
  usesBodyWeight: data['usesBodyWeight'] as bool,
  ownerId: ownerId,
);
