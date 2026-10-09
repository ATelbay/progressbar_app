import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../../data/profile_repository.dart';
import '../../domain/models.dart';
import '../firestore_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(FirebaseAuth.instance),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => FirestoreProfileRepository(ref.watch(firestoreProvider)),
);

final uidProvider = StreamProvider<String?>(
  (ref) => ref.watch(authRepositoryProvider).uid,
);

final profileProvider = StreamProvider<UserProfile?>((ref) {
  final uid = ref.watch(uidProvider).value;
  if (uid == null) return const Stream.empty();
  return ref.watch(profileRepositoryProvider).watch(uid);
});

enum Session {
  loading,
  signedOut,

  /// Signed in, but name and body weight are not filled in yet.
  needsProfile,
  ready,
}

final sessionProvider = Provider<Session>((ref) {
  final uid = ref.watch(uidProvider);
  if (!uid.hasValue) return Session.loading;
  if (uid.value == null) return Session.signedOut;
  final profile = ref.watch(profileProvider);
  if (!profile.hasValue) return Session.loading;
  return profile.value == null ? Session.needsProfile : Session.ready;
});

/// The phone number the code was sent to, kept between the two sign-in steps.
class PendingPhone extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String phone) => state = phone;
}

final pendingPhoneProvider = NotifierProvider<PendingPhone, String?>(
  PendingPhone.new,
);

/// «+7 701 234 56 78» → «+77012345678»; null when it is not a phone number.
String? normalizePhone(String input) {
  final digits = input.replaceAll(RegExp(r'[\s\-()]'), '');
  return RegExp(r'^\+\d{10,15}$').hasMatch(digits) ? digits : null;
}
