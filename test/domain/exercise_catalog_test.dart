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

  test('every area files an exercise under a group of that same area', () {
    for (final area in MuscleArea.values) {
      expect(areaOf(muscleGroupFor(area)), area);
    }
    expect(areaOf('neck'), isNull);
  });

  test('a profile copy can set the language and clear it again', () {
    const profile = UserProfile(id: 'u', name: 'A', phone: '+7');
    final russian = profile.copyWith(languageCode: () => 'ru');
    expect(russian.languageCode, 'ru');
    expect(russian.copyWith(bodyWeightKg: 80).languageCode, 'ru');
    expect(russian.copyWith(languageCode: () => null).languageCode, isNull);
  });
}
