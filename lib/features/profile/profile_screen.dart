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
import '../auth/auth_controller.dart';
import '../format.dart';
import '../workout/number_field.dart';

/// Languages the interface is translated into, under their own names.
const _languages = [('ru', 'Русский'), ('en', 'English'), ('kk', 'Қазақша')];

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _save(WidgetRef ref, UserProfile profile) => unawaited(
    ref.read(profileRepositoryProvider).save(profile).catchError((_) {}),
  );

  Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showPbSheet<(String?,)>(
      context,
      ChoiceSheet<String?>(
        title: l10n.profileLanguage,
        selected: profile.languageCode,
        options: [(null, l10n.languageSystem), ..._languages],
      ),
    );
    if (picked != null) {
      _save(ref, profile.copyWith(languageCode: () => picked.$1));
    }
  }

  static String _themeName(AppLocalizations l10n, ThemeChoice theme) =>
      switch (theme) {
        ThemeChoice.system => l10n.languageSystem,
        ThemeChoice.dark => l10n.themeDark,
        ThemeChoice.light => l10n.themeLight,
      };

  Future<void> _pickTheme(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showPbSheet<(ThemeChoice,)>(
      context,
      ChoiceSheet<ThemeChoice>(
        title: l10n.profileTheme,
        selected: profile.theme,
        options: [
          for (final theme in ThemeChoice.values)
            (theme, _themeName(l10n, theme)),
        ],
      ),
    );
    if (picked != null) _save(ref, profile.copyWith(theme: picked.$1));
  }

  Future<void> _pickEntryMode(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showPbSheet<(EntryMode,)>(
      context,
      ChoiceSheet<EntryMode>(
        title: l10n.profileEntryMode,
        selected: profile.entryMode,
        options: [
          (EntryMode.summary, l10n.entryModeSummary),
          (EntryMode.perSet, l10n.entryModePerSet),
        ],
      ),
    );
    if (picked != null) _save(ref, profile.copyWith(entryMode: picked.$1));
  }

  Future<void> _editAccount(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final edited = await showPbSheet<UserProfile>(
      context,
      _AccountSheet(profile),
    );
    if (edited != null) _save(ref, edited);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final profile = ref.watch(profileProvider).value;
    final muted = PbText.body.copyWith(color: c.inkMuted);

    Widget setting(
      String title, {
      String? value,
      required VoidCallback onTap,
    }) => GlassCard(
      onTap: onTap,
      child: Row(
        spacing: PbSpace.s3,
        children: [
          Expanded(
            child: Text(title, style: PbText.bodyStrong.copyWith(color: c.ink)),
          ),
          if (value != null)
            Text(value, style: muted)
          else
            Icon(Icons.chevron_right, color: c.ink),
        ],
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
                  l10n.tabProfile,
                  style: PbText.title.copyWith(color: c.ink),
                ),
                Expanded(
                  child: profile == null
                      ? const SizedBox()
                      : ListView(
                          children: [
                            Semantics(
                              button: true,
                              label: l10n.profileEdit,
                              child: _Account(
                                profile,
                                onTap: () =>
                                    _editAccount(context, ref, profile),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: PbSpace.s3,
                              ),
                              child: Text(
                                l10n.profileSettings,
                                style: PbText.label.copyWith(color: c.inkMuted),
                              ),
                            ),
                            setting(
                              l10n.profileLanguage,
                              value:
                                  _languages
                                      .where(
                                        (l) => l.$1 == profile.languageCode,
                                      )
                                      .firstOrNull
                                      ?.$2 ??
                                  l10n.languageSystem,
                              onTap: () => _pickLanguage(context, ref, profile),
                            ),
                            const SizedBox(height: PbSpace.s2),
                            setting(
                              l10n.profileTheme,
                              value: _themeName(l10n, profile.theme),
                              onTap: () => _pickTheme(context, ref, profile),
                            ),
                            const SizedBox(height: PbSpace.s2),
                            setting(
                              l10n.profileEntryMode,
                              value: profile.entryMode == EntryMode.summary
                                  ? l10n.entryModeSummary
                                  : l10n.entryModePerSet,
                              onTap: () =>
                                  _pickEntryMode(context, ref, profile),
                            ),
                            const SizedBox(height: PbSpace.s2),
                            setting(
                              l10n.profileCatalog,
                              onTap: () => context.push(Routes.exerciseCatalog),
                            ),
                          ],
                        ),
                ),
                OutlinedButton.icon(
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.profileSignOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Account extends StatelessWidget {
  const _Account(this.profile, {required this.onTap});

  final UserProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final weight = profile.bodyWeightKg;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: GlassPanel(
        child: Row(
          spacing: PbSpace.s3,
          children: [
            CircleAvatar(
              radius: PbSize.actionHeight / 2,
              backgroundColor: c.sunken,
              foregroundColor: c.ink,
              child: Text(
                profile.name.characters.firstOrNull?.toUpperCase() ?? '',
                style: PbText.heading,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: PbText.heading.copyWith(color: c.ink),
                  ),
                  Text(
                    profile.phone,
                    style: PbText.caption.copyWith(color: c.inkMuted),
                  ),
                ],
              ),
            ),
            if (weight != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.welcomeBodyWeight,
                    style: PbText.label.copyWith(color: c.inkMuted),
                  ),
                  NumberText(
                    NumberLine([
                      (formatNumber(context, weight), false),
                      (' ${l10n.unitKg}', true),
                    ]),
                    style: PbText.numMd,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AccountSheet extends StatefulWidget {
  const _AccountSheet(this.profile);

  final UserProfile profile;

  @override
  State<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<_AccountSheet> {
  static const _minKg = 30.0, _maxKg = 250.0, _stepKg = 0.5;
  late final _name = TextEditingController(text: widget.profile.name);
  late double _weightKg = widget.profile.bodyWeightKg ?? 75;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    return PbSheet(
      children: [
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          style: PbText.heading.copyWith(color: c.ink),
          decoration: InputDecoration(labelText: l10n.welcomeNameLabel),
          onChanged: (_) => setState(() {}),
        ),
        NumberField(
          label: l10n.welcomeBodyWeight,
          value: formatNumber(context, _weightKg),
          unit: l10n.unitKg,
          style: PbText.numLg,
          onStep: (d) => setState(
            () => _weightKg = (_weightKg + d * _stepKg).clamp(_minKg, _maxKg),
          ),
        ),
        Text(
          l10n.welcomeBodyWeightHint,
          style: PbText.caption.copyWith(color: c.inkMuted),
        ),
        FilledButton(
          onPressed: _name.text.trim().isEmpty
              ? null
              : () => Navigator.pop(
                  context,
                  widget.profile.copyWith(
                    name: _name.text.trim(),
                    bodyWeightKg: _weightKg,
                  ),
                ),
          child: Text(l10n.exerciseSave),
        ),
      ],
    );
  }
}
