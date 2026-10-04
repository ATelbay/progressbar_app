import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'auth_controller.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.signInTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l10n.signInPhoneLabel),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signIn(),
                child: Text(l10n.signInContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
