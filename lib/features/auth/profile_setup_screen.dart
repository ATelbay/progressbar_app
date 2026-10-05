import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glow_background.dart';
import 'auth_controller.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  static const _minKg = 30.0, _maxKg = 250.0, _stepKg = 0.5;
  final _name = TextEditingController();
  double _bodyWeightKg = 75;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _nudge(double by) => setState(
    () => _bodyWeightKg = (_bodyWeightKg + by).clamp(_minKg, _maxKg),
  );

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _name.text.trim();
    final uid = ref.read(uidProvider).value;
    if (name.isEmpty) {
      setState(() => _error = l10n.errorNameRequired);
      return;
    }
    if (uid == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(profileRepositoryProvider)
          .save(
            UserProfile(
              id: uid,
              name: name,
              phone: ref.read(authRepositoryProvider).phoneNumber ?? '',
              bodyWeightKg: _bodyWeightKg,
            ),
          );
    } catch (_) {
      if (mounted) setState(() => _error = l10n.errorNetwork);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final weight = _bodyWeightKg == _bodyWeightKg.roundToDouble()
        ? _bodyWeightKg.toStringAsFixed(0)
        : _bodyWeightKg.toStringAsFixed(1).replaceAll('.', ',');
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(PbSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: PbSpace.s6),
                Text(
                  l10n.welcomeTitle,
                  style: PbText.title.copyWith(color: c.ink),
                ),
                const SizedBox(height: PbSpace.s2),
                Text(
                  l10n.welcomeHint,
                  style: PbText.body.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: PbSpace.s6),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.givenName],
                  style: PbText.heading.copyWith(color: c.ink),
                  decoration: InputDecoration(
                    labelText: l10n.welcomeNameLabel,
                    errorText: _error,
                    errorMaxLines: 3,
                  ),
                ),
                const SizedBox(height: PbSpace.s4),
                GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.welcomeBodyWeight,
                        style: PbText.label.copyWith(color: c.inkMuted),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: weight,
                                children: [
                                  TextSpan(
                                    text: ' ${l10n.unitKg}',
                                    style: PbText.numMd.copyWith(
                                      color: c.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                              style: PbText.numHero.copyWith(color: c.ink),
                            ),
                          ),
                          _Step(
                            icon: Icons.remove,
                            label: l10n.decreaseBodyWeight,
                            onTap: () => _nudge(-_stepKg),
                          ),
                          const SizedBox(width: PbSpace.s2),
                          _Step(
                            icon: Icons.add,
                            label: l10n.increaseBodyWeight,
                            onTap: () => _nudge(_stepKg),
                          ),
                        ],
                      ),
                      const SizedBox(height: PbSpace.s2),
                      Text(
                        l10n.welcomeBodyWeightHint,
                        style: PbText.caption.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: Text(l10n.welcomeDone),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.pb;
    return IconButton(
      onPressed: onTap,
      tooltip: label,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(PbSize.actionHeight),
        backgroundColor: c.sunken,
        foregroundColor: c.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PbRadius.md),
        ),
      ),
    );
  }
}
