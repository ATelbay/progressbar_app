import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/link_logic.dart';
import '../domain/models.dart';

/// Coach–trainee links (`links/{coachId}_{traineeId}`) and the one-time
/// invitations that create them (`invitations/{code}`). Unlike workouts, all
/// of this needs a network, so every write waits for the server and may fail.
abstract interface class LinkRepository {
  /// Links in which [uid] is the trainee: their coaches.
  Stream<List<CoachLink>> watchCoaches(String uid);

  /// Links in which [uid] is the coach: their trainees.
  Stream<List<CoachLink>> watchTrainees(String uid);

  Future<Invitation> createInvitation({
    required String inviterId,
    required String inviterName,
    required LinkRole role,
  });

  /// The invitation behind [code]; null when there is none or it has expired.
  Future<Invitation?> findInvitation(String code);

  /// Makes the link and uses the invitation up.
  Future<CoachLink> accept(
    Invitation invitation, {
    required String acceptorId,
    required String acceptorName,
  });

  /// The trainee turns a coach read-only or removes them.
  Future<void> setStatus(CoachLink link, LinkStatus status);
}

class FirestoreLinkRepository implements LinkRepository {
  FirestoreLinkRepository(this._db, {Random? random, DateTime Function()? now})
    : _random = random ?? Random.secure(),
      _now = now ?? DateTime.now;

  final FirebaseFirestore _db;
  final Random _random;
  final DateTime Function() _now;

  CollectionReference<Map<String, dynamic>> get _links =>
      _db.collection('links');
  CollectionReference<Map<String, dynamic>> get _invitations =>
      _db.collection('invitations');

  CoachLink _link(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return CoachLink(
      id: doc.id,
      coachId: data['coachId'] as String,
      traineeId: data['traineeId'] as String,
      status: LinkStatus.values.byName(data['status'] as String),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      coachName: data['coachName'] as String? ?? '',
      traineeName: data['traineeName'] as String? ?? '',
    );
  }

  Stream<List<CoachLink>> _watch(String field, String uid) => _links
      .where(field, isEqualTo: uid)
      .snapshots()
      .map((snap) => snap.docs.map(_link).toList());

  @override
  Stream<List<CoachLink>> watchCoaches(String uid) => _watch('traineeId', uid);

  @override
  Stream<List<CoachLink>> watchTrainees(String uid) => _watch('coachId', uid);

  @override
  Future<Invitation> createInvitation({
    required String inviterId,
    required String inviterName,
    required LinkRole role,
  }) async {
    // A code that is already taken is refused by the server: try another.
    for (var attempt = 0; ; attempt++) {
      final now = _now();
      final invitation = Invitation(
        code: newInviteCode(_random),
        inviterId: inviterId,
        inviterName: inviterName,
        inviterRole: role,
        createdAt: now,
        expiresAt: now.add(inviteLifetime),
      );
      try {
        await _invitations.doc(invitation.code).set({
          'inviterId': inviterId,
          'inviterName': inviterName,
          'inviterRole': role.name,
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(invitation.expiresAt!),
        });
        return invitation;
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied' || attempt == 3) rethrow;
      }
    }
  }

  @override
  Future<Invitation?> findInvitation(String code) async {
    final snap = await _invitations.doc(code).get();
    final data = snap.data();
    if (data == null) return null;
    final invitation = Invitation(
      code: code,
      inviterId: data['inviterId'] as String,
      inviterName: data['inviterName'] as String? ?? '',
      inviterRole: LinkRole.values.byName(data['inviterRole'] as String),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? _now(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
    );
    return isExpired(invitation, _now()) ? null : invitation;
  }

  @override
  Future<CoachLink> accept(
    Invitation invitation, {
    required String acceptorId,
    required String acceptorName,
  }) async {
    final link = acceptInvitation(
      invitation,
      acceptorId: acceptorId,
      acceptorName: acceptorName,
      now: _now(),
    );
    final batch = _db.batch()
      ..set(_links.doc(link.id), {
        'coachId': link.coachId,
        'traineeId': link.traineeId,
        'status': link.status.name,
        'coachName': link.coachName,
        'traineeName': link.traineeName,
        'inviteCode': invitation.code,
        'createdAt': Timestamp.fromDate(link.createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..delete(_invitations.doc(invitation.code));
    await batch.commit();
    return link;
  }

  @override
  Future<void> setStatus(CoachLink link, LinkStatus status) =>
      _links.doc(link.id).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
