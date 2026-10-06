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
import 'package:progressbar_app/features/workout/workout_screen.dart';
import 'package:progressbar_app/firebase_options.dart';
import 'package:progressbar_app/l10n/app_localizations.dart';
import 'package:progressbar_app/widgets/glass_panel.dart';

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
      if (index == 0) await mark('SHOT:05-plan');
      await tap(find.widgetWithText(FilledButton, l10n.welcomeDone));
    }
    await mark('SHOT:06-builder');
    await tap(find.widgetWithText(FilledButton, l10n.builderStart));

    await wait(find.byType(WorkoutScreen));
    await wait(find.text(l10n.entryRecord));
    await mark('SHOT:07-workout');
    await mark('FONT:accessibility-large');
    await mark('SHOT:08-workout-large-font');
    await mark('FONT:large');

    await tap(find.byTooltip(l10n.entryIncrease(l10n.entryWeight)));
    await tap(find.widgetWithText(FilledButton, l10n.entryRecord));
    await tap(find.text(l10n.entryEachSet));
    await wait(find.text(l10n.entryRecordSet(1)));
    await tap(find.text(l10n.effortSome));
    await mark('SHOT:09-per-set');
    await tap(find.text(l10n.entryRecordSet(1)));
    await tap(find.text(l10n.entrySummaryOnly));
    await tap(find.widgetWithText(FilledButton, l10n.entryRecord));
    await wait(find.text(l10n.workoutAllRecorded));
    await mark('SHOT:10-all-recorded');
    await tap(find.widgetWithText(FilledButton, l10n.workoutFinish));
    await wait(find.text(l10n.finishTitle));
    await mark('SHOT:11-finish');
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

    // Everything reached the server.
    await db.waitForPendingWrites();
    final uid = auth.currentUser!.uid;
    const server = GetOptions(source: Source.server);
    final workouts = await db.collection('users/$uid/workouts').get(server);
    expect(workouts.docs.single.data()['status'], 'completed');
    expect(workouts.docs.single.data()['programName'], 'Сила');
    final programs = await db.collection('users/$uid/programs').get(server);
    expect(programs.docs.single.data()['name'], 'Сила');
    final pointer = await db.doc('users/$uid/state/activeWorkout').get(server);
    expect(pointer.data()?['workoutId'], isNull);
    final profile = await db.doc('users/$uid').get(server);
    expect(profile.data()?['name'], 'Арман');
  });
}
