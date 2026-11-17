// Verifies real font metrics inside the floating navigation on both platforms.
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:progressbar_app/app.dart';
import 'package:progressbar_app/data/profile_repository.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/firebase_options.dart';
import 'package:progressbar_app/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('large localized labels and icons stay inside navigation', (
    tester,
  ) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    final db = FirebaseFirestore.instance..useFirestoreEmulator(host, 8080);
    final auth = FirebaseAuth.instance;
    await auth.useAuthEmulator(host, 9099);
    await auth.signOut();
    final uid = (await auth.signInAnonymously()).user!.uid;
    final profiles = FirestoreProfileRepository(db);
    final profile = UserProfile(
      id: uid,
      name: 'Проверка навигации',
      phone: '+77010000031',
      bodyWeightKg: 82.5,
      languageCode: 'ru',
      theme: ThemeChoice.dark,
    );
    await profiles.save(profile);
    Future<void> wait(Finder finder) async {
      for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(finder, findsWidgets);
    }

    Future<void> mark(String line) async {
      // ignore: avoid_print
      print(line);
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(const ProviderScope(child: ProgressBarApp()));
    await wait(find.byType(NavigationBar));
    await tester.tap(
      find.text(lookupAppLocalizations(const Locale('ru')).tabProfile).last,
    );
    await tester.pump(const Duration(milliseconds: 600));
    await mark('FONT:accessibility-large');
    for (final language in ['ru', 'en', 'kk']) {
      for (final theme in [ThemeChoice.dark, ThemeChoice.light]) {
        await profiles.save(
          profile.copyWith(languageCode: () => language, theme: theme),
        );
        final l = lookupAppLocalizations(Locale(language));
        final bar = find.byType(NavigationBar);
        await wait(find.descendant(of: bar, matching: find.text(l.tabHome)));
        await tester.pump(const Duration(milliseconds: 800));
        final bounds = tester.getRect(bar);
        final labels = [
          l.tabHome,
          l.tabHistory,
          l.tabProgress,
          l.tabPeople,
          l.tabProfile,
        ];
        for (final label in labels) {
          final rect = tester.getRect(
            find.descendant(of: bar, matching: find.text(label)),
          );
          expect(rect.top, greaterThanOrEqualTo(bounds.top), reason: label);
          expect(rect.bottom, lessThanOrEqualTo(bounds.bottom), reason: label);
        }
        for (final element
            in find
                .descendant(of: bar, matching: find.byType(Icon))
                .evaluate()) {
          final box = element.renderObject! as RenderBox;
          final rect = box.localToGlobal(Offset.zero) & box.size;
          expect(rect.top, greaterThanOrEqualTo(bounds.top));
          expect(rect.bottom, lessThanOrEqualTo(bounds.bottom));
        }
        await mark('SHOT:nav-$language-${theme.name}-large');
      }
    }
    await mark('FONT:large');
    await auth.signOut();
  });
}
