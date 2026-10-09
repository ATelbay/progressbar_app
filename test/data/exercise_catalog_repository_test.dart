import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:progressbar_app/data/exercise_catalog_repository.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/domain/workout_logic.dart';
import 'package:progressbar_app/features/exercises/exercise_catalog_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Map<String, Exercise>> load() =>
      AssetExerciseCatalogRepository(rootBundle).load();

  Map<String, Object?> row() => {
    'id': 'free-exercise-db/Plank',
    'names': {'en': 'Plank', 'ru': 'Планка', 'kk': 'Планка'},
    'muscleGroup': 'abdominals',
    'equipment': 'body only',
    'measure': 'time',
    'usesBodyWeight': true,
  };

  String encoded(List<Object?> rows, {int version = 1}) =>
      jsonEncode({'schemaVersion': version, 'exercises': rows});

  test(
    'the packaged asset loads offline with all three translations',
    () async {
      final catalog = await load();
      expect(catalog.length, inInclusiveRange(100, 150));
      for (final entry in catalog.entries) {
        expect(entry.key, entry.value.id);
        expect(entry.value.ownerId, isNull);
        expect(entry.value.muscleGroup, isNotEmpty);
        for (final language in ['en', 'ru', 'kk']) {
          expect(
            entry.value.names[language]?.trim(),
            isNotEmpty,
            reason: '${entry.key} / $language',
          );
        }
      }
      expect(
        catalog['free-exercise-db/Barbell_Bench_Press_-_Medium_Grip']!.nameFor(
          'ru',
        ),
        'Жим штанги лёжа',
      );
      final plank = catalog['free-exercise-db/Plank']!;
      expect(plank.nameFor('kk'), 'Планка');
      expect(plank.nameFor('unknown'), plank.names['en']);
      expect(() => plank.names['ru'] = 'Changed', throwsUnsupportedError);
      expect(() => catalog.clear(), throwsUnsupportedError);
    },
  );

  test(
    'the provider loads the asset without Firebase or a signed-in user',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final catalog = await container.read(exerciseCatalogProvider.future);
      expect(catalog, contains('free-exercise-db/Pullups'));
      expect(catalog, contains('free-exercise-db/Plank'));
    },
  );

  test(
    'catalog flags drive real workout load and progress correctly',
    () async {
      final catalog = await load();
      final now = DateTime.utc(2026, 10, 6);
      var counter = 0;
      String nextId() => '${counter++}';
      var workout = startWorkout(
        id: 'w',
        traineeId: 'athlete',
        now: now,
        newId: nextId,
        catalog: catalog,
        languageCode: 'ru',
        bodyWeightKg: 80,
      );
      final cases = {
        'Pullups': const SetValues(reps: 5, weightKg: 10),
        'Dips_-_Chest_Version': const SetValues(reps: 8),
        'Barbell_Bench_Press_-_Medium_Grip': const SetValues(
          reps: 8,
          weightKg: 60,
        ),
        'Plank': const SetValues(seconds: 45),
        'Side_Bridge': const SetValues(seconds: 30),
      };
      for (final entry in cases.entries) {
        final exercise = catalog['free-exercise-db/${entry.key}']!;
        workout = addExercise(
          workout,
          exercise,
          languageCode: 'ru',
          newId: nextId,
          now: now,
        );
        workout = recordSummary(
          workout,
          workout.exercises.last.id,
          setCount: 1,
          fact: entry.value,
          newId: nextId,
          now: now,
        );
      }
      workout = completeWorkout(workout, now: now);
      final pullup = workout.exercises[0];
      final dip = workout.exercises[1];
      final bench = workout.exercises[2];
      expect(pullup.name, 'Подтягивания прямым хватом');
      expect(totalLoadKg(workout, pullup, pullup.sets.single.fact!), 90);
      expect(totalLoadKg(workout, dip, dip.sets.single.fact!), 80);
      expect(totalLoadKg(workout, bench, bench.sets.single.fact!), 60);
      final pullupPoint = progressFor(pullup.exerciseId, [workout]).single;
      expect(pullupPoint.value, 5);
      expect(pullupPoint.extraKg, 10);
      expect(progressFor(bench.exerciseId, [workout]).single.value, 60);
      expect(progressFor('free-exercise-db/Plank', [workout]).single.value, 45);
      expect(
        progressFor('free-exercise-db/Side_Bridge', [workout]).single.value,
        30,
      );
      expect(workout.exercises[3].measure, Measure.time);
      expect(workout.exercises[4].measure, Measure.time);
    },
  );

  test('duplicate IDs and unsupported schemas fail visibly', () {
    expect(
      () => decodeExerciseCatalog(encoded([row(), row()])),
      throwsFormatException,
    );
    expect(
      () => decodeExerciseCatalog(encoded([row()], version: 2)),
      throwsFormatException,
    );
    expect(() => decodeExerciseCatalog(encoded([])), throwsFormatException);
  });

  test('incomplete translations fail instead of silently using English', () {
    for (final invalid in [null, '', '   ', 123]) {
      final item = row();
      item['names'] = {'en': 'Plank', 'ru': 'Планка', 'kk': invalid};
      expect(
        () => decodeExerciseCatalog(encoded([item])),
        throwsFormatException,
      );
    }
  });

  test(
    'invalid measure and body-weight flags cannot change workout semantics',
    () {
      for (final change in [
        {'measure': 'distance'},
        {'usesBodyWeight': 'true'},
        {'usesBodyWeight': null},
        {'id': 'free-exercise-db/'},
        {'id': 'user/plank'},
        {'ownerId': 'user'},
      ]) {
        expect(
          () => decodeExerciseCatalog(encoded([row()..addAll(change)])),
          throwsFormatException,
        );
      }
    },
  );
}
