import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../router.dart';
import '../../theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/sheet.dart';
import '../format.dart';
import 'people_providers.dart';

/// A round badge with the first letter of a name.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar(this.name, {super.key, this.large = false});

  final String name;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.pb;
    return CircleAvatar(
      radius: (large ? PbSize.actionHeight : PbSize.touchMin) / 2,
      backgroundColor: c.sunken,
      foregroundColor: c.ink,
      child: Text(
        name.characters.firstOrNull?.toUpperCase() ?? '',
        style: PbText.bodyStrong,
      ),
    );
  }
}

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  Future<void> _coachActions(
    BuildContext context,
    WidgetRef ref,
    CoachLink link,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final status = await showPbSheet<LinkStatus>(context, _CoachSheet(link));
    if (status == null) return;
    try {
      await ref.read(linkRepositoryProvider).setStatus(link, status);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.inviteFailed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final coaches = ref.watch(myCoachesProvider).value ?? const [];
    final trainees = ref.watch(myTraineesProvider).value ?? const [];
    final activeCoach = ref.watch(activeCoachProvider);

    Widget label(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: PbSpace.s2),
      child: Text(text, style: PbText.label.copyWith(color: c.inkMuted)),
    );
    Widget person(
      String name,
      String caption, {
      required Widget trailing,
      required VoidCallback onTap,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: PbSpace.s2),
      child: GlassCard(
        onTap: onTap,
        child: Row(
          spacing: PbSpace.s3,
          children: [
            PersonAvatar(name),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: PbText.bodyStrong.copyWith(color: c.ink)),
                  Text(
                    caption,
                    style: PbText.caption.copyWith(color: c.inkMuted),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );

    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(PbSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: PbSpace.s3,
              children: [
                Text(
                  l10n.tabPeople,
                  style: PbText.title.copyWith(color: c.ink),
                ),
                Expanded(
                  child: coaches.isEmpty && trainees.isEmpty
                      ? Center(
                          child: Text(
                            l10n.peopleEmpty,
                            style: PbText.body.copyWith(color: c.inkMuted),
                          ),
                        )
                      : ListView(
                          children: [
                            if (coaches.isNotEmpty) label(l10n.peopleMyCoaches),
                            for (final link in coaches)
                              // Only the newest active coach really is one.
                              person(
                                link.coachName,
                                link.id == activeCoach?.id
                                    ? l10n.peopleCoachActive
                                    : l10n.peopleCoachReadOnly,
                                trailing: link.id == activeCoach?.id
                                    ? PbChip(
                                        l10n.chipActive,
                                        color: c.accentText,
                                      )
                                    : PbChip(l10n.chipReadOnly),
                                onTap: () => _coachActions(context, ref, link),
                              ),
                            if (trainees.isNotEmpty)
                              label(l10n.peopleMyTrainees),
                            for (final link in trainees)
                              person(
                                link.traineeName,
                                link.status == LinkStatus.active
                                    ? l10n.peopleTraineeActive
                                    : l10n.peopleTraineeReadOnly,
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: c.ink,
                                ),
                                onTap: () => context.push(Routes.trainee),
                              ),
                          ],
                        ),
                ),
                FilledButton(
                  onPressed: () => context.push(Routes.invite),
                  child: Text(l10n.peopleInvite),
                ),
                TextButton(
                  onPressed: () => context.push(Routes.inviteAccept),
                  child: Text(l10n.peopleEnterCode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What the trainee can do with a coach: turn read-only or remove.
class _CoachSheet extends StatelessWidget {
  const _CoachSheet(this.link);

  final CoachLink link;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final name = link.coachName;
    final hint = PbText.caption.copyWith(color: c.inkMuted);
    return PbSheet(
      children: [
        Row(
          spacing: PbSpace.s3,
          children: [
            PersonAvatar(name),
            Expanded(
              child: Text(
                l10n.coachSheetTitle(name),
                style: PbText.heading.copyWith(color: c.ink),
              ),
            ),
          ],
        ),
        if (link.status == LinkStatus.active) ...[
          OutlinedButton(
            onPressed: () => Navigator.pop(context, LinkStatus.readOnly),
            child: Text(l10n.coachDeactivate),
          ),
          Text(l10n.coachDeactivateHint(name), style: hint),
        ],
        FilledButton(
          onPressed: () => Navigator.pop(context, LinkStatus.removed),
          style: FilledButton.styleFrom(
            backgroundColor: c.danger,
            foregroundColor: c.ground,
          ),
          child: Text(l10n.builderDelete),
        ),
        Text(l10n.coachRemoveHint(name), style: hint),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.coachKeep),
        ),
      ],
    );
  }
}
