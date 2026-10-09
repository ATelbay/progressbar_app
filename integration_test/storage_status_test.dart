// Native Firestore metadata and a real server refusal, against local
// emulators only. Run with the screenshot helpers used by the main pass.
import 'dart:async';

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
import 'package:progressbar_app/data/workout_repository.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/domain/workout_logic.dart';
import 'package:progressbar_app/features/home/home_screen.dart';
import 'package:progressbar_app/features/exercises/personal_exercises_provider.dart';
import 'package:progressbar_app/features/program/program_providers.dart';
import 'package:progressbar_app/features/workout/workout_providers.dart';
import 'package:progressbar_app/features/workout/workout_screen.dart';
import 'package:progressbar_app/firebase_options.dart';
import 'package:progressbar_app/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'offline results, acknowledgements and server refusals are visible',
    (tester) async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final db = FirebaseFirestore.instance
        ..useFirestoreEmulator('localhost', 8080);
      final auth = FirebaseAuth.instance;
      await auth.useAuthEmulator('localhost', 9099);
      await auth.signOut();
      final uid = (await auth.signInAnonymously()).user!.uid;
      final profiles = FirestoreProfileRepository(db);
      final profile = UserProfile(
        id: uid,
        name: 'Проверка сети',
        phone: '+77010000010',
        bodyWeightKg: 75,
        languageCode: 'ru',
        theme: ThemeChoice.dark,
      );
      await profiles.save(profile);
      final catalog = await AssetExerciseCatalogRepository(rootBundle).load();
      final exercises = catalog.values
          .where((e) => e.measure == Measure.reps && !e.usesBodyWeight)
          .take(2)
          .toList();
      final day = ProgramDay(
        id: 'd1',
        name: 'Проверка сети',
        exercises: [
          for (final (index, exercise) in exercises.indexed)
            ProgramExercise(
              id: 'pe$index',
              exerciseId: exercise.id,
              sets: const [SetValues(reps: 10, weightKg: 20)],
            ),
        ],
      );
      final workout = startWorkout(
        id: 'sync-test',
        traineeId: uid,
        now: DateTime.now(),
        newId: () => db.collection('ids').doc().id,
        catalog: catalog,
        languageCode: 'ru',
        bodyWeightKg: 75,
        program: Program(
          id: 'p1',
          authorId: uid,
          name: 'Синхронизация',
          days: [day],
        ),
        day: day,
      );
      final seed = FirestoreWorkoutRepository(db);
      await seed.start(workout);
      await db.waitForPendingWrites();

      Future<void> wait(Finder finder) async {
        for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(finder, findsWidgets);
      }

      Future<void> gone(Finder finder) async {
        for (var i = 0; i < 100 && finder.evaluate().isNotEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(finder, findsNothing);
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

      await tester.pumpWidget(const ProviderScope(child: ProgressBarApp()));
      await wait(find.byType(HomeScreen));
      final l10n = AppLocalizations.of(
        tester.element(find.byType(HomeScreen)),
      )!;
      await tap(find.text(l10n.homeContinue));
      await wait(find.byType(WorkoutScreen));
      await gone(find.text(l10n.workoutLocalReady));
      await db.disableNetwork();
      await wait(find.text(l10n.workoutLocalReady));
      await mark('SHOT:01-offline-dark');

      await tap(find.widgetWithText(FilledButton, l10n.entryContinue));
      await tap(find.widgetWithText(FilledButton, l10n.entryContinue));
      await tap(find.widgetWithText(FilledButton, l10n.entryRecord));
      await wait(find.text(l10n.workoutNotSent));
      await wait(find.text(l10n.workoutLocalSaved));
      await tester.ensureVisible(find.text(l10n.workoutLocalSaved));
      await mark('SHOT:02-pending-dark');

      // Profile writes also stay local while disconnected; do not await the
      // server. This switches the real app theme to inspect the same state.
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
      await mark('SHOT:03-pending-light');
      await mark('FONT:accessibility-large');
      await tap(find.widgetWithText(FilledButton, l10n.entryContinue));
      await tap(find.widgetWithText(FilledButton, l10n.entryContinue));
      final record = find.widgetWithText(FilledButton, l10n.entryRecord);
      await tester.ensureVisible(record);
      await tester.pump(const Duration(milliseconds: 300));
      expect(record.hitTestable(), findsOneWidget);
      await mark('SHOT:04-offline-large-record');
      await mark('FONT:large');

      await db.enableNetwork();
      await db.waitForPendingWrites();
      await gone(find.text(l10n.workoutNotSent));
      await gone(find.text(l10n.workoutLocalSaved));
      await mark('SHOT:05-synced');
      final container = ProviderScope.containerOf(
        tester.element(find.byType(WorkoutScreen)),
      );
      final repo = container.read(workoutRepositoryProvider);
      final saved = (await repo.watchActive(uid).first)!;
      expect(
        saved.exercises.first.sets.single.fact,
        const SetValues(reps: 10, weightKg: 20),
      );

      // The existing rules refuse changing a workout's supervisor. Submit an
      // invalid edit through the actual repository to exercise onRejected and
      // rollback, rather than substituting either the repository or the server.
      final invalid = recordSummary(
        Workout(
          id: saved.id,
          traineeId: uid,
          status: saved.status,
          startedAt: saved.startedAt,
          exercises: saved.exercises,
          supervisorCoachId: 'not-an-active-coach',
        ),
        saved.exercises.first.id,
        setCount: 1,
        fact: const SetValues(reps: 10, weightKg: 99),
        newId: () => db.collection('ids').doc().id,
        now: DateTime.now(),
      );
      await repo.save(invalid);
      await wait(find.text(l10n.saveWorkoutRejected));
      await mark('SHOT:06-server-refused');
      // The warning survives leaving the workout, and awaits acknowledgement.
      await tester.binding.handlePopRoute();
      await wait(find.byType(HomeScreen));
      expect(find.text(l10n.saveWorkoutRejected), findsOneWidget);
      await mark('SHOT:07-refusal-on-home');
      await tap(
        find.text(
          MaterialLocalizations.of(tester.element(find.byType(HomeScreen)))
              .okButtonLabel,
        ),
      );
      await gone(find.text(l10n.saveWorkoutRejected));
      final server = await db
          .doc('users/$uid/workouts/${saved.id}')
          .get(const GetOptions(source: Source.server));
      expect(server.data()?['supervisorCoachId'], isNull);
      expect(server.data()?['exercises'][0]['sets'][0]['fact']['weightKg'], 20);

      // Exercise the other repository callbacks as well. Writes to a different
      // owner are rejected by the same local rules, without changing them.
      await container
          .read(programRepositoryProvider)
          .save(
            Program(
              id: 'refused-program',
              authorId: 'not-this-user',
              name: 'Не сохранять',
              days: [day],
            ),
          );
      await wait(find.text(l10n.saveProgramRejected));
      await mark('SHOT:08-program-refused-light');
      await tap(
        find.text(
          MaterialLocalizations.of(tester.element(find.byType(HomeScreen)))
              .okButtonLabel,
        ),
      );
      await gone(find.text(l10n.saveProgramRejected));

      await profiles.save(profile);
      for (
        var i = 0;
        i < 100 &&
            Theme.of(tester.element(find.byType(HomeScreen))).brightness !=
                Brightness.dark;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(
        Theme.of(tester.element(find.byType(HomeScreen))).brightness,
        Brightness.dark,
      );
      await container
          .read(personalExerciseRepositoryProvider)
          .save(
            const Exercise(
              id: 'custom/refused-exercise',
              names: {'ru': 'Не сохранять'},
              muscleGroup: 'chest',
              ownerId: 'not-this-user',
            ),
          );
      await wait(find.text(l10n.saveExerciseRejected));
      await mark('SHOT:09-exercise-refused-dark');
      await tap(
        find.text(
          MaterialLocalizations.of(tester.element(find.byType(HomeScreen)))
              .okButtonLabel,
        ),
      );
      await gone(find.text(l10n.saveExerciseRejected));
    },
  );
}
