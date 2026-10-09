import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:progressbar_app/domain/link_logic.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/domain/workout_logic.dart';

final now = DateTime.utc(2026, 10, 6, 12);

Invitation invitation(LinkRole role, {DateTime? expiresAt}) => Invitation(
  code: 'K7M42Q',
  inviterId: 'sergey',
  inviterName: 'Сергей',
  inviterRole: role,
  createdAt: now,
  expiresAt: expiresAt ?? now.add(inviteLifetime),
);

CoachLink link(String coach, LinkStatus status, int day) => CoachLink(
  id: linkId(coach, 'me'),
  coachId: coach,
  traineeId: 'me',
  status: status,
  createdAt: now.add(Duration(days: day)),
);

void main() {
  test(
    'an invitation link carries the code and nothing else is taken for one',
    () {
      expect(inviteLink('K7M42Q'), 'progressbar://app/join/K7M42Q');
      expect(inviteCodeFromLink(Uri.parse(inviteLink('K7M42Q'))), 'K7M42Q');
      expect(inviteCodeFromLink(Uri.parse('/join/k7m42q')), 'K7M42Q');
      for (final other in [
        'https://app/join/K7M42Q',
        'progressbar://app/join/K7M40Q',
        'progressbar://app/join',
        'progressbar://app/program/K7M42Q',
        '/people',
      ]) {
        expect(inviteCodeFromLink(Uri.parse(other)), isNull, reason: other);
      }
    },
  );

  test('codes are six unambiguous characters and survive sloppy typing', () {
    final code = newInviteCode(Random(1));
    expect(code.length, 6);
    expect(code.split('').every(inviteAlphabet.contains), isTrue);
    expect(normalizeInviteCode(' k7m-42q '), 'K7M42Q');
    expect(formatInviteCode('K7M42Q'), 'K7M 42Q');
    for (final bad in ['', 'K7M42', 'K7M42QX', 'K7M40Q', 'K7M4IQ']) {
      expect(normalizeInviteCode(bad), isNull, reason: bad);
    }
  });

  test('the inviter keeps the role they chose', () {
    final asCoach = acceptInvitation(
      invitation(LinkRole.coach),
      acceptorId: 'me',
      acceptorName: 'Арман',
      now: now,
    );
    expect(asCoach.id, 'sergey_me');
    expect((asCoach.coachId, asCoach.coachName), ('sergey', 'Сергей'));
    expect((asCoach.traineeId, asCoach.traineeName), ('me', 'Арман'));
    expect(asCoach.status, LinkStatus.active);

    final asTrainee = acceptInvitation(
      invitation(LinkRole.trainee),
      acceptorId: 'me',
      acceptorName: 'Арман',
      now: now,
    );
    expect(asTrainee.id, 'me_sergey');
    expect((asTrainee.coachId, asTrainee.coachName), ('me', 'Арман'));
    expect((asTrainee.traineeId, asTrainee.traineeName), ('sergey', 'Сергей'));
  });

  test('own and expired invitations cannot be accepted', () {
    expect(
      () => acceptInvitation(
        invitation(LinkRole.coach),
        acceptorId: 'sergey',
        acceptorName: 'Сергей',
        now: now,
      ),
      throwsArgumentError,
    );
    final old = invitation(LinkRole.coach, expiresAt: now);
    expect(isExpired(old, now), isTrue);
    expect(
      () => acceptInvitation(
        old,
        acceptorId: 'me',
        acceptorName: 'Арман',
        now: now,
      ),
      throwsStateError,
    );
  });

  test('only the newest active coach stays active', () {
    final links = [
      link('old', LinkStatus.active, 1),
      link('viewer', LinkStatus.readOnly, 2),
      link('new', LinkStatus.active, 3),
      link('gone', LinkStatus.removed, 4),
    ];
    expect(activeCoachOf('me', links), 'new');
    expect(linksToDemote('me', links).map((l) => l.coachId), ['old']);
    expect(linksToDemote('me', [links.last]), isEmpty);
    expect(visibleLinks(links).map((l) => l.coachId), ['new', 'viewer', 'old']);
    expect(activeCoachOf('me', [links[1], links[3]]), isNull);
  });
}
