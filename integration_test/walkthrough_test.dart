// Walks through the whole app on a device against the local Firebase
// emulators (never production): sign-in by phone, a program, a workout,
// history, progress, profile. Prints «SHOT:<name>» where a screenshot of the
// device is worth taking and «FONT:<size>» where the host should change the
// system text size; see tool/walkthrough.sh.
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:progressbar_app/app.dart';
import 'package:progressbar_app/features/auth/code_screen.dart';
import 'package:progressbar_app/features/auth/profile_setup_screen.dart';
import 'package:progressbar_app/features/auth/sign_in_screen.dart';
import 'package:progressbar_app/features/exercises/exercise_picker_screen.dart';
import 'package:progressbar_app/features/program/program_builder_screen.dart';
import 'package:progressbar_app/features/profile/profile_screen.dart';
import 'package:progressbar_app/features/workout/number_keypad.dart';
import 'package:progressbar_app/features/workout/workout_day_button.dart';
import 'package:progressbar_app/features/workout/workout_screen.dart';
import 'package:progressbar_app/firebase_options.dart';
import 'package:progressbar_app/l10n/app_localizations.dart';
import 'package:progressbar_app/widgets/glass_panel.dart';
import 'package:progressbar_app/widgets/step_button.dart';

const phone = '+77010000001';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the app works end to end on a device', (tester) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Before anything else touches Firebase: from here on only the emulators.
    final db = FirebaseFirestore.instance
      ..useFirestoreEmulator('localhost', 8080);
    final auth = FirebaseAuth.instance;
    await auth.useAuthEmulator('localhost', 9099);
    await auth.signOut();

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
    }

    Future<void> tap(Finder finder) async {
      await wait(finder);
      await tester.ensureVisible(finder.first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(finder.first);
      await tester.pump(const Duration(milliseconds: 600));
    }

    Future<void> pickDay(DateTime day, String shot) async {
      await tap(
        find.descendant(
          of: find.byType(WorkoutDayButton),
          matching: find.byIcon(Icons.calendar_today_outlined),
        ),
      );
      await wait(find.byType(DatePickerDialog));
      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(picker.lastDate, DateUtils.dateOnly(DateTime.now()));
      await mark('SHOT:$shot');
      final material = MaterialLocalizations.of(
        tester.element(find.byType(DatePickerDialog)),
      );
      await tap(find.byTooltip(material.inputDateModeButtonLabel));
      await tester.enterText(
        find.byType(TextField).last,
        material.formatCompactDate(day),
      );
      await tap(find.text(material.okButtonLabel));
      expect(find.byType(DatePickerDialog), findsNothing);
    }

    final today = DateUtils.dateOnly(DateTime.now());
    final workoutDay = DateTime(today.year, today.month, today.day - 1);
    final editedDay = DateTime(today.year, today.month, today.day - 2);
    String storedDay(DateTime day) =>
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

    await tester.pumpWidget(const ProviderScope(child: ProgressBarApp()));
    await wait(find.byType(SignInScreen));
    await mark('SHOT:01-sign-in');
    final l10n = AppLocalizations.of(
      tester.element(find.byType(SignInScreen)),
    )!;

    await tester.enterText(find.byType(TextField), phone);
    await tap(find.byType(FilledButton));
    await wait(find.byType(CodeScreen));
    // The emulator keeps the code it would have sent by SMS.
    final request = await HttpClient().getUrl(
      Uri.parse(
        'http://localhost:9099/emulator/v1/projects/progressbar-app/verificationCodes',
      ),
    );
    final body = await (await request.close()).transform(utf8.decoder).join();
    final codes = (jsonDecode(body)['verificationCodes'] as List)
        .where((c) => c['phoneNumber'] == phone)
        .toList();
    await tester.enterText(
      find.byType(TextField),
      codes.last['code'] as String,
    );

    await wait(find.byType(ProfileSetupScreen));
    await tester.enterText(find.byType(TextField), 'Арман');
    await mark('SHOT:02-welcome');
    await tap(find.byType(FilledButton));
    await wait(find.text(l10n.homeEmptyTitle));
    await mark('SHOT:03-home-empty');

    // A program with two exercises.
    await tap(find.text(l10n.homeNewProgram));
    await tester.enterText(find.byType(TextField), 'Сила');
    await tester.pump(const Duration(milliseconds: 400));
    for (final index in [0, 4]) {
      await tap(find.widgetWithText(OutlinedButton, l10n.pickerTitle));
      await wait(find.byType(ExercisePickerScreen));
      await wait(find.byType(GlassCard));
      if (index == 0) await mark('SHOT:04-picker');
      await tap(find.byType(GlassCard).at(index));
      await wait(find.text(l10n.entrySets));
      // First sets and reps, then the weight on the same keypad.
      await tap(find.widgetWithText(FilledButton, l10n.entryContinue));
      await tap(find.widgetWithText(FilledButton, l10n.entryContinue));
      await tap(find.widgetWithText(PbPill, '6'));
      await tap(find.widgetWithText(PbPill, '0'));
      if (index == 0) await mark('SHOT:05-plan-keypad');
      await tap(find.widgetWithText(FilledButton, l10n.welcomeDone));
      expect(find.byType(NumberKeypad), findsNothing);
      if (index == 0) {
        await tap(find.byType(GlassCard).first);
        await wait(find.text(l10n.builderNote));
        await tap(find.text('+0.5'));
        await tap(find.text('−0.5'));
        await mark('SHOT:05b-plan');
        await tap(find.widgetWithText(FilledButton, l10n.welcomeDone));
      }
    }
    await mark('SHOT:06-builder');
    await tap(find.widgetWithText(FilledButton, l10n.builderStart));

    await wait(find.byType(WorkoutScreen));
    await wait(find.text(l10n.entryContinue));
    await mark('SHOT:07-workout');
    await mark('FONT:accessibility-large');
    await mark('SHOT:08-workout-large-font');
    await tap(find.widgetWithText(FilledButton, l10n.entryContinue));
    await tap(find.widgetWithText(FilledButton, l10n.entryContinue));
    final record = find.widgetWithText(FilledButton, l10n.entryRecord);
    await tester.ensureVisible(record);
    await tester.pump(const Duration(milliseconds: 300));
    expect(record.hitTestable(), findsOneWidget);
    await mark('SHOT:08b-workout-large-record');
    await mark('FONT:large');

    for (final key in ['6', '2', ',', '5']) {
      await tap(find.widgetWithText(PbPill, key));
    }
    await tap(find.widgetWithText(FilledButton, l10n.entryRecord));
    await tap(find.text(l10n.entryEachSet));
    await wait(find.text(l10n.entryRecordSet(1)));
    await tap(find.text(l10n.effortSome));
    await mark('SHOT:09-per-set');
    await tap(find.text(l10n.entryRecordSet(1)));
    await tap(find.text(l10n.entrySummaryOnly));
    await tap(find.widgetWithText(FilledButton, l10n.entryContinue));
    await tap(find.widgetWithText(FilledButton, l10n.entryContinue));
    await tap(find.widgetWithText(FilledButton, l10n.entryRecord));
    await wait(find.text(l10n.workoutAllRecorded));
    await mark('SHOT:10-all-recorded');
    await tap(find.widgetWithText(FilledButton, l10n.workoutFinish));
    await wait(find.text(l10n.finishTitle));
    await mark('SHOT:11-finish');
    expect(find.text(l10n.finishCancel), findsNothing);
    await pickDay(workoutDay, '11b-finish-calendar');
    await mark('SHOT:11c-finish-backdated');
    await tap(find.widgetWithText(FilledButton, l10n.workoutFinish).last);

    await wait(find.text(l10n.homeMyPrograms));
    await mark('SHOT:12-home');
    await tap(find.text(l10n.tabHistory));
    await wait(find.text('Сила'));
    await mark('SHOT:13-history');
    await tap(find.text(l10n.tabProgress));
    await mark('SHOT:14-progress');
    await tap(find.text(l10n.tabProfile));
    await wait(find.text(l10n.profileCatalog));
    await mark('SHOT:15-profile');

    await tap(find.text(l10n.profileTheme));
    await mark('SHOT:16-theme-choice');
    await tap(find.text(l10n.themeLight));
    expect(
      Theme.of(tester.element(find.text(l10n.profileTheme))).brightness,
      Brightness.light,
    );
    await mark('SHOT:17-profile-light');
    await tap(find.text(l10n.profileTheme));
    await tap(find.text(l10n.themeDark));
    expect(
      Theme.of(tester.element(find.text(l10n.profileTheme))).brightness,
      Brightness.dark,
    );
    await mark('SHOT:18-profile-dark');

    // Check the settings with real Russian and Kazakh fonts, including the
    // longest values at the larger system text size.
    for (final (language, code) in [('Русский', 'ru'), ('Қазақша', 'kk')]) {
      final current = AppLocalizations.of(
        tester.element(find.byType(ProfileScreen)),
      )!;
      await tap(find.text(current.profileLanguage));
      await tap(find.text(language));
      await mark('FONT:accessibility-large');
      await mark('SHOT:19-profile-$code-large');
      final translated = AppLocalizations.of(
        tester.element(find.byType(ProfileScreen)),
      )!;
      await tester.ensureVisible(find.text(translated.profileEntryMode));
      await mark('SHOT:19b-profile-$code-settings-large');
      await mark('FONT:large');
    }
    final current = AppLocalizations.of(
      tester.element(find.byType(ProfileScreen)),
    )!;
    await tap(find.text(current.profileLanguage));
    await tap(find.text('English'));

    // Planning another occurrence starts with the author's actual last
    // weight, including the step up recorded during the workout.
    await tap(find.text(l10n.tabHome));
    await tap(find.text('Сила'));
    await tap(find.widgetWithText(OutlinedButton, l10n.pickerTitle));
    await wait(find.byType(ExercisePickerScreen));
    await wait(find.byType(GlassCard));
    await tap(find.byType(GlassCard).first);
    await wait(find.text(l10n.builderNote));
    expect(find.textContaining('Last time:'), findsOneWidget);
    expect(find.text('62.5 kg', findRichText: true), findsOneWidget);
    expect(find.byType(NumberKeypad), findsNothing);
    await mark('SHOT:20-plan-last-weight');
    await tap(find.widgetWithText(FilledButton, l10n.welcomeDone));
    await tap(
      find.byTooltip(
        MaterialLocalizations.of(
          tester.element(find.byType(ProgramBuilderScreen)),
        ).backButtonTooltip,
      ),
    );

    // Everything reached the server.
    await db.waitForPendingWrites();
    final uid = auth.currentUser!.uid;
    const server = GetOptions(source: Source.server);
    final workouts = await db.collection('users/$uid/workouts').get(server);
    expect(workouts.docs.single.data()['status'], 'completed');
    expect(workouts.docs.single.data()['programName'], 'Сила');
    expect(workouts.docs.single.data()['performedOn'], storedDay(workoutDay));
    final programs = await db.collection('users/$uid/programs').get(server);
    expect(programs.docs.single.data()['name'], 'Сила');
    final pointer = await db.doc('users/$uid/state/activeWorkout').get(server);
    expect(pointer.data()?['workoutId'], isNull);
    final profile = await db.doc('users/$uid').get(server);
    expect(profile.data()?['name'], 'Арман');
    expect(profile.data()?['theme'], 'dark');

    // Editing the day leaves the completion time intact. Keeping the workout
    // in the confirmation dialog must leave history and progress intact too.
    await tap(find.text(l10n.tabHistory));
    await tap(find.byTooltip(l10n.historyEdit));
    await mark('SHOT:21-workout-edit');
    await pickDay(editedDay, '21b-edit-calendar');
    await tap(find.text(l10n.editSave));
    await wait(find.text(l10n.historyEdited));
    await db.waitForPendingWrites();
    final edited = await workouts.docs.single.reference.get(server);
    expect(edited.data()?['performedOn'], storedDay(editedDay));
    expect(
      edited.data()?['completedAt'],
      workouts.docs.single.data()['completedAt'],
    );

    await tap(find.byTooltip(l10n.historyEdit));
    await tap(find.text(l10n.editDelete));
    await mark('SHOT:22-delete-confirm');
    await tap(find.text(l10n.builderKeep));
    expect(
      (await db.collection('users/$uid/workouts').get(server)).docs,
      hasLength(1),
    );
    await tap(find.text(l10n.editDelete));
    await tap(find.text(l10n.builderDelete));
    await wait(find.text(l10n.historyEmptyTitle));
    await mark('SHOT:23-history-deleted');
    await db.waitForPendingWrites();
    expect(
      (await db.collection('users/$uid/workouts').get(server)).docs,
      isEmpty,
    );
    expect(
      (await db.doc('users/$uid/state/activeWorkout').get(server))
          .data()?['workoutId'],
      isNull,
    );
    await tap(find.text(l10n.tabProgress));
    await wait(find.text(l10n.progressEmptyTitle));
    await mark('SHOT:24-progress-deleted');
  });
}
