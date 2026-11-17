// Native motion and gestures; all account/storage dependencies are in memory.
import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:progressbar_app/app.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/features/auth/auth_controller.dart';
import 'package:progressbar_app/features/exercises/exercise_catalog_provider.dart';
import 'package:progressbar_app/features/exercises/exercise_picker_screen.dart';
import 'package:progressbar_app/features/firestore_provider.dart';
import 'package:progressbar_app/features/home/home_screen.dart';
import 'package:progressbar_app/features/profile/profile_screen.dart';
import 'package:progressbar_app/l10n/app_localizations.dart';

import '../test/support/fakes.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
    'native tabs, interrupted transitions, routes and reduced motion',
    (tester) async {
      debugDefaultTargetPlatformOverride = Platform.isIOS
          ? TargetPlatform.iOS
          : TargetPlatform.android;
      try {
        final profiles = FakeProfileRepository();
        const profile = UserProfile(
          id: 'motion-user',
          name: 'Проверка переходов',
          phone: '+77010000041',
          bodyWeightKg: 80,
          languageCode: 'ru',
          theme: ThemeChoice.dark,
        );
        await profiles.save(profile);
        final reduced = ValueNotifier(false);
        addTearDown(reduced.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                FakeAuthRepository(signedInAs: profile.id),
              ),
              profileRepositoryProvider.overrideWithValue(profiles),
              firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
              exerciseCatalogProvider.overrideWith((ref) => const {}),
            ],
            child: ValueListenableBuilder<bool>(
              valueListenable: reduced,
              builder: (context, value, _) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: value),
                child: const ProgressBarApp(),
              ),
            ),
          ),
        );
        final l = lookupAppLocalizations(const Locale('ru'));
        Future<void> wait(Finder finder) async {
          for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          expect(finder, findsWidgets);
        }

        void mark(String label) {
          // ignore: avoid_print
          print('MOTION:$label');
        }

        Future<void> tab(String label, {int milliseconds = 600}) async {
          await tester.tap(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.text(label),
            ),
          );
          await tester.pump(Duration(milliseconds: milliseconds));
          expect(tester.takeException(), isNull);
        }

        await wait(find.byType(HomeScreen));
        mark('start');
        await tester.pump(const Duration(seconds: 2));
        for (final small in [false, true]) {
          reduced.value = small;
          await profiles.save(
            profile.copyWith(
              theme: small ? ThemeChoice.light : ThemeChoice.dark,
            ),
          );
          await tester.pump(const Duration(milliseconds: 500));
          final phase = small ? 'reduced' : 'normal';
          mark('$phase-profile');
          await tab(l.tabProfile);
          mark('$phase-history');
          await tab(l.tabHistory);
          mark('$phase-home');
          await tab(l.tabHome);
          mark('$phase-people');
          await tab(l.tabPeople);
          mark('$phase-profile-again');
          await tab(l.tabProfile);
          await wait(find.byType(ProfileScreen));
          mark('$phase-open-catalog');
          await tester.tap(find.text(l.profileCatalog));
          await tester.pump(const Duration(milliseconds: 800));
          if (Platform.isIOS) {
            final pickerContext = tester.element(
              find.byType(ExercisePickerScreen),
            );
            expect(Theme.of(pickerContext).platform, TargetPlatform.iOS);
            expect(
              ModalRoute.of(pickerContext)!.settings,
              isA<MaterialPage<void>>(),
            );
            expect(
              (ModalRoute.of(pickerContext)! as PageRoute).popGestureEnabled,
              isTrue,
            );
            mark('$phase-edge-back');
            final route = ModalRoute.of(pickerContext)! as PageRoute;
            final bounds = tester.getRect(find.byType(ExercisePickerScreen));
            final width = bounds.width;
            final edge = bounds.topLeft + Offset(2, bounds.height / 2);
            final gesture = await tester.startGesture(edge);
            await gesture.moveBy(const Offset(50, 0));
            await tester.pump(const Duration(milliseconds: 50));
            expect(route.popGestureInProgress, isTrue);
            for (var step = 0; step < 5; step++) {
              await gesture.moveBy(Offset((width * .85 - 50) / 5, 0));
              await tester.pump(const Duration(milliseconds: 40));
            }
            expect(route.animation!.value, lessThan(.5));
            await gesture.up();
          } else {
            mark('$phase-system-back');
            await tester.binding.handlePopRoute();
          }
          await tester.pump(const Duration(milliseconds: 700));
          expect(find.byType(ProfileScreen), findsOneWidget);
          expect(find.byType(NavigationBar), findsOneWidget);
          mark('$phase-rapid-tabs');
          await tab(l.tabHistory, milliseconds: 50);
          await tab(l.tabProgress, milliseconds: 50);
          await tab(l.tabHome);
          expect(find.byType(HomeScreen), findsOneWidget);
        }
        await tester.pump(const Duration(seconds: 1));
        mark('stop');
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
