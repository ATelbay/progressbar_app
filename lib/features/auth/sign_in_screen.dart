import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/auth_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../router.dart';
import '../../theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glow_background.dart';
import 'auth_controller.dart';
import 'auth_messages.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _phone = TextEditingController(text: '+7 ');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final phone = normalizePhone(_phone.text);
    if (phone == null) {
      setState(() => _error = l10n.errorInvalidPhone);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendCode(phone);
      ref.read(pendingPhoneProvider.notifier).set(phone);
      if (mounted) context.push(Routes.signInCode);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = authErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(PbSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: PbSpace.s8 * 2),
                Text(
                  l10n.appTitle,
                  style: PbText.numHero.copyWith(
                    fontSize: 88,
                    height: 0.92,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: PbSpace.s6),
                Text(
                  l10n.signInTagline,
                  style: PbText.body.copyWith(color: c.inkMuted),
                ),
                const Spacer(),
                GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        style: PbText.heading.copyWith(color: c.ink),
                        decoration: InputDecoration(
                          labelText: l10n.signInPhoneLabel,
                          errorText: _error,
                          errorMaxLines: 3,
                        ),
                      ),
                      const SizedBox(height: PbSpace.s3),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: Text(l10n.signInGetCode),
                      ),
                      const SizedBox(height: PbSpace.s3),
                      Text(
                        l10n.signInSmsHint,
                        textAlign: TextAlign.center,
                        style: PbText.caption.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
