import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabHome)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: () => context.push(Routes.workout),
              child: Text(l10n.homeStartFreeWorkout),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push(Routes.programBuilder),
              child: Text(l10n.homeNewProgram),
            ),
          ],
        ),
      ),
    );
  }
}
