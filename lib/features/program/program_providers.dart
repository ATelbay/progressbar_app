import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/program_repository.dart';
import '../../domain/models.dart';
import '../../domain/storage_status.dart';
import '../auth/auth_controller.dart';
import '../firestore_provider.dart';
import '../storage_status_providers.dart';

final programRepositoryProvider = Provider<ProgramRepository>(
  (ref) => FirestoreProgramRepository(
    ref.watch(firestoreProvider),
    onRejected: rejectedWriteHandler(ref, StorageArea.program),
  ),
);

/// Programs the signed-in user wrote.
final ownProgramsProvider = StreamProvider<List<Program>>((ref) {
  final uid = ref.watch(uidProvider).value;
  if (uid == null) return const Stream.empty();
  return ref.watch(programRepositoryProvider).watchOwn(uid);
});
