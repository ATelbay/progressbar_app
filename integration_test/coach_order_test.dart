// Two real local Auth accounts. A link is created only by accepting an invitation.
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
import 'package:progressbar_app/data/link_repository.dart';
import 'package:progressbar_app/data/profile_repository.dart';
import 'package:progressbar_app/data/workout_repository.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/domain/workout_logic.dart';
import 'package:progressbar_app/features/home/home_screen.dart';
import 'package:progressbar_app/features/people/trainee_screen.dart';
import 'package:progressbar_app/firebase_options.dart';
import 'package:progressbar_app/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'coach reads original order in active, completed, mine, all and read-only workouts',
    (tester) async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
      final db = FirebaseFirestore.instance..useFirestoreEmulator(host, 8080);
      final auth = FirebaseAuth.instance;
      await auth.useAuthEmulator(host, 9099);
      await auth.signOut();
      final suffix = DateTime.now().microsecondsSinceEpoch;
      final coachEmail = 'coach-$suffix@example.invalid',
          traineeEmail = 'trainee-$suffix@example.invalid';
      const password = 'local-emulator-only-20261116';
      final profiles = FirestoreProfileRepository(db),
          links = FirestoreLinkRepository(db),
          workouts = FirestoreWorkoutRepository(db);
      final coach = (await auth.createUserWithEmailAndPassword(
        email: coachEmail,
        password: password,
      )).user!.uid;
      final coachProfile = UserProfile(
        id: coach,
        name: 'Сергей',
        phone: '+77010000111',
        languageCode: 'ru',
        theme: ThemeChoice.dark,
      );
      await profiles.save(coachProfile);
      final invitation = await links.createInvitation(
        inviterId: coach,
        inviterName: 'Сергей',
        role: LinkRole.coach,
      );
      await auth.signOut();
      final trainee = (await auth.createUserWithEmailAndPassword(
        email: traineeEmail,
        password: password,
      )).user!.uid;
      await profiles.save(
        UserProfile(
          id: trainee,
          name: 'Айгерим',
          phone: '+77010000112',
          languageCode: 'ru',
          bodyWeightKg: 80,
        ),
      );
      final link = await links.accept(
        (await links.findInvitation(invitation.code))!,
        acceptorId: trainee,
        acceptorName: 'Айгерим',
      );
      final catalog = await AssetExerciseCatalogRepository(rootBundle).load();
      final exercises = catalog.values
          .where((e) => e.measure == Measure.reps && !e.usesBodyWeight)
          .take(3)
          .toList();
      final program = Program(
        id: 'p',
        authorId: trainee,
        name: 'Сила',
        days: [
          ProgramDay(
            id: 'd',
            name: 'Грудь и трицепс',
            exercises: [
              for (final (i, e) in exercises.indexed)
                ProgramExercise(
                  id: 'pe$i',
                  exerciseId: e.id,
                  sets: const [SetValues(reps: 12, weightKg: 60)],
                ),
            ],
          ),
        ],
      );
      Workout start(String id) => startWorkout(
        id: id,
        traineeId: trainee,
        now: DateTime.now(),
        newId: () => db.collection('ids').doc().id,
        catalog: catalog,
        languageCode: 'ru',
        program: program,
        day: program.days.single,
        supervisorCoachId: coach,
        supervisorCoachName: 'Сергей',
        bodyWeightKg: 80,
      );
      var completed = start('completed');
      await workouts.start(completed);
      completed = moveExerciseGroup(completed, 2, 0, now: DateTime.now());
      completed = recordSummary(
        completed,
        completed.exercises[1].id,
        setCount: 1,
        fact: const SetValues(reps: 10, weightKg: 80),
        newId: () => db.collection('ids').doc().id,
        now: DateTime.now(),
      );
      completed = completeWorkout(completed, now: DateTime.now());
      await workouts.save(completed);
      var current = start('current');
      await workouts.start(current);
      current = moveExerciseGroup(current, 2, 0, now: DateTime.now());
      await workouts.save(current);
      await db.waitForPendingWrites();
      Future<void> wait(Finder f) async {
        for (var i = 0; i < 100 && f.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(f, findsWidgets);
      }

      Future<void> tap(Finder f) async {
        await wait(f);
        await tester.ensureVisible(f.first);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(f.first);
        await tester.pump(const Duration(milliseconds: 600));
      }

      Future<void> mark(String name) async {
        // ignore: avoid_print
        print(name.startsWith('FONT:') ? name : 'SHOT:$name');
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(tester.takeException(), isNull);
      }

      Future<void> showCoach() async {
        await tester.pumpWidget(const SizedBox());
        await auth.signOut();
        await auth.signInWithEmailAndPassword(
          email: coachEmail,
          password: password,
        );
        await tester.pumpWidget(
          ProviderScope(key: UniqueKey(), child: const ProgressBarApp()),
        );
        await wait(find.byType(HomeScreen));
        final l = AppLocalizations.of(tester.element(find.byType(HomeScreen)))!;
        await tap(find.text(l.tabPeople));
        await tap(find.text('Айгерим'));
        await wait(find.byType(TraineeScreen));
      }

      await showCoach();
      AppLocalizations l() =>
          AppLocalizations.of(tester.element(find.byType(TraineeScreen)))!;
      await wait(find.text(l().workoutOrderChanged));
      expect(find.text(l().workoutOrderChanged), findsNWidgets(2));
      await tap(find.text(l().workoutOrderChanged).first);
      await wait(find.text(l().workoutPlannedOrder));
      await mark('01-current-mine-order');
      await tap(find.text(l().traineeAll));
      await wait(find.text(l().workoutOrderChanged));
      await mark('02-active-all');
      final coachView = await db
          .doc('users/$trainee/workouts/completed')
          .get(const GetOptions(source: Source.server));
      expect(coachView.data()!['originalOrder'], completed.originalOrder);
      expect(coachView.data()!['bodyWeightKg'], 80);
      await tester.pumpWidget(const SizedBox());
      await auth.signOut();
      await auth.signInWithEmailAndPassword(
        email: traineeEmail,
        password: password,
      );
      var corrected = recordSet(
        completed,
        completed.exercises[1].id,
        completed.exercises[1].sets.first.id,
        fact: const SetValues(reps: 6, weightKg: 60),
        now: DateTime.now(),
      );
      corrected = setWorkoutDay(
        corrected,
        DateTime.now().subtract(const Duration(days: 1)),
        now: DateTime.now(),
      );
      await workouts.save(corrected);
      await db.waitForPendingWrites();
      await links.setStatus(link, LinkStatus.readOnly);
      await showCoach();
      await wait(find.text(l().historyEdited));
      final afterEdit =
          (await db
                  .doc('users/$trainee/workouts/completed')
                  .get(const GetOptions(source: Source.server)))
              .data()!;
      expect(afterEdit['originalOrder'], completed.originalOrder);
      expect(
        (afterEdit['exercises'] as List).map((e) => e['id']),
        completed.exercises.map((e) => e.id),
      );
      expect(afterEdit['exercises'][1]['sets'][0]['fact']['reps'], 6);
      expect(afterEdit['exercises'][1]['sets'][0]['plan']['reps'], 12);
      expect(afterEdit['bodyWeightKg'], 80);
      await mark('02b-coach-after-trainee-edit');
      await wait(find.text(l().traineeReadOnly));
      await wait(find.text(l().workoutOrderChanged));
      expect(find.text(l().workoutOrderChanged), findsNWidgets(2));
      await tap(find.text(l().traineeAll));
      await tap(find.text(l().workoutOrderChanged).first);
      await mark('03-readonly-all-order');
      await profiles.save(coachProfile.copyWith(theme: ThemeChoice.light));
      await mark('04-coach-dawn');
      await mark('FONT:accessibility-large');
      await mark('05-coach-large');
      await auth.signOut();
    },
  );
}
