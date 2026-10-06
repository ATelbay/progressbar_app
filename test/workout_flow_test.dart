import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:progressbar_app/app.dart';
import 'package:progressbar_app/data/exercise_catalog_repository.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/features/auth/auth_controller.dart';
import 'package:progressbar_app/features/exercises/exercise_catalog_provider.dart';
import 'package:progressbar_app/features/firestore_provider.dart';

import 'support/fakes.dart';

void main() {
  late FakeProfileRepository profiles;
  late FakeFirebaseFirestore db;
  late Map<String, Exercise> catalog;

  // Loaded once outside the tests' fake clock: an asset future cached by one
  // widget test never completes for the next one.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    catalog = await AssetExerciseCatalogRepository(rootBundle).load();
  });

  Future<void> openApp(WidgetTester tester) async {
    // A phone-sized screen, as in the mockups.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    profiles = FakeProfileRepository();
    db = FakeFirebaseFirestore();
    await profiles.save(
      const UserProfile(
        id: 'user-1',
        name: 'Арман',
        phone: '+77084880667',
        bodyWeightKg: 80,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(signedInAs: 'user-1'),
          ),
          profileRepositoryProvider.overrideWithValue(profiles),
          firestoreProvider.overrideWithValue(db),
          exerciseCatalogProvider.overrideWith((ref) => catalog),
        ],
        child: const ProgressBarApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> settle(WidgetTester tester) async {
    // Storage answers asynchronously; let it and the screens catch up.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await settle(tester);
  }

  Future<Map<String, dynamic>> onlyWorkout() async =>
      (await db.collection('users/user-1/workouts').get()).docs.single.data();

  Future<void> startWithBenchPress(WidgetTester tester) async {
    await openApp(tester);
    expect(find.text('The bar is empty for now'), findsOneWidget);
    await tap(tester, find.text('Workout without a program'));
    expect(find.text('Add the first exercise.'), findsOneWidget);

    await tap(tester, find.text('Add exercise'));
    await tester.enterText(find.byType(TextField), 'bench press');
    await settle(tester);
    await tap(tester, find.textContaining('Bench Press').first);
    expect(find.text('Record'), findsOneWidget);
  }

  testWidgets('a workout without a program is recorded and finished', (
    tester,
  ) async {
    await startWithBenchPress(tester);
    expect(find.text('0 of 1', findRichText: true), findsOneWidget);

    await tap(tester, find.byTooltip('More: Weight'));
    await tap(tester, find.byTooltip('More: Weight'));
    await tap(tester, find.byTooltip('Less: Reps'));
    await tap(tester, find.text('Record'));

    expect(find.text('3 × 9 × 5 kg', findRichText: true), findsOneWidget);
    expect(find.text('1 of 1', findRichText: true), findsOneWidget);
    expect(find.text('Everything is recorded'), findsOneWidget);
    // Summary entry is stored set by set.
    final sets = (await onlyWorkout())['exercises'][0]['sets'] as List;
    expect(sets.length, 3);
    expect(sets.map((s) => s['fact']['weightKg']), everyElement(5));
    expect(sets.map((s) => s['fact']['reps']), everyElement(9));
    expect(sets.map((s) => s['plan']), everyElement(isNull));
    expect(profiles.profileOf('user-1')!.lastSetCount, 3);

    await tap(tester, find.widgetWithText(FilledButton, 'Finish'));
    expect(find.text('Finish the workout?'), findsOneWidget);
    await tap(tester, find.widgetWithText(FilledButton, 'Finish').last);

    expect(find.text('The bar is empty for now'), findsOneWidget);
    final stored = await onlyWorkout();
    expect(stored['status'], 'completed');
    expect(stored['bodyWeightKg'], 80);
  });

  testWidgets('sets are recorded one by one, weight typed on the keypad', (
    tester,
  ) async {
    await startWithBenchPress(tester);
    await tap(tester, find.text('Add each set'));
    expect(profiles.profileOf('user-1')!.entryMode, EntryMode.perSet);
    expect(find.text('Record set 1'), findsOneWidget);

    await tap(tester, find.text('0 kg', findRichText: true));
    for (final key in ['4', '2', ',', '5']) {
      await tap(tester, find.widgetWithText(TextButton, key));
    }
    await tap(tester, find.text('Done'));
    expect(find.text('42.5 kg', findRichText: true), findsOneWidget);

    await tap(tester, find.text('Some left'));
    await tap(tester, find.text('Record set 1'));
    expect(find.text('Record set 2'), findsOneWidget);
    await tap(tester, find.text('Record set 2'));

    final sets = (await onlyWorkout())['exercises'][0]['sets'] as List;
    expect(sets.map((s) => s['fact']['weightKg']), [42.5, 42.5]);
    expect(sets.map((s) => s['rpe']), [8.5, null]);

    await tap(tester, find.text('Total only'));
    expect(profiles.profileOf('user-1')!.entryMode, EntryMode.summary);
    expect(find.text('Record'), findsOneWidget);
  });

  testWidgets('cancelling removes the workout and returns home', (
    tester,
  ) async {
    await startWithBenchPress(tester);
    await tap(tester, find.widgetWithText(TextButton, 'Finish'));
    // Nothing is recorded, so there is nothing to keep.
    expect(find.widgetWithText(FilledButton, 'Finish'), findsNothing);
    await tap(tester, find.text('Cancel the workout and delete the records'));
    expect(find.text('The bar is empty for now'), findsOneWidget);
    expect((await db.collection('users/user-1/workouts').get()).docs, isEmpty);
  });

  testWidgets('a workout in progress is offered on the home screen', (
    tester,
  ) async {
    await startWithBenchPress(tester);
    // The system «back»: a swipe on iOS, the button on Android.
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.text('Workout in progress'), findsOneWidget);
    expect(find.text('Workout without a program'), findsNothing);
    await tap(tester, find.text('Continue'));
    expect(find.text('Record'), findsOneWidget);
  });

  testWidgets('a program is built, started and its plan copied', (
    tester,
  ) async {
    await openApp(tester);
    await tap(tester, find.text('New program'));
    await tester.enterText(find.byType(TextField), 'Strength');
    await settle(tester);
    expect(find.text('Day 1'), findsOneWidget);
    // An empty day cannot be started.
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Start workout'),
          )
          .onPressed,
      isNull,
    );

    await tap(tester, find.widgetWithText(OutlinedButton, 'Exercise'));
    await tester.enterText(find.byType(TextField), 'bench press');
    await settle(tester);
    await tap(tester, find.textContaining('Bench Press').first);
    await tap(tester, find.byTooltip('More: Weight'));
    await tap(tester, find.byTooltip('More: Sets'));
    await tap(tester, find.text('Done'));
    expect(find.text('4 × 10 × 2.5 kg', findRichText: true), findsOneWidget);

    await tap(tester, find.byTooltip('Add day'));
    expect(find.text('Day 2'), findsOneWidget);
    expect(find.text('No exercises in this day yet.'), findsOneWidget);
    await tap(tester, find.text('Day 1'));

    final program = (await db.collection('users/user-1/programs').get())
        .docs
        .single
        .data();
    expect(program['name'], 'Strength');
    expect((program['days'] as List).map((d) => d['name']), ['Day 1', 'Day 2']);
    expect((program['days'][0]['exercises'][0]['sets'] as List).length, 4);

    await tap(tester, find.text('Start workout'));
    // The workout opens with the plan and the day's name.
    expect(find.text('Day 1'), findsOneWidget);
    expect(find.text('4 × 10 × 2.5 kg', findRichText: true), findsOneWidget);
    await tap(tester, find.text('Record'));
    expect(find.text('on plan'), findsOneWidget);

    final workout = await onlyWorkout();
    expect(workout['programName'], 'Strength');
    expect(workout['dayName'], 'Day 1');
    final sets = workout['exercises'][0]['sets'] as List;
    expect(sets.length, 4);
    expect(sets.map((s) => s['plan']['weightKg']), everyElement(2.5));
    expect(sets.map((s) => s['fact']['weightKg']), everyElement(2.5));

    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.text('Strength'), findsOneWidget);
    expect(find.text('2 days'), findsOneWidget);
    expect(find.text('Workout in progress'), findsOneWidget);
  });

  testWidgets('a finished workout appears in history and can be corrected', (
    tester,
  ) async {
    await startWithBenchPress(tester);
    await tap(tester, find.text('Record'));
    await tap(tester, find.widgetWithText(FilledButton, 'Finish'));
    await tap(tester, find.widgetWithText(FilledButton, 'Finish').last);

    await tap(tester, find.text('History'));
    expect(find.text('No program'), findsOneWidget);
    expect(find.text('1 exercise'), findsOneWidget);
    expect(find.text('3 × 10 × 0 kg', findRichText: true), findsOneWidget);
    expect(find.text('edited after completion'), findsNothing);

    await tap(tester, find.byTooltip('Edit workout'));
    expect(find.textContaining('This workout is completed'), findsOneWidget);
    // Nothing changed yet, so there is nothing to save.
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Save changes'),
          )
          .onPressed,
      isNull,
    );
    await tap(tester, find.byIcon(Icons.edit_outlined));
    await tap(tester, find.byTooltip('More: Weight'));
    await tap(tester, find.byTooltip('Less: Sets'));
    await tap(tester, find.text('Record'));
    expect(find.text('2 × 10 × 2.5 kg', findRichText: true), findsOneWidget);
    // Not stored until saved.
    expect((await onlyWorkout())['editedAt'], isNull);

    await tap(tester, find.text('Save changes'));
    expect(find.text('edited after completion'), findsOneWidget);
    expect(find.text('2 × 10 × 2.5 kg', findRichText: true), findsOneWidget);
    final stored = await onlyWorkout();
    expect(stored['editedAt'], isNotNull);
    expect(stored['status'], 'completed');
    expect((stored['exercises'][0]['sets'] as List).length, 2);
  });

  testWidgets('history without workouts leads back to programs', (
    tester,
  ) async {
    await openApp(tester);
    await tap(tester, find.text('History'));
    expect(find.text('No workouts yet'), findsOneWidget);
    await tap(tester, find.text('To programs'));
    expect(find.text('The bar is empty for now'), findsOneWidget);
  });

  testWidgets('progress shows a point per finished workout', (tester) async {
    await openApp(tester);
    await tap(tester, find.text('Progress'));
    expect(find.text('No points yet'), findsOneWidget);
    await tap(tester, find.text('Home'));

    for (final presses in [2, 3]) {
      await tap(tester, find.text('Workout without a program'));
      await tap(tester, find.text('Add exercise'));
      await tester.enterText(find.byType(TextField), 'bench press');
      await settle(tester);
      await tap(tester, find.textContaining('Bench Press').first);
      // The second workout opens with the first one's result.
      for (var i = 0; i < presses; i++) {
        await tap(tester, find.byTooltip('More: Weight'));
      }
      await tap(tester, find.text('Record'));
      await tap(tester, find.widgetWithText(FilledButton, 'Finish'));
      await tap(tester, find.widgetWithText(FilledButton, 'Finish').last);
    }

    await tap(tester, find.text('Progress'));
    expect(find.text('Heaviest weight'), findsOneWidget);
    // 5 kg, then 5 + 7.5 kg: the latest twice, in the panel and in the list.
    expect(find.text('12.5 kg', findRichText: true), findsNWidgets(2));
    expect(find.text('5 kg', findRichText: true), findsOneWidget);
    expect(find.text('+7.5 kg over 2 workouts'), findsOneWidget);
  });

  testWidgets('profile changes language, entry mode, name and body weight', (
    tester,
  ) async {
    await openApp(tester);
    await tap(tester, find.text('Profile'));
    expect(find.text('Арман'), findsOneWidget);
    expect(find.text('80 kg', findRichText: true), findsOneWidget);

    await tap(tester, find.text('Result entry'));
    await tap(tester, find.text('Set by set'));
    expect(profiles.profileOf('user-1')!.entryMode, EntryMode.perSet);

    await tap(tester, find.text('Арман'));
    await tester.enterText(find.byType(TextField), 'Арман Т.');
    await tap(tester, find.byTooltip('More: Body weight'));
    await tap(tester, find.text('Save'));
    expect(profiles.profileOf('user-1')!.name, 'Арман Т.');
    expect(profiles.profileOf('user-1')!.bodyWeightKg, 80.5);

    await tap(tester, find.text('Language'));
    await tap(tester, find.text('Русский'));
    expect(profiles.profileOf('user-1')!.languageCode, 'ru');
    // The whole interface follows at once.
    expect(find.text('Профиль'), findsWidgets);
    expect(find.text('Справочник упражнений'), findsOneWidget);

    await tap(tester, find.text('Язык'));
    await tap(tester, find.text('Как в телефоне'));
    expect(profiles.profileOf('user-1')!.languageCode, isNull);
    expect(find.text('Exercise catalog'), findsOneWidget);
  });

  testWidgets('the catalog takes own exercises and edits of built-in ones', (
    tester,
  ) async {
    await openApp(tester);
    await tap(tester, find.text('Profile'));
    await tap(tester, find.text('Exercise catalog'));

    await tap(tester, find.text('Your own exercise'));
    await tester.enterText(find.byType(TextField).last, 'Sled push');
    await tap(tester, find.widgetWithText(TextButton, 'Legs').last);
    await tap(tester, find.widgetWithText(TextButton, 'Time'));
    await tap(tester, find.text('Save'));
    await tester.enterText(find.byType(TextField), 'sled');
    await settle(tester);
    expect(find.text('Sled push'), findsOneWidget);
    expect(find.text('yours'), findsOneWidget);
    var stored = (await db.collection('users/user-1/exercises').get()).docs;
    expect(stored.single.data()['id'], startsWith('custom/'));
    expect(stored.single.data()['measure'], 'time');
    expect(stored.single.data()['muscleGroup'], 'quadriceps');

    await tester.enterText(find.byType(TextField), 'bench press');
    await settle(tester);
    await tap(tester, find.textContaining('Bench Press').first);
    await tester.enterText(find.byType(TextField).last, 'My bench');
    await settle(tester);
    await tap(tester, find.text('Save'));
    await tester.enterText(find.byType(TextField), 'my bench');
    await settle(tester);
    expect(find.text('My bench'), findsOneWidget);
    expect(find.text('edited'), findsOneWidget);
    stored = (await db.collection('users/user-1/exercises').get()).docs;
    expect(stored.length, 2);

    await tap(tester, find.text('My bench'));
    await tap(tester, find.text('Restore the original'));
    expect(find.text('My bench'), findsNothing);
    stored = (await db.collection('users/user-1/exercises').get()).docs;
    expect(stored.single.data()['id'], startsWith('custom/'));
  });
}
