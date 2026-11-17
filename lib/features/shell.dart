import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/link_logic.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'auth/auth_controller.dart';
import '../router.dart';
import 'people/people_providers.dart';
import '../theme.dart';
import '../widgets/glass_panel.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final destinations = [
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
    ];
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
    final invited = ref.watch(pendingInviteCodeProvider);
    if (invited != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(pendingInviteCodeProvider) != invited) return;
        ref.read(pendingInviteCodeProvider.notifier).set(null);
        context.push('${Routes.inviteAccept}?code=$invited');
      });
    }
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(PbSpace.s2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // NavigationBar caps labels at 1.3. Reserve their actual wrapped
            // height so long localized names stay inside the glass at that scale.
            var labelHeight = 0.0;
            for (final destination in destinations) {
              final painter = TextPainter(
                text: TextSpan(text: destination.label, style: PbText.navLabel),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context)
                    .clamp(maxScaleFactor: 1.3),
              )..layout(maxWidth: constraints.maxWidth / destinations.length);
              labelHeight = math.max(labelHeight, painter.height);
              painter.dispose();
            }
            final labelSize = PbText.navLabel.fontSize!;
            final scaledSize = MediaQuery.textScalerOf(context)
                .clamp(maxScaleFactor: 1.3)
                .scale(labelSize);
            if (scaledSize > labelSize) {
              // Platform font metrics can wrap a localized label after this
              // measurement. Keep room for two lines at enlarged text sizes.
              labelHeight = math.max(
                labelHeight,
                scaledSize * PbText.navLabel.height! * 2,
              );
            }
            return GlassPanel(
              padding: EdgeInsets.zero,
              child: NavigationBar(
                height: math.max(
                  PbSize.tabBarHeight,
                  PbSize.touchMin + labelHeight,
                ),
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (index) => navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                ),
                destinations: destinations,
              ),
            );
          },
        ),
      ),
    );
  }
}
