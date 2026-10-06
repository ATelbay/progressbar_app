import 'dart:math';

import 'models.dart';

/// Letters and digits that are hard to confuse when read aloud: no 0, 1, I,
/// L or O.
const inviteAlphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
const inviteCodeLength = 6;
const inviteLifetime = Duration(days: 7);

String newInviteCode(Random random) => [
  for (var i = 0; i < inviteCodeLength; i++)
    inviteAlphabet[random.nextInt(inviteAlphabet.length)],
].join();

/// «k7m 42q» → «K7M42Q»; null when it cannot be an invitation code.
String? normalizeInviteCode(String input) {
  final code = input.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();
  return code.length == inviteCodeLength &&
          code.split('').every(inviteAlphabet.contains)
      ? code
      : null;
}

/// «K7M42Q» → «K7M 42Q», easier to read and dictate.
String formatInviteCode(String code) => code.length == inviteCodeLength
    ? '${code.substring(0, 3)} ${code.substring(3)}'
    : code;

/// The app's own link scheme: the system camera reads it from a QR code and
/// opens the app, so no scanner is needed inside.
const inviteLinkScheme = 'progressbar';

/// «K7M42Q» → «progressbar://app/join/K7M42Q».
String inviteLink(String code) => '$inviteLinkScheme://app/join/$code';

/// The code inside an invitation link or its path («/join/K7M42Q»); null for
/// anything else.
String? inviteCodeFromLink(Uri uri) {
  if (uri.hasScheme && uri.scheme != inviteLinkScheme) return null;
  final parts = uri.pathSegments;
  return parts.length == 2 && parts.first == 'join'
      ? normalizeInviteCode(parts.last)
      : null;
}

/// One link per pair of people, so the ID is made of both.
String linkId(String coachId, String traineeId) => '${coachId}_$traineeId';

bool isExpired(Invitation invitation, DateTime now) =>
    invitation.expiresAt != null && !now.isBefore(invitation.expiresAt!);

/// The link that accepting [invitation] creates: the inviter takes the role
/// they chose, the one who accepts takes the other. It starts active.
CoachLink acceptInvitation(
  Invitation invitation, {
  required String acceptorId,
  required String acceptorName,
  required DateTime now,
}) {
  if (invitation.inviterId == acceptorId) {
    throw ArgumentError('An invitation cannot be accepted by its author');
  }
  if (isExpired(invitation, now)) throw StateError('Invitation has expired');
  final inviterIsCoach = invitation.inviterRole == LinkRole.coach;
  final coachId = inviterIsCoach ? invitation.inviterId : acceptorId;
  final traineeId = inviterIsCoach ? acceptorId : invitation.inviterId;
  return CoachLink(
    id: linkId(coachId, traineeId),
    coachId: coachId,
    traineeId: traineeId,
    status: LinkStatus.active,
    createdAt: now,
    coachName: inviterIsCoach ? invitation.inviterName : acceptorName,
    traineeName: inviterIsCoach ? acceptorName : invitation.inviterName,
  );
}

/// A trainee has one active coach. When a newer link is active, the older
/// active ones are to be turned read-only; this lists them.
List<CoachLink> linksToDemote(String traineeId, Iterable<CoachLink> links) {
  final active =
      links
          .where(
            (l) => l.traineeId == traineeId && l.status == LinkStatus.active,
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return active.skip(1).toList();
}

/// Links worth showing: a removed one is gone for both sides.
List<CoachLink> visibleLinks(Iterable<CoachLink> links) =>
    links.where((l) => l.status != LinkStatus.removed).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
