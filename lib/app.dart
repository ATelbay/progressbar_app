import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'features/auth/auth_controller.dart';
import 'router.dart';
import 'theme.dart';

class ProgressBarApp extends ConsumerWidget {
  const ProgressBarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      // The language chosen in the profile; without one, the phone's.
      locale: switch (ref.watch(profileProvider).value?.languageCode) {
        final code? => Locale(code),
        null => null,
      },
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
