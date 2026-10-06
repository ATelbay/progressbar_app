import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/program_repository.dart';
import '../../domain/models.dart';
import '../auth/auth_controller.dart';

final programRepositoryProvider = Provider<ProgramRepository>(
  (ref) => FirestoreProgramRepository(FirebaseFirestore.instance),
);

/// Programs the signed-in user wrote.
final ownProgramsProvider = StreamProvider<List<Program>>((ref) {
  final uid = ref.watch(uidProvider).value;
  if (uid == null) return const Stream.empty();
  return ref.watch(programRepositoryProvider).watchOwn(uid);
});
