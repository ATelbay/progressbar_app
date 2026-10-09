// Stable exercise slots and summary entry beyond the plan, local Firebase only.
import 'dart:async';
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
import 'package:progressbar_app/data/firestore_codec.dart';
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
import 'package:progressbar_app/widgets/glass_panel.dart';
import 'package:progressbar_app/widgets/step_button.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'selection stays in order and an extra summary is visibly recorded',
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
                  sets: const [
                    SetValues(reps: 8, weightKg: 20),
                    SetValues(reps: 8, weightKg: 20),
                  ],
                ),
            ],
          ),
        ],
      );
      await FirestoreProgramRepository(db).save(program);
      final workouts = FirestoreWorkoutRepository(db);
      final workout = startWorkout(
        id: 'order-workout',
        traineeId: uid,
        now: DateTime.now(),
        newId: () => db.collection('ids').doc().id,
        catalog: catalog,
        languageCode: 'ru',
        program: program,
        day: program.days.single,
      );
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

      Future<void> select(String id) =>
          tap(find.descendant(of: slot(id), matching: find.byType(GlassCard)));
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
      final home = AppLocalizations.of(
        tester.element(find.byType(HomeScreen)),
      )!;
      await tap(find.text(home.homeContinue));
      await wait(find.byType(EntryPanel));
      await select(ids[2]);
      expectOrder();
      await mark('SHOT:01-selected-third');
      await tap(find.text(l().entryEachSet));
      await select(ids[1]);
      expectOrder();
      await tap(find.text(l().entryRecordSet(1)));
      expectOrder();
      await wait(find.text(l().entryRecordSet(2)));
      await mark('SHOT:02-per-set-middle');
      await tap(find.text(l().entrySummaryOnly));
      await record(sets: '2');
      await record();
      await record();
      await wait(find.text(l().workoutAllRecorded));
      expect(find.byType(EntryPanel), findsNothing);

      await db.waitForPendingWrites();
      await db.disableNetwork();
      // Add the same catalog exercise again: workout IDs must distinguish them.
      await tap(find.text(l().workoutAddExercise));
      await tester.enterText(
        find.byType(TextField),
        exercises.first.nameFor('ru'),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tap(find.text(exercises.first.nameFor('ru')).last);
      await wait(find.text(l().workoutOutsidePlan));
      final added =
          (await workouts
                  .watchActive(uid)
                  .firstWhere((w) => w?.exercises.length == 4))!
              .exercises
              .last;
      ids.add(added.id);
      expect(
        tester.widget<EntryPanel>(find.byType(EntryPanel)).exercise.id,
        added.id,
      );
      expectOrder();
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        find.widgetWithText(FilledButton, l().entryContinue).hitTestable(),
        findsOneWidget,
      );
      await mark('SHOT:03-extra-before');
      await type('3');
      await tap(find.widgetWithText(FilledButton, l().entryContinue));
      await type('10');
      await tap(find.widgetWithText(FilledButton, l().entryContinue));
      final before = (await doc.get(const GetOptions(source: Source.cache)))
          .data()!;
      expect(before['exercises'][3]['sets'], isEmpty);
      await type('7,5');
      await tap(find.widgetWithText(FilledButton, l().entryRecord));
      await wait(find.text(l().workoutAllRecorded));
      expect(find.byType(EntryPanel), findsNothing);
      expectOrder();
      await wait(find.text(l().workoutNotSent));

      Future<void> inspectExtra(String name) async {
        final card = slot(added.id);
        await tester.ensureVisible(card);
        await tester.pump(const Duration(milliseconds: 300));
        for (final label in [
          l().workoutOutsidePlan,
          l().workoutExerciseRecorded,
        ]) {
          expect(
            find.descendant(of: card, matching: find.text(label)).hitTestable(),
            findsOneWidget,
          );
        }
        expectOrder();
        await mark('SHOT:$name');
      }

      await inspectExtra('04-extra-offline-dark');
      unawaited(profiles.save(profile.copyWith(theme: ThemeChoice.light)));
      for (
        var i = 0;
        i < 100 &&
            Theme.of(tester.element(find.byType(WorkoutScreen))).brightness !=
                Brightness.light;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(
        Theme.of(tester.element(find.byType(WorkoutScreen))).brightness,
        Brightness.light,
      );
      await inspectExtra('05-extra-offline-light');
      await mark('FONT:accessibility-large');
      await inspectExtra('06-extra-ru-large');
      unawaited(
        profiles.save(
          profile.copyWith(languageCode: () => 'kk', theme: ThemeChoice.dark),
        ),
      );
      await wait(
        find.text(
          lookupAppLocalizations(const Locale('kk')).workoutOutsidePlan,
        ),
      );
      await inspectExtra('07-extra-kk-large');
      await mark('FONT:large');

      await db.enableNetwork();
      await db.waitForPendingWrites();
      for (
        var i = 0;
        i < 100 && find.text(l().workoutNotSent).evaluate().isNotEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.text(l().workoutNotSent), findsNothing);
      final saved = (await doc.get(const GetOptions(source: Source.server)))
          .data()!;
      expect((saved['exercises'][3]['sets'] as List).length, 3);
      expect(
        (saved['exercises'][3]['sets'] as List).map(
          (s) => s['fact']['weightKg'],
        ),
        everyElement(7.5),
      );
      expect(
        (saved['exercises'][3]['sets'] as List).map((s) => s['plan']),
        everyElement(isNull),
      );

      await select(added.id);
      expectOrder();
      await record(sets: '2', count: '12', weight: '5');
      await wait(find.text(l().workoutAllRecorded));
      await db.waitForPendingWrites();
      final corrected = (await doc.get(const GetOptions(source: Source.server)))
          .data()!;
      expect((corrected['exercises'][3]['sets'] as List).length, 2);
      expect(corrected['exercises'][3]['sets'][0]['fact']['reps'], 12);
      expect(corrected['exercises'][3]['sets'][0]['fact']['weightKg'], 5);
      expect(
        corrected['exercises'].take(3).toList(),
        saved['exercises'].take(3).toList(),
      );
      final storedProgram =
          (await db
                  .doc('users/$uid/programs/${program.id}')
                  .get(const GetOptions(source: Source.server)))
              .data()!;
      expect(storedProgram['days'], programToMap(program)['days']);
      await inspectExtra('08-extra-corrected');
    },
  );
}
