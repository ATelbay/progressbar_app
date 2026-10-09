// Focused native check of the shared keypad. Local Firebase only.
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:progressbar_app/app.dart';
import 'package:progressbar_app/data/exercise_catalog_repository.dart';
import 'package:progressbar_app/data/profile_repository.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/features/home/home_screen.dart';
import 'package:progressbar_app/features/workout/summary_entry.dart';
import 'package:progressbar_app/features/workout/workout_screen.dart';
import 'package:progressbar_app/firebase_options.dart';
import 'package:progressbar_app/l10n/app_localizations.dart';
import 'package:progressbar_app/widgets/step_button.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'numeric focus and final saves work with native fonts and storage',
    (tester) async {
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
        name: 'Проверка клавиатуры',
        phone: '+77010000011',
        languageCode: 'ru',
        theme: ThemeChoice.dark,
      );
      await profiles.save(profile);
      final catalog = await AssetExerciseCatalogRepository(rootBundle).load();
      final exercise = catalog.values.firstWhere(
        (e) => e.measure == Measure.reps && !e.usesBodyWeight,
      );

      Future<void> wait(Finder finder) async {
        for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(finder, findsWidgets);
      }

      Future<void> tap(Finder finder) async {
        await wait(finder);
        await tester.ensureVisible(finder.first);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(finder.first);
        await tester.pump(const Duration(milliseconds: 600));
      }

      Future<void> type(String value) async {
        for (final key in value.split('')) {
          await tap(find.widgetWithText(PbPill, key));
        }
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
      await wait(find.byType(HomeScreen));
      var l = AppLocalizations.of(tester.element(find.byType(HomeScreen)))!;
      await tap(find.text(l.homeNewProgram));
      await tester.enterText(find.byType(TextField), 'Клавиатура');
      await tester.pump(const Duration(milliseconds: 600));
      await tap(find.widgetWithText(OutlinedButton, l.pickerTitle));
      await tester.enterText(find.byType(TextField), exercise.nameFor('ru'));
      await tester.pump(const Duration(milliseconds: 600));
      await tap(find.text(exercise.nameFor('ru')).last);
      await wait(find.byType(SummaryEntry));
      await mark('SHOT:01-plan-sets');
      await type('3');
      await tap(find.widgetWithText(FilledButton, l.entryContinue));
      await type('1');
      await type('2');
      await tap(find.widgetWithText(FilledButton, l.entryContinue));
      await type('60');
      await mark('SHOT:02-plan-weight');
      await db.waitForPendingWrites();
      final programs = db.collection('users/$uid/programs');
      final before = (await programs.get()).docs.single.data();
      expect(before['days'][0]['exercises'], isEmpty);
      await tap(find.widgetWithText(FilledButton, l.welcomeDone));
      expect(find.byType(SummaryEntry), findsNothing);
      expect(find.text('3 × 12 × 60 кг', findRichText: true), findsOneWidget);
      await tap(find.text('3 × 12 × 60 кг', findRichText: true));
      await tap(find.text('+5'));
      await tap(find.widgetWithText(FilledButton, l.welcomeDone));
      await tap(find.text(l.builderStart));
      await wait(find.byType(WorkoutScreen));

      for (final (language, theme, large) in [
        ('ru', ThemeChoice.dark, false),
        ('ru', ThemeChoice.light, false),
        ('ru', ThemeChoice.light, true),
        ('kk', ThemeChoice.dark, true),
      ]) {
        await profiles.save(
          profile.copyWith(languageCode: () => language, theme: theme),
        );
        final translated = lookupAppLocalizations(Locale(language));
        await wait(find.text(translated.entrySets));
        l = AppLocalizations.of(tester.element(find.byType(WorkoutScreen)))!;
        await mark(large ? 'FONT:accessibility-large' : 'FONT:large');
        await tap(find.byKey(const ValueKey('entry-sets')));
        await type('3');
        await tap(find.widgetWithText(FilledButton, l.entryContinue));
        await type('8');
        await tap(find.widgetWithText(FilledButton, l.entryContinue));
        await type('65');
        final record = find.widgetWithText(FilledButton, l.entryRecord);
        await tester.ensureVisible(record);
        await tester.pump(const Duration(milliseconds: 300));
        expect(record.hitTestable(), findsOneWidget);
        expect(
          find.byKey(const ValueKey('entry-weight')).hitTestable(),
          findsOneWidget,
        );
        for (final key in ['1', '0']) {
          expect(
            find.widgetWithText(PbPill, key).hitTestable(),
            findsOneWidget,
          );
        }
        final unsaved = (await db.collection('users/$uid/workouts').get())
            .docs
            .single
            .data();
        expect(
          (unsaved['exercises'][0]['sets'] as List).map((s) => s['fact']),
          everyElement(isNull),
        );
        await mark(
          'SHOT:03-$language-${theme.name}-${large ? 'large' : 'normal'}',
        );
      }
      await tap(find.widgetWithText(FilledButton, l.entryRecord));
      await wait(find.text(l.workoutAllRecorded));
      await db.waitForPendingWrites();
      final saved = (await db.collection('users/$uid/workouts').get())
          .docs
          .single
          .data();
      final sets = saved['exercises'][0]['sets'] as List;
      expect(sets.length, 3);
      expect(sets.map((s) => s['plan']['reps']), everyElement(12));
      expect(sets.map((s) => s['plan']['weightKg']), everyElement(65));
      expect(sets.map((s) => s['fact']['reps']), everyElement(8));
      expect(sets.map((s) => s['fact']['weightKg']), everyElement(65));
      await mark('FONT:large');
      await mark('SHOT:04-recorded');
    },
  );
}
