// Stable exercise slots and summary entry beyond the plan, local Firebase only.
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
import 'package:progressbar_app/data/program_repository.dart';
import 'package:progressbar_app/data/workout_repository.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/domain/workout_logic.dart';
import 'package:progressbar_app/features/home/home_screen.dart';
import 'package:progressbar_app/features/workout/entry_panel.dart';
import 'package:progressbar_app/features/workout/workout_screen.dart';
import 'package:progressbar_app/firebase_options.dart';
import 'package:progressbar_app/l10n/app_localizations.dart';
import 'package:progressbar_app/widgets/step_button.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'estimated plan comparison survives native entry and history correction',
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
        name: 'Проверка порядка',
        phone: '+77010000012',
        languageCode: 'ru',
        theme: ThemeChoice.dark,
      );
      await profiles.save(profile);
      final catalog = await AssetExerciseCatalogRepository(rootBundle).load();
      final exercises = catalog.values
          .where((e) => e.measure == Measure.reps && !e.usesBodyWeight)
          .take(3)
          .toList();
      final program = Program(
        id: 'order-program',
        authorId: uid,
        name: 'Проверка порядка',
        days: [
          ProgramDay(
            id: 'day',
            name: 'День 1',
            exercises: [
              for (final (i, exercise) in exercises.indexed)
                ProgramExercise(
                  id: 'pe$i',
                  exerciseId: exercise.id,
                  sets: const [SetValues(reps: 12, weightKg: 60)],
                ),
            ],
          ),
        ],
      );
      await FirestoreProgramRepository(db).save(program);
      final workouts = FirestoreWorkoutRepository(db);
      var workout = startWorkout(
        bodyWeightKg: 80,
        id: 'order-workout',
        traineeId: uid,
        now: DateTime.now(),
        newId: () => db.collection('ids').doc().id,
        catalog: catalog,
        languageCode: 'ru',
        program: program,
        day: program.days.single,
      );
      workout = moveExerciseGroup(workout, 2, 0, now: DateTime.now());
      await workouts.start(workout);
      await db.waitForPendingWrites();
      final doc = db.doc('users/$uid/workouts/${workout.id}');
      final ids = workout.exercises.map((e) => e.id).toList();

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

      Future<void> mark(String line) async {
        // ignore: avoid_print
        print(line);
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(tester.takeException(), isNull);
      }

      AppLocalizations l() =>
          AppLocalizations.of(tester.element(find.byType(WorkoutScreen)))!;
      Finder slot(String id) => find.byKey(ValueKey('workout-exercise-$id'));
      void expectOrder() {
        final positions = [
          for (final id in ids) tester.getTopLeft(slot(id)).dy,
        ];
        expect(positions, orderedEquals([...positions]..sort()));
      }

      Future<void> type(String value) async {
        for (final key in value.split('')) {
          await tap(find.widgetWithText(PbPill, key));
        }
      }

      Future<void> record({String? sets, String? count, String? weight}) async {
        if (sets != null) await type(sets);
        await tap(find.widgetWithText(FilledButton, l().entryContinue));
        if (count != null) await type(count);
        await tap(find.widgetWithText(FilledButton, l().entryContinue));
        if (weight != null) await type(weight);
        await tap(find.widgetWithText(FilledButton, l().entryRecord));
        expectOrder();
      }

      await tester.pumpWidget(const ProviderScope(child: ProgressBarApp()));
      await wait(find.byType(HomeScreen));
      await tap(
        find.text(
          AppLocalizations.of(tester.element(find.byType(HomeScreen)))!
              .homeContinue,
        ),
      );
      await wait(find.byType(EntryPanel));
      await record(sets: '1', count: '10', weight: '80');
      expect(find.text(l().chipAbovePlan), findsWidgets);
      await tap(find.text(l().entryModePerSet));
      // The native step controls and weight keypad, not direct callbacks.
      for (var i = 0; i < 9; i++) {
        await tap(find.byTooltip(l().entryDecrease(l().entryReps)));
      }
      await tap(find.text('60 кг', findRichText: true).last);
      for (final key in ['8', '0']) {
        await tap(find.widgetWithText(TextButton, key));
      }
      await tap(find.text(l().welcomeDone));
      await tap(find.text(l().entryRecordSet(1)));
      await mark('SHOT:01-per-set-above');
      await tap(find.widgetWithText(TextButton, l().workoutFinish));
      await mark('SHOT:02-finish-mixed');
      await tap(find.widgetWithText(FilledButton, l().workoutFinish).last);
      await wait(find.byType(HomeScreen));
      final text = AppLocalizations.of(
        tester.element(find.byType(HomeScreen)),
      )!;
      await tap(find.text(text.tabHistory));
      await wait(find.text(text.chipAbovePlan));
      expect(find.text('≈ 106,5 кг против ≈ 84 кг'), findsOneWidget);
      expect(find.text('≈ 88 кг против ≈ 84 кг'), findsOneWidget);
      await tap(find.text(text.workoutOrderChanged));
      await mark('SHOT:03-history-comparison');
      await tap(find.byTooltip(text.historyEdit));
      await tap(
        find.byTooltip(text.historyEditExercise(workout.exercises.first.name)),
      );
      await wait(find.text(text.entryContinue));
      await type('1');
      await tap(find.widgetWithText(FilledButton, text.entryContinue));
      await type('6');
      await tap(find.widgetWithText(FilledButton, text.entryContinue));
      await type('60');
      await tap(find.widgetWithText(FilledButton, text.entryRecord));
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await tap(find.byIcon(Icons.calendar_today_outlined));
      await wait(find.byType(DatePickerDialog));
      await tap(find.text('${yesterday.day}').last);
      await tap(
        find.text(
          MaterialLocalizations.of(
            tester.element(find.byType(DatePickerDialog)),
          ).okButtonLabel,
        ),
      );
      await tap(find.text(text.editSave));
      await db.waitForPendingWrites();
      await mark('SHOT:04-history-edited');
      final saved = (await doc.get(const GetOptions(source: Source.server)))
          .data()!;
      expect(saved['schemaVersion'], 2);
      expect(saved['exercises'][0]['sets'][0]['plan']['reps'], 12);
      expect(saved['exercises'][0]['sets'][0]['plan']['weightKg'], 60);
      expect(saved['exercises'][0]['sets'][0]['fact']['reps'], 6);
      expect(saved['exercises'][0]['sets'][0]['fact']['weightKg'], 60);
      expect(saved['bodyWeightKg'], 80);
      expect(saved['originalOrder'], workout.originalOrder);
      expect(saved['exercises'].map((e) => e['id']), ids);
      expect(saved['performedOn'], isNotNull);
      await auth.signOut();
    },
  );
}
