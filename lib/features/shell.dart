import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/link_logic.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'auth/auth_controller.dart';
import 'people/people_providers.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // A trainee has one active coach. A link made by someone else's accept
    // may leave two; this device turns the older ones read-only.
    ref.listen(myCoachesProvider, (_, next) {
      final uid = ref.read(uidProvider).value;
      if (uid == null) return;
      for (final link in linksToDemote(uid, next.value ?? const [])) {
        unawaited(
          ref
              .read(linkRepositoryProvider)
              .setStatus(link, LinkStatus.readOnly)
              .catchError((_) {}),
        );
      }
    });
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.fitness_center),
            label: l10n.tabHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history),
            label: l10n.tabHistory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.show_chart),
            label: l10n.tabProgress,
          ),
          NavigationDestination(
            icon: const Icon(Icons.group_outlined),
            label: l10n.tabPeople,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            label: l10n.tabProfile,
          ),
        ],
      ),
    );
  }
}
