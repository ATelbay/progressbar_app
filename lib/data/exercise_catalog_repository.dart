import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/exercise_catalog.dart';
import '../domain/models.dart';

/// The bundled catalog is available before sign-in and without a network.
/// User-created exercises and overrides belong to a separate storage layer.
abstract interface class ExerciseCatalogRepository {
  Future<Map<String, Exercise>> load();
}

class AssetExerciseCatalogRepository implements ExerciseCatalogRepository {
  const AssetExerciseCatalogRepository(this._bundle);

  static const assetPath = 'assets/exercises/catalog.json';
  final AssetBundle _bundle;

  @override
  Future<Map<String, Exercise>> load() async =>
      decodeExerciseCatalog(await _bundle.loadString(assetPath));
}

/// Validate the complete bundle before making any entries available.
Map<String, Exercise> decodeExerciseCatalog(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic> || decoded['schemaVersion'] != 1) {
    throw const FormatException('Unsupported exercise catalog schema.');
  }
  final rows = decoded['exercises'];
  if (rows is! List || rows.isEmpty) {
    throw const FormatException('The exercise catalog must not be empty.');
  }
  final exercises = <Exercise>[];
  for (final row in rows) {
    if (row is! Map<String, dynamic>) {
      throw const FormatException('Expected an exercise object.');
    }
    final id = _text(row['id'], 'id');
    if (!id.startsWith('free-exercise-db/') ||
        id == 'free-exercise-db/' ||
        row['ownerId'] != null) {
      throw FormatException('Invalid built-in exercise ID or owner: $id');
    }
    final names = row['names'];
    if (names is! Map<String, dynamic>) {
      throw FormatException('Missing exercise names: $id');
    }
    final translated = {
      for (final language in ['en', 'ru', 'kk'])
        language: _text(names[language], '$id.names.$language'),
    };
    final measure = switch (row['measure']) {
      'reps' => Measure.reps,
      'time' => Measure.time,
      _ => throw FormatException('Invalid exercise measure: $id'),
    };
    final bodyWeight = row['usesBodyWeight'];
    if (bodyWeight is! bool) {
      throw FormatException('Missing body-weight flag: $id');
    }
    exercises.add(
      Exercise(
        id: id,
        names: Map.unmodifiable(translated),
        muscleGroup: _text(row['muscleGroup'], '$id.muscleGroup'),
        equipment: row['equipment'] == null
            ? null
            : _text(row['equipment'], '$id.equipment'),
        measure: measure,
        usesBodyWeight: bodyWeight,
      ),
    );
  }
  try {
    return indexExercises(exercises);
  } on ArgumentError catch (error) {
    throw FormatException(error.message.toString());
  }
}

String _text(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Expected non-empty text: $field');
  }
  return value.trim();
}
