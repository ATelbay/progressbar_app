import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/assignment_repository.dart';
import '../../domain/assignment_logic.dart';
import '../../domain/exercise_catalog.dart';
import '../../domain/models.dart';
import '../auth/auth_controller.dart';
import '../exercises/exercise_catalog_provider.dart';
import '../exercises/personal_exercises_provider.dart';
import '../firestore_provider.dart';
import '../people/people_providers.dart';
import 'program_providers.dart';

final assignmentRepositoryProvider = Provider<AssignmentRepository>(
  (ref) => FirestoreAssignmentRepository(ref.watch(firestoreProvider)),
);

final ownAssignmentsProvider = StreamProvider<List<Assignment>>((ref) {
  final uid = ref.watch(uidProvider).value;
  if (uid == null) return Stream.value([]);
  return ref.watch(assignmentRepositoryProvider).watch(uid);
});

/// The link is watched independently: removing a coach immediately hides
/// cached programs and closes an already-open assigned program.
final availableAssignmentsProvider = Provider<AsyncValue<List<Assignment>>>((
  ref,
) {
  final links = ref.watch(myCoachesProvider);
  final assignments = ref.watch(ownAssignmentsProvider);
  return links.when(
    data: (links) => assignments.whenData(
      (items) => items
          .where((a) => links.any((link) => canReadAssignment(a, link)))
          .toList(),
    ),
    loading: () => const AsyncLoading(),
    error: (e, stack) => AsyncError(e, stack),
  );
});

typedef ProgramKey = ({String authorId, String programId});
final sharedProgramProvider = StreamProvider.autoDispose
    .family<Program?, ProgramKey>((ref, key) {
      ref.watch(uidProvider);
      return ref
          .watch(programRepositoryProvider)
          .watchProgram(key.authorId, key.programId);
    });

final authorExercisesProvider = StreamProvider.autoDispose
    .family<List<Exercise>, String>((ref, authorId) {
      ref.watch(uidProvider);
      return ref.watch(personalExerciseRepositoryProvider).watch(authorId);
    });

/// Author edits take precedence over built-ins only for that author's plan.
/// Trainee edits cannot change the meaning of the coach's planned exercise.
final authorCatalogProvider = FutureProvider.autoDispose
    .family<Map<String, Exercise>, String>(
      (ref, authorId) async => mergeCatalog(
        await ref.watch(exerciseCatalogProvider.future),
        await ref.watch(authorExercisesProvider(authorId).future),
      ),
    );

final traineeAssignmentsProvider = StreamProvider.autoDispose
    .family<List<Assignment>, String>((ref, traineeId) {
      final uid = ref.watch(uidProvider).value;
      if (uid == null) return Stream.value([]);
      return ref
          .watch(assignmentRepositoryProvider)
          .watch(traineeId, coachId: uid);
    });
