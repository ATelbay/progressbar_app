import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/link_logic.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/step_button.dart';
import '../auth/auth_controller.dart';
import 'people_providers.dart';
import 'people_screen.dart';

class _Screen extends StatelessWidget {
  const _Screen({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.pb;
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(PbSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: PbSpace.s3,
              children: [
                Row(
                  spacing: PbSpace.s3,
                  children: [
                    StepButton(
                      icon: Icons.chevron_left,
                      label: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      size: PbSize.touchMin,
                      onTap: () => context.pop(),
                    ),
                    Text(title, style: PbText.title.copyWith(color: c.ink)),
                  ],
                ),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Choose the role to invite in, then show the code to pass on.
class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  LinkRole _role = LinkRole.coach;
  Invitation? _invitation;
  bool _busy = false;
  bool _failed = false;

  Future<void> _create() async {
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final invitation = await ref
          .read(linkRepositoryProvider)
          .createInvitation(
            inviterId: profile.id,
            inviterName: profile.name,
            role: _role,
          );
      if (mounted) setState(() => _invitation = invitation);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final muted = PbText.body.copyWith(color: c.inkMuted);
    final invitation = _invitation;
    if (invitation != null) {
      final code = formatInviteCode(invitation.code);
      return _Screen(
        title: l10n.inviteTitle,
        children: [
          Text(
            invitation.inviterRole == LinkRole.coach
                ? l10n.inviteShowCoach
                : l10n.inviteShowTrainee,
            style: muted,
          ),
          GlassPanel(
            child: Column(
              spacing: PbSpace.s2,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SelectableText(
                    code,
                    style: PbText.numHero.copyWith(color: c.ink),
                  ),
                ),
                Text(
                  l10n.inviteValid,
                  style: PbText.caption.copyWith(color: c.inkMuted),
                ),
              ],
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: code));
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.inviteCopied)),
              );
            },
            child: Text(l10n.inviteCopy),
          ),
        ],
      );
    }
    Widget choice(LinkRole role, String title, String hint) => GlassCard(
      current: _role == role,
      onTap: () => setState(() => _role = role),
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: _role == role,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: PbSpace.s1,
          children: [
            Text(title, style: PbText.heading.copyWith(color: c.ink)),
            Text(hint, style: PbText.caption.copyWith(color: c.inkMuted)),
          ],
        ),
      ),
    );
    return _Screen(
      title: l10n.peopleInvite,
      children: [
        Text(l10n.inviteRoleQuestion, style: muted),
        choice(LinkRole.coach, l10n.inviteAsCoach, l10n.inviteAsCoachHint),
        choice(
          LinkRole.trainee,
          l10n.inviteAsTrainee,
          l10n.inviteAsTraineeHint,
        ),
        if (_failed)
          Text(l10n.inviteFailed, style: PbText.body.copyWith(color: c.danger)),
        const Spacer(),
        FilledButton(
          onPressed: _busy ? null : _create,
          child: Text(l10n.inviteCreate),
        ),
      ],
    );
  }
}

/// Type a code, see who invites and in which role, then accept or not.
class InviteAcceptScreen extends ConsumerStatefulWidget {
  const InviteAcceptScreen({super.key});

  @override
  ConsumerState<InviteAcceptScreen> createState() => _InviteAcceptScreenState();
}

class _InviteAcceptScreenState extends ConsumerState<InviteAcceptScreen> {
  final _code = TextEditingController();
  Invitation? _invitation;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) setState(() => _error = l10n.inviteFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _find() => _run(() async {
    final l10n = AppLocalizations.of(context)!;
    final code = normalizeInviteCode(_code.text);
    final found = code == null
        ? null
        : await ref.read(linkRepositoryProvider).findInvitation(code);
    if (!mounted) return;
    setState(() {
      if (found == null) {
        _error = l10n.inviteNotFound;
      } else if (found.inviterId == ref.read(uidProvider).value) {
        _error = l10n.inviteOwn;
      } else {
        _invitation = found;
      }
    });
  });

  Future<void> _accept(Invitation invitation) => _run(() async {
    final profile = ref.read(profileProvider).value!;
    await ref
        .read(linkRepositoryProvider)
        .accept(invitation, acceptorId: profile.id, acceptorName: profile.name);
    if (mounted) context.pop();
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final invitation = _invitation;
    final fromCoach = invitation?.inviterRole == LinkRole.coach;
    // Accepting a coach replaces the current active one.
    final current = fromCoach ? ref.watch(activeCoachProvider) : null;
    final replaces =
        current != null && current.coachId != invitation?.inviterId;
    return _Screen(
      title: l10n.inviteTitle,
      children: [
        TextField(
          controller: _code,
          enabled: invitation == null,
          autofocus: true,
          autocorrect: false,
          textCapitalization: TextCapitalization.characters,
          style: PbText.numMd.copyWith(color: c.ink),
          decoration: InputDecoration(
            labelText: l10n.inviteCodeLabel,
            errorText: _error,
            errorMaxLines: 3,
          ),
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) => _find(),
        ),
        if (invitation != null) ...[
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: PbSpace.s3,
              children: [
                Row(
                  spacing: PbSpace.s3,
                  children: [
                    PersonAvatar(invitation.inviterName, large: true),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invitation.inviterName,
                            style: PbText.heading.copyWith(color: c.ink),
                          ),
                          Text(
                            fromCoach
                                ? l10n.inviteFromCoach
                                : l10n.inviteFromTrainee,
                            style: PbText.caption.copyWith(color: c.inkMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  fromCoach
                      ? l10n.inviteCoachWill(invitation.inviterName)
                      : l10n.inviteTraineeWill(invitation.inviterName),
                  style: PbText.body.copyWith(color: c.inkMuted),
                ),
              ],
            ),
          ),
          if (replaces)
            Text(
              l10n.inviteCurrentCoach(current.coachName),
              style: PbText.caption.copyWith(color: c.warning),
            ),
        ],
        const Spacer(),
        if (invitation == null)
          FilledButton(
            onPressed: _busy || normalizeInviteCode(_code.text) == null
                ? null
                : _find,
            child: Text(l10n.inviteFind),
          )
        else ...[
          FilledButton(
            onPressed: _busy ? null : () => _accept(invitation),
            child: Text(replaces ? l10n.inviteAcceptActive : l10n.inviteAccept),
          ),
          OutlinedButton(
            onPressed: () => context.pop(),
            child: Text(l10n.inviteDecline),
          ),
        ],
      ],
    );
  }
}
