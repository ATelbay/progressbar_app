import 'dart:math';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:progressbar_app/data/link_repository.dart';
import 'package:progressbar_app/domain/link_logic.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/domain/workout_logic.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreLinkRepository links;
  var now = DateTime.utc(2026, 10, 6, 12);

  setUp(() {
    db = FakeFirebaseFirestore();
    now = DateTime.utc(2026, 10, 6, 12);
    links = FirestoreLinkRepository(db, random: Random(7), now: () => now);
  });

  Future<Invitation> invite(String uid, LinkRole role) =>
      links.createInvitation(inviterId: uid, inviterName: uid, role: role);

  test('an invitation is found by its code until it expires', () async {
    final invitation = await invite('coach', LinkRole.coach);
    expect(normalizeInviteCode(invitation.code), invitation.code);
    final found = await links.findInvitation(invitation.code);
    expect(found!.inviterId, 'coach');
    expect(found.inviterRole, LinkRole.coach);
    expect(found.expiresAt!.toUtc(), now.add(inviteLifetime));
    expect(await links.findInvitation('ZZZZZZ'), isNull);

    now = now.add(inviteLifetime);
    expect(await links.findInvitation(invitation.code), isNull);
  });

  test('accepting links both people and uses the code up', () async {
    final invitation = await invite('coach', LinkRole.coach);
    final link = await links.accept(
      invitation,
      acceptorId: 'me',
      acceptorName: 'Арман',
    );
    expect(link.id, 'coach_me');
    expect(await links.findInvitation(invitation.code), isNull);

    final mine = await links.watchCoaches('me').first;
    expect(mine.single.coachName, 'coach');
    expect(mine.single.status, LinkStatus.active);
    final theirs = await links.watchTrainees('coach').first;
    expect(theirs.single.traineeName, 'Арман');
    expect(await links.watchTrainees('me').first, isEmpty);
    expect(await links.watchCoaches('coach').first, isEmpty);
  });

  test(
    'a trainee invites a coach, then has two until the older is demoted',
    () async {
      await links.accept(
        await invite('first', LinkRole.coach),
        acceptorId: 'me',
        acceptorName: 'Арман',
      );
      now = now.add(const Duration(days: 1));
      await links.accept(
        await invite('me', LinkRole.trainee),
        acceptorId: 'second',
        acceptorName: 'Мадина',
      );

      var mine = await links.watchCoaches('me').first;
      expect(mine.length, 2);
      expect(activeCoachOf('me', mine), 'second');
      final older = linksToDemote('me', mine).single;
      expect(older.coachId, 'first');

      await links.setStatus(older, LinkStatus.readOnly);
      mine = await links.watchCoaches('me').first;
      expect(linksToDemote('me', mine), isEmpty);
      expect(activeCoachOf('me', mine), 'second');
      expect(visibleLinks(mine).length, 2);

      await links.setStatus(older, LinkStatus.removed);
      expect(visibleLinks(await links.watchCoaches('me').first).length, 1);
    },
  );

  test('a new invitation renews a removed link', () async {
    final first = await links.accept(
      await invite('coach', LinkRole.coach),
      acceptorId: 'me',
      acceptorName: 'Арман',
    );
    await links.setStatus(first, LinkStatus.removed);
    await links.accept(
      await invite('coach', LinkRole.coach),
      acceptorId: 'me',
      acceptorName: 'Арман',
    );
    final mine = await links.watchCoaches('me').first;
    expect(mine.single.status, LinkStatus.active);
  });
}
