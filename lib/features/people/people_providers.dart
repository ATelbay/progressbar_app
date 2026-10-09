import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/link_repository.dart';
import '../../domain/link_logic.dart';
import '../../domain/models.dart';
import '../../domain/workout_logic.dart';
import '../auth/auth_controller.dart';
import '../firestore_provider.dart';
import '../workout/workout_providers.dart';

/// The code from an invitation link the app was opened with. It waits here
/// until the person is signed in, then the shell opens the invitation.
class PendingInviteCode extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? code) => state = code;
}

final pendingInviteCodeProvider = NotifierProvider<PendingInviteCode, String?>(
  PendingInviteCode.new,
);

/// Hands text to the system share sheet.
final shareTextProvider =
    Provider<Future<void> Function(String text, Rect? origin)>(
      (ref) =>
          (text, origin) => SharePlus.instance.share(
            ShareParams(text: text, sharePositionOrigin: origin),
          ),
    );

final linkRepositoryProvider = Provider<LinkRepository>(
  (ref) => FirestoreLinkRepository(ref.watch(firestoreProvider)),
);

/// The signed-in user's coaches, removed ones left out.
final myCoachesProvider = StreamProvider<List<CoachLink>>((ref) {
  final uid = ref.watch(uidProvider).value;
  if (uid == null) return Stream.value(const []);
  return ref.watch(linkRepositoryProvider).watchCoaches(uid).map(visibleLinks);
});

/// The signed-in user's trainees, removed ones left out.
final myTraineesProvider = StreamProvider<List<CoachLink>>((ref) {
  final uid = ref.watch(uidProvider).value;
  if (uid == null) return Stream.value(const []);
  return ref.watch(linkRepositoryProvider).watchTrainees(uid).map(visibleLinks);
});

/// The coach a workout started now is recorded under, if any.
final activeCoachProvider = Provider<CoachLink?>((ref) {
  final uid = ref.watch(uidProvider).value;
  final coaches = ref.watch(myCoachesProvider).value ?? const <CoachLink>[];
  final coachId = uid == null ? null : activeCoachOf(uid, coaches);
  return coaches.where((l) => l.coachId == coachId).firstOrNull;
});

final traineeWorkoutsProvider = StreamProvider.autoDispose
    .family<List<Workout>, String>((ref, traineeId) {
      ref.watch(uidProvider);
      return ref.watch(workoutRepositoryProvider).watchAll(traineeId);
    });
