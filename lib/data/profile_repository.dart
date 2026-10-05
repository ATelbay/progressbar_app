import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models.dart';

abstract interface class ProfileRepository {
  /// The profile of [uid]; null until the user fills it in on first sign-in.
  Stream<UserProfile?> watch(String uid);

  Future<void> save(UserProfile profile);
}

class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  @override
  Stream<UserProfile?> watch(String uid) => _doc(uid).snapshots().map((snap) {
    final data = snap.data();
    if (data == null) return null;
    return UserProfile(
      id: uid,
      name: data['name'] as String,
      phone: data['phone'] as String,
      bodyWeightKg: (data['bodyWeightKg'] as num?)?.toDouble(),
      entryMode:
          EntryMode.values.asNameMap()[data['entryMode']] ?? EntryMode.summary,
      lastSetCount: data['lastSetCount'] as int?,
    );
  });

  @override
  Future<void> save(UserProfile profile) => _doc(profile.id).set({
    'name': profile.name,
    'phone': profile.phone,
    'bodyWeightKg': profile.bodyWeightKg,
    'entryMode': profile.entryMode.name,
    'lastSetCount': profile.lastSetCount,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
