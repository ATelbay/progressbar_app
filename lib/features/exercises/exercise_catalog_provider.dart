import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/exercise_catalog_repository.dart';
import '../../domain/models.dart';

final exerciseCatalogRepositoryProvider = Provider<ExerciseCatalogRepository>(
  (ref) => AssetExerciseCatalogRepository(rootBundle),
);

/// Loaded on demand and shared by the program builder and workout screens.
final exerciseCatalogProvider = FutureProvider<Map<String, Exercise>>(
  (ref) => ref.watch(exerciseCatalogRepositoryProvider).load(),
);
