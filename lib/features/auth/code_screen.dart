import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../widgets/glow_background.dart';
import 'auth_controller.dart';
import 'auth_messages.dart';

class CodeScreen extends ConsumerStatefulWidget {
  const CodeScreen({super.key});

  @override
  ConsumerState<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends ConsumerState<CodeScreen> {
  static const _length = 6;
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(AuthRepository) action) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(ref.read(authRepositoryProvider));
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = authErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _confirm() {
    if (_code.text.length == _length) {
      _run((auth) => auth.confirmCode(_code.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final phone = ref.watch(pendingPhoneProvider) ?? '';
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(),
      body: GlowBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(PbSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.codeTitle,
                  style: PbText.title.copyWith(color: c.ink),
                ),
                const SizedBox(height: PbSpace.s2),
                Text(
                  l10n.codeSentTo(phone),
                  style: PbText.body.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: PbSpace.s6),
                TextField(
                  controller: _code,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(_length),
                  ],
                  textAlign: TextAlign.center,
                  style: PbText.numLg.copyWith(color: c.ink, letterSpacing: 12),
                  decoration: InputDecoration(
                    labelText: l10n.codeLabel,
                    errorText: _error,
                    errorMaxLines: 3,
                  ),
                  onChanged: (_) {
                    setState(() {});
                    if (!_busy) _confirm();
                  },
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _busy || _code.text.length != _length
                      ? null
                      : _confirm,
                  child: Text(l10n.codeContinue),
                ),
                TextButton(
                  onPressed: _busy || phone.isEmpty
                      ? null
                      : () => _run((auth) => auth.sendCode(phone)),
                  child: Text(l10n.codeResend),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
