import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/personal_exercise_repository.dart';
import '../../domain/exercise_catalog.dart';
import '../../domain/models.dart';
import '../auth/auth_controller.dart';
import 'exercise_catalog_provider.dart';

final personalExerciseRepositoryProvider = Provider<PersonalExerciseRepository>(
  (ref) => FirestorePersonalExerciseRepository(FirebaseFirestore.instance),
);

/// The signed-in user's own exercises and edits of built-in ones.
final personalExercisesProvider = StreamProvider<List<Exercise>>((ref) {
  final uid = ref.watch(uidProvider).value;
  if (uid == null) return Stream.value(const []);
  return ref.watch(personalExerciseRepositoryProvider).watch(uid);
});

/// The built-in catalog with the user's exercises and edits applied — what
/// the exercise picker, program builder and workout start should use.
final userCatalogProvider = FutureProvider<Map<String, Exercise>>(
  (ref) async => mergeCatalog(
    await ref.watch(exerciseCatalogProvider.future),
    await ref.watch(personalExercisesProvider.future),
  ),
);
