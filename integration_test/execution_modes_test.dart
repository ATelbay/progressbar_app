// Native flow and real local Firestore storage; never uses production data.
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
import 'package:progressbar_app/data/firestore_codec.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/features/exercises/exercise_catalog_provider.dart';
import 'package:progressbar_app/features/home/home_screen.dart';
import 'package:progressbar_app/features/history/history_screen.dart';
import 'package:progressbar_app/features/workout/execution_entry_panel.dart';
import 'package:progressbar_app/features/workout/number_keypad.dart';
import 'package:progressbar_app/features/workout/summary_entry.dart';
import 'package:progressbar_app/firebase_options.dart';
import 'package:progressbar_app/l10n/app_localizations.dart';
import 'package:progressbar_app/widgets/step_button.dart';

const catalog = {
  'a': Exercise(
    id: 'a',
    names: {'ru': 'Выпады', 'en': 'Lunges', 'kk': 'Алға адымдау'},
    muscleGroup: 'legs',
  ),
  'b': Exercise(
    id: 'b',
    names: {'ru': 'Приседания', 'en': 'Squats', 'kk': 'Отырып-тұру'},
    muscleGroup: 'legs',
  ),
  'c': Exercise(
    id: 'c',
    names: {'ru': 'Жим ногами', 'en': 'Leg press', 'kk': 'Аяқпен сығымдау'},
    muscleGroup: 'legs',
  ),
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'plan, full and summary execution groups persist online and offline',
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
        name: 'Проверка режимов',
        phone: '+77010000021',
        languageCode: 'ru',
        theme: ThemeChoice.dark,
      );
      await profiles.save(profile);
      var l = lookupAppLocalizations(const Locale('ru'));
      Future<void> wait(Finder f) async {
        for (var i = 0; i < 100 && f.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(f, findsWidgets);
      }

      Future<void> tap(Finder f) async {
        await wait(f);
        if (f.last.hitTestable().evaluate().isEmpty) {
          await tester.ensureVisible(f.last);
        }
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(f.last);
        await tester.pump(const Duration(milliseconds: 550));
        expect(tester.takeException(), isNull);
      }

      Future<void> type(String value) async {
        for (final digit in value.split('')) {
          await tap(
            find.descendant(
              of: find.byType(NumberKeypad),
              matching: find.widgetWithText(PbPill, digit),
            ),
          );
        }
      }

      Future<void> next() async => tap(find.byType(FilledButton).last);
      Future<void> values({String? reps, String? weight}) async {
        if (reps != null) await type(reps);
        await next();
        if (weight != null) await type(weight);
      }

      Future<void> mark(String line) async {
        // ignore: avoid_print
        print(line);
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(tester.takeException(), isNull);
      }

      Future<void> add(String name) async {
        await tap(find.widgetWithText(OutlinedButton, l.pickerTitle));
        await tester.enterText(find.byType(TextField), name);
        await tester.pump(const Duration(milliseconds: 400));
        await tap(find.text(name).last);
        await wait(find.byType(SummaryEntry));
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [exerciseCatalogProvider.overrideWith((ref) => catalog)],
          child: const ProgressBarApp(),
        ),
      );
      await wait(find.byType(HomeScreen));
      await tap(find.text(l.homeNewProgram));
      await tester.enterText(find.byType(TextField), 'Режимы');
      await tester.pump(const Duration(milliseconds: 500));
      await add('Выпады');
      await tap(find.text(l.executionSuperset));
      await tap(find.text(l.executionAddMember));
      await wait(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Приседания');
      await tester.pump(const Duration(milliseconds: 400));
      await tap(find.text('Приседания').last);
      await wait(find.byType(SummaryEntry));
      await type('2');
      await next();
      await values(reps: '12', weight: '20');
      await mark('SHOT:01-plan-superset');
      await next();
      await values(reps: '8', weight: '60');
      await tap(find.widgetWithText(FilledButton, l.welcomeDone));
      await add('Жим ногами');
      await tap(find.text(l.executionDropSet));
      await type('2');
      await next();
      await values(reps: '10', weight: '100');
      await tap(find.text(l.executionAddDrop));
      await values(reps: '8', weight: '75');
      await mark('SHOT:02-plan-drop');
      await tap(find.widgetWithText(FilledButton, l.welcomeDone));
      await db.waitForPendingWrites();
      final programDoc =
          (await db.collection('users/$uid/programs').get()).docs.single;
      final plan = programFromMap(programDoc.id, programDoc.data());
      expect(
        plan.days.single.exercises.take(2).map((e) => e.groupId).toSet().length,
        1,
      );
      expect(plan.days.single.exercises.last.dropStages.single.weightKg, 75);
      await mark('SHOT:03-plan-groups');
      await tap(find.text(l.builderStart));
      await wait(find.byType(ExecutionEntryPanel));
      await tap(
        find.byTooltip(
          MaterialLocalizations.of(
            tester.element(find.byType(ExecutionEntryPanel)),
          ).backButtonTooltip,
        ),
      );
      await wait(find.byType(HomeScreen));
      await mark('SHOT:03b-home-dark');
      await tap(find.text(l.tabProfile));
      await mark('SHOT:03c-profile-dark');
      await profiles.save(profile.copyWith(theme: ThemeChoice.light));
      await tester.pump(const Duration(milliseconds: 700));
      await mark('SHOT:03d-profile-light');
      await tap(find.text(l.tabHome));
      await mark('SHOT:03e-home-light');
      await profiles.save(profile);
      await tap(find.text(l.homeContinue));
      await wait(find.byType(ExecutionEntryPanel));
      await tap(find.text(l.entryModePerSet));
      for (var i = 0; i < 4; i++) {
        await wait(find.text(l.executionMember(i.isEven ? 1 : 2, 2)));
        await values(
          reps: i.isEven ? '12' : '8',
          weight: i.isEven ? '20' : '60',
        );
        if (i == 1) {
          await mark('SHOT:04-full-superset');
          await tap(find.byKey(const ValueKey('execution-controls')));
          await mark('SHOT:04b-superset-controls');
          await tap(find.text(l.executionContinueRecord));
        }
        await next();
      }
      await wait(find.text(l.executionDropSet));
      // The chosen full-entry mode carries over to the following group.
      await db.disableNetwork();
      await values(reps: '10', weight: '100');
      await next();
      await values(reps: '8', weight: '75');
      await tap(find.byKey(const ValueKey('execution-controls')));
      await mark('SHOT:05a-drop-controls');
      await tap(find.text(l.executionAddDrop));
      await values(reps: '6', weight: '50');
      await mark('SHOT:05-drop-extra-offline');
      await tap(find.text(l.executionRecordDropSet));
      await db.enableNetwork();
      await db.waitForPendingWrites();
      await values(reps: '9', weight: '100');
      await tap(find.byKey(const ValueKey('execution-controls')));
      await tap(find.text(l.executionFinishDrop));
      await wait(find.text(l.workoutAllRecorded));
      await db.waitForPendingWrites();
      var active =
          (await db.collection('users/$uid/workouts').get()).docs.single;
      var stored = workoutFromMap(active.id, active.data());
      expect(
        stored.exercises.last.sets.first.drops.map((d) => d.fact!.weightKg),
        [75, 50],
      );
      expect(stored.exercises.last.sets.last.drops.single.fact, isNull);
      expect(stored.exercises.last.sets.every((s) => s.dropComplete), isTrue);
      await tap(find.widgetWithText(FilledButton, l.workoutFinish));
      await tap(find.widgetWithText(FilledButton, l.workoutFinish));
      await wait(find.byType(HomeScreen));
      await tap(find.text(l.tabHistory));
      await wait(find.byType(HistoryScreen));
      await mark('SHOT:06-history-stages');
      await tap(find.byType(ExpansionTile).first);
      await mark('SHOT:06a-history-superset');
      await tap(find.byType(ExpansionTile).last);
      await tester.ensureVisible(find.byType(PlanFactRow).last);
      await mark('SHOT:06b-history-drop');
      await profiles.save(profile.copyWith(theme: ThemeChoice.light));
      await tester.pump(const Duration(milliseconds: 700));
      await mark('SHOT:06c-history-drop-light');
      await profiles.save(profile);
      await tap(find.text(l.tabHome));
      await tap(find.text('Режимы'));
      await tap(find.text(l.builderStart));
      await wait(find.byType(ExecutionEntryPanel));
      await tap(find.text(l.entrySummaryOnly));
      await type('2');
      await next();
      await values();
      await next();
      await values();
      await tap(find.text(l.executionRecordSuperset));
      await wait(find.text(l.executionDropSet));
      await type('2');
      await next();
      await values();
      await next();
      await values();
      await mark('SHOT:07-summary-drop');
      await tap(find.text(l.executionRecordDrops));
      await wait(find.text(l.workoutAllRecorded));
      await db.waitForPendingWrites();
      final docs = (await db.collection('users/$uid/workouts').get()).docs;
      stored = docs
          .map((d) => workoutFromMap(d.id, d.data()))
          .firstWhere((w) => !w.isCompleted);
      expect(stored.exercises.last.sets.length, 2);
      expect(
        stored.exercises.last.sets.map((s) => s.drops.single.fact!.weightKg),
        [75, 75],
      );
      // Verify both themes and Kazakh with the actual system large-font setting.
      await tap(find.text('Жим ногами').last);
      for (final (language, theme, large) in [
        ('ru', ThemeChoice.light, false),
        ('kk', ThemeChoice.dark, true),
      ]) {
        await profiles.save(
          profile.copyWith(languageCode: () => language, theme: theme),
        );
        l = lookupAppLocalizations(Locale(language));
        await wait(find.text(l.executionDropSet));
        await mark(large ? 'FONT:accessibility-large' : 'FONT:large');
        await tap(find.byKey(const ValueKey('entry-count')));
        await next();
        await mark('SHOT:08-$language-$theme');
        await tap(find.byKey(const ValueKey('execution-controls')));
        await mark('SHOT:08b-controls-$language-$theme');
        await tap(find.text(l.executionContinueRecord));
      }
      await mark('FONT:large');
      await tap(
        find.byTooltip(
          MaterialLocalizations.of(
            tester.element(find.byType(ExecutionEntryPanel)),
          ).backButtonTooltip,
        ),
      );
      await tap(find.text(l.tabProfile));
      await mark('FONT:accessibility-large');
      await mark('SHOT:09-profile-kk-large');
      await mark('FONT:large');
      await auth.signOut();
    },
  );
}
