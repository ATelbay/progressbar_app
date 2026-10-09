import 'package:flutter_test/flutter_test.dart';

import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/domain/program_logic.dart';

const bench = Exercise(
  id: 'bench',
  names: {'en': 'Bench'},
  muscleGroup: 'chest',
);
const plan = SetValues(reps: 8, weightKg: 60);

void main() {
  var program = const Program(id: 'p', authorId: 'me', name: '', days: []);

  test('a program is built day by day and exercise by exercise', () {
    program = renameProgram(program, 'Сила');
    program = addDay(program, id: 'd1', name: 'День 1');
    program = addDay(program, id: 'd2', name: 'День 2');
    program = renameDay(program, 'd1', 'Грудь');
    program = putExercise(
      program,
      'd1',
      ProgramExercise(
        id: 'e1',
        exerciseId: 'bench',
        sets: uniformSets(3, plan),
      ),
    );
    expect(program.name, 'Сила');
    expect(program.authorId, 'me');
    expect(program.days.map((d) => d.name), ['Грудь', 'День 2']);
    expect(program.days.first.exercises.single.sets, [plan, plan, plan]);
    expect(program.days.last.exercises, isEmpty);
  });

  test('putting an exercise with a known ID replaces it in place', () {
    program = putExercise(
      program,
      'd1',
      const ProgramExercise(id: 'e2', exerciseId: 'bench', sets: [plan]),
    );
    program = putExercise(
      program,
      'd1',
      ProgramExercise(
        id: 'e1',
        exerciseId: 'bench',
        note: 'Пауза',
        sets: uniformSets(4, plan),
      ),
    );
    final exercises = program.days.first.exercises;
    expect(exercises.map((e) => e.id), ['e1', 'e2']);
    expect(exercises.first.sets.length, 4);
    expect(exercises.first.note, 'Пауза');
  });

  test('exercises and days are removed, unknown days are an error', () {
    program = removeExercise(program, 'd1', 'e2');
    expect(program.days.first.exercises.single.id, 'e1');
    program = removeDay(program, 'd2');
    expect(program.days.single.id, 'd1');
    expect(() => renameDay(program, 'gone', 'x'), throwsStateError);
    expect(() => uniformSets(0, plan), throwsArgumentError);
  });

  test('a day starts only when it has known, planned exercises', () {
    final day = program.days.single;
    expect(canStartDay(day, const {'bench': bench}), isTrue);
    expect(canStartDay(day, const {}), isFalse);
    expect(
      canStartDay(const ProgramDay(id: 'd', name: 'x', exercises: []), const {
        'bench': bench,
      }),
      isFalse,
    );
  });
}
