import 'package:flutter_test/flutter_test.dart';

import 'package:progressbar_app/domain/exercise_catalog.dart';
import 'package:progressbar_app/domain/models.dart';

void main() {
  const exercise = Exercise(
    id: 'pullup',
    names: {'ru': 'Подтягивания'},
    muscleGroup: 'lats',
    usesBodyWeight: true,
  );

  test('index rejects duplicate IDs instead of overwriting a movement', () {
    expect(() => indexExercises([exercise, exercise]), throwsArgumentError);
  });

  test('index rejects an empty ID', () {
    expect(
      () => indexExercises([
        const Exercise(
          id: ' ',
          names: {'en': 'Squat'},
          muscleGroup: 'quadriceps',
        ),
      ]),
      throwsArgumentError,
    );
  });

  test('index looks up exercises and cannot be changed by callers', () {
    final catalog = indexExercises([exercise]);
    expect(catalog['pullup'], same(exercise));
    expect(catalog['unknown'], isNull);
    expect(() => catalog.clear(), throwsUnsupportedError);
  });
}
