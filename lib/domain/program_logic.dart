import 'models.dart';

/// Editing a program in the builder. Every function returns a new program;
/// workouts already started keep their own copy of the plan.

Program renameProgram(Program program, String name) => Program(
  id: program.id,
  authorId: program.authorId,
  name: name,
  days: program.days,
);

Program _withDays(Program program, List<ProgramDay> days) => Program(
  id: program.id,
  authorId: program.authorId,
  name: program.name,
  days: days,
);

Program _updateDay(
  Program program,
  String dayId,
  ProgramDay Function(ProgramDay) update,
) {
  if (!program.days.any((d) => d.id == dayId)) {
    throw StateError('No day $dayId in program ${program.id}');
  }
  return _withDays(program, [
    for (final day in program.days) day.id == dayId ? update(day) : day,
  ]);
}

Program addDay(Program program, {required String id, required String name}) =>
    _withDays(program, [
      ...program.days,
      ProgramDay(id: id, name: name, exercises: const []),
    ]);

Program renameDay(Program program, String dayId, String name) => _updateDay(
  program,
  dayId,
  (day) => ProgramDay(id: day.id, name: name, exercises: day.exercises),
);

Program removeDay(Program program, String dayId) =>
    _withDays(program, program.days.where((d) => d.id != dayId).toList());

/// [setCount] equal planned sets: the builder plans an exercise in one line.
List<SetValues> uniformSets(int setCount, SetValues values) {
  if (setCount < 1) throw ArgumentError.value(setCount, 'setCount');
  return List.filled(setCount, values);
}

/// Adds the exercise to the day, or replaces the one with the same ID.
Program putExercise(
  Program program,
  String dayId,
  ProgramExercise exercise,
) => _updateDay(
  program,
  dayId,
  (day) => ProgramDay(
    id: day.id,
    name: day.name,
    exercises: day.exercises.any((e) => e.id == exercise.id)
        ? [for (final e in day.exercises) e.id == exercise.id ? exercise : e]
        : [...day.exercises, exercise],
  ),
);

Program removeExercise(Program program, String dayId, String exerciseId) =>
    _updateDay(
      program,
      dayId,
      (day) => ProgramDay(
        id: day.id,
        name: day.name,
        exercises: day.exercises.where((e) => e.id != exerciseId).toList(),
      ),
    );

/// A day can be started when every exercise in it is known and planned.
bool canStartDay(ProgramDay day, Map<String, Exercise> catalog) =>
    day.exercises.isNotEmpty &&
    day.exercises.every(
      (e) => catalog.containsKey(e.exerciseId) && e.sets.isNotEmpty,
    );

/// Replaces an entire group at its original position, preserving unrelated
/// exercises and stable member IDs, including repeated catalog exercises.
Program putExecutionPlan(
  Program program,
  String dayId, {
  required List<String> replacedIds,
  required List<ProgramExercise> members,
}) {
  if (members.map((e) => e.id).toSet().length != members.length) {
    throw ArgumentError('Duplicate member ID');
  }
  final supersets = <String, int>{};
  for (final e in members) {
    if (e.sets.isEmpty) throw ArgumentError('An exercise needs a set');
    if (e.executionMode == ExecutionMode.superset) {
      if (e.groupId == null) throw ArgumentError('A superset needs a group ID');
      supersets.update(e.groupId!, (n) => n + 1, ifAbsent: () => 1);
    }
  }
  if (supersets.values.any((n) => n < 2)) {
    throw ArgumentError('A superset needs two exercises');
  }
  return _updateDay(program, dayId, (day) {
    final position = day.exercises.indexWhere(
      (e) => replacedIds.contains(e.id),
    );
    final result = <ProgramExercise>[];
    for (var i = 0; i < day.exercises.length; i++) {
      if (i == position) result.addAll(members);
      if (!replacedIds.contains(day.exercises[i].id)) {
        result.add(day.exercises[i]);
      }
    }
    if (position < 0) result.addAll(members);
    return ProgramDay(id: day.id, name: day.name, exercises: result);
  });
}
