import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progressbar_app/app.dart';
import 'package:progressbar_app/data/firestore_codec.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/features/auth/auth_controller.dart';
import 'package:progressbar_app/features/exercises/exercise_catalog_provider.dart';
import 'package:progressbar_app/features/firestore_provider.dart';

import 'support/fakes.dart';

void main() {
  late FakeFirebaseFirestore db;
  const program = Program(
    id: 'p',
    authorId: 'coach',
    name: 'Coach plan',
    days: [
      ProgramDay(
        id: 'd',
        name: 'Back',
        exercises: [
          ProgramExercise(
            id: 'pe',
            exerciseId: 'custom/one',
            sets: [SetValues(reps: 8, weightKg: 40)],
          ),
        ],
      ),
    ],
  );
  const exercise = Exercise(
    id: 'custom/one',
    names: {'en': 'Coach row'},
    muscleGroup: 'lats',
  );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> tap(WidgetTester tester, String text) async {
    final finder = find.text(text).first;
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await settle(tester);
  }

  Future<void> open(WidgetTester tester, String uid) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    db = FakeFirebaseFirestore();
    await db.doc('links/coach_trainee').set({
      'coachId': 'coach',
      'traineeId': 'trainee',
      'coachName': 'Sergey',
      'traineeName': 'Aigerim',
      'status': 'active',
      'createdAt': Timestamp.now(),
    });
    await db.doc('users/coach/programs/p').set(programToMap(program));
    await db
        .doc('users/coach/exercises/custom~one')
        .set(exerciseToMap(exercise));
    final profiles = FakeProfileRepository();
    await profiles.save(UserProfile(id: uid, name: uid, phone: '+77010000001'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(signedInAs: uid),
          ),
          profileRepositoryProvider.overrideWithValue(profiles),
          firestoreProvider.overrideWithValue(db),
          exerciseCatalogProvider.overrideWith((_) async => {}),
        ],
        child: const ProgressBarApp(),
      ),
    );
    await settle(tester);
  }

  Future<void> assign() => db.doc('users/trainee/assignments/coach_p').set({
    'coachId': 'coach',
    'traineeId': 'trainee',
    'programId': 'p',
    'assignedAt': Timestamp.now(),
  });

  testWidgets('trainee starts read-only program with coach custom exercise', (
    tester,
  ) async {
    await open(tester, 'trainee');
    await assign();
    await settle(tester);
    expect(find.text('Assigned by Sergey'), findsOneWidget);
    await tap(tester, 'Coach plan');
    expect(find.text('Coach row'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Delete program'), findsNothing);
    expect(find.text('Assign to trainee'), findsNothing);
    await tap(tester, 'Start workout');
    await tap(tester, 'Continue');
    await tap(tester, 'Continue');
    await tap(tester, 'Record');
    await tap(tester, 'Finish');
    await tester.tap(find.widgetWithText(FilledButton, 'Finish').last);
    await settle(tester);
    final doc = (await db.collection('users/trainee/workouts').get())
        .docs
        .single
        .data();
    expect(doc['traineeId'], 'trainee');
    expect(doc['supervisorCoachId'], 'coach');
    expect(doc['supervisorCoachName'], 'Sergey');
    expect(doc['exercises'][0]['name'], 'Coach row');
    expect(doc['exercises'][0]['sets'][0]['plan']['weightKg'], 40);
    await tap(tester, 'History');
    expect(find.text('Coach: Sergey'), findsOneWidget);
  });

  testWidgets(
    'shared program updates live, deactivation keeps it, removal closes it',
    (tester) async {
      await open(tester, 'trainee');
      await assign();
      await settle(tester);
      await tap(tester, 'Coach plan');
      await db.doc('users/coach/programs/p').update({'name': 'Updated plan'});
      await settle(tester);
      expect(find.text('Updated plan'), findsOneWidget);
      await db.doc('links/coach_trainee').update({'status': 'readOnly'});
      await settle(tester);
      expect(find.text('Start workout'), findsOneWidget);
      await db.doc('links/coach_trainee').update({'status': 'removed'});
      await settle(tester);
      expect(find.text('Start workout'), findsNothing);
      expect(
        find.text('Program unavailable: it was deleted or access was closed.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'coach opens correct trainee, assigns, and filters live workouts',
    (tester) async {
      await open(tester, 'coach');
      for (final id in ['mine', 'other']) {
        await db
            .doc('users/trainee/workouts/$id')
            .set(
              workoutToMap(
                Workout(
                  id: id,
                  traineeId: 'trainee',
                  supervisorCoachId: id == 'mine' ? 'coach' : null,
                  supervisorCoachName: id == 'mine' ? 'Sergey' : null,
                  programName: id == 'mine' ? 'Supervised' : 'Solo workout',
                  status: WorkoutStatus.inProgress,
                  startedAt: DateTime(2026, 10, 6),
                  exercises: [],
                ),
              ),
            );
      }
      await tap(tester, 'People');
      await tap(tester, 'Aigerim');
      expect(find.text('Supervised'), findsOneWidget);
      expect(find.text('Solo workout'), findsNothing);
      expect(find.text('Edit workout'), findsNothing);
      await tap(tester, 'All');
      expect(find.text('Solo workout'), findsOneWidget);
      await tap(tester, 'Assign program');
      await tap(tester, 'Coach plan');
      expect(
        (await db.doc('users/trainee/assignments/coach_p').get()).exists,
        isTrue,
      );
      await db.doc('links/coach_trainee').update({'status': 'readOnly'});
      await settle(tester);
      expect(find.text('Assign program'), findsNothing);
      expect(find.text('Supervised'), findsOneWidget);
      await db.doc('links/coach_trainee').update({'status': 'removed'});
      await settle(tester);
      expect(find.text('Supervised'), findsNothing);
      expect(find.text('Access to this trainee is closed.'), findsOneWidget);
    },
  );

  testWidgets('builder assigns own program to active trainee', (tester) async {
    await open(tester, 'coach');
    await tap(tester, 'Coach plan');
    await tap(tester, 'Assign to trainee');
    await tap(tester, 'Aigerim');
    expect(
      (await db.doc('users/trainee/assignments/coach_p').get()).exists,
      isTrue,
    );
  });
}
