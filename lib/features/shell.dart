import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
