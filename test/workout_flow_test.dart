import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show CustomSemanticsAction, SemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:progressbar_app/app.dart';
import 'package:progressbar_app/l10n/app_localizations.dart';
import 'package:progressbar_app/features/home/home_screen.dart';
import 'package:progressbar_app/data/exercise_catalog_repository.dart';
import 'package:progressbar_app/data/firestore_codec.dart';
import 'package:progressbar_app/data/link_repository.dart';
import 'package:progressbar_app/data/program_repository.dart';
import 'package:progressbar_app/data/workout_repository.dart';
import 'package:progressbar_app/domain/link_logic.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/domain/workout_logic.dart';
import 'package:progressbar_app/features/auth/auth_controller.dart';
import 'package:progressbar_app/features/exercises/exercise_catalog_provider.dart';
import 'package:progressbar_app/features/firestore_provider.dart';
import 'package:progressbar_app/features/people/people_providers.dart';
import 'package:progressbar_app/features/workout/entry_panel.dart';
import 'package:progressbar_app/features/workout/execution_entry_panel.dart';
import 'package:progressbar_app/widgets/barbell.dart';
import 'package:progressbar_app/widgets/qr_code.dart';
import 'package:progressbar_app/widgets/step_button.dart';

import 'support/fakes.dart';

void main() {
  late FakeProfileRepository profiles;
  late FakeFirebaseFirestore db;
  late Map<String, Exercise> catalog;
  // What the app handed to the system share sheet.
  final shared = <String>[];

  // Loaded once outside the tests' fake clock: an asset future cached by one
  // widget test never completes for the next one.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    catalog = await AssetExerciseCatalogRepository(rootBundle).load();
  });

  Future<void> openApp(
    WidgetTester tester, {
    FakeFirebaseFirestore? seeded,
  }) async {
    // A phone-sized screen, as in the mockups.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    profiles = FakeProfileRepository();
    db = seeded ?? FakeFirebaseFirestore();
    shared.clear();
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
          shareTextProvider.overrideWithValue(
            (text, _) async => shared.add(text),
          ),
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

  Future<void> typeNumber(WidgetTester tester, String value) async {
    for (final key in value.split('')) {
      await tap(tester, find.widgetWithText(PbPill, key));
    }
  }

  Future<void> record(
    WidgetTester tester, {
    String? sets,
    String? count,
    String? weight,
  }) async {
    if (sets != null) await typeNumber(tester, sets);
    await tap(tester, find.widgetWithText(FilledButton, 'Continue'));
    if (count != null) await typeNumber(tester, count);
    await tap(tester, find.widgetWithText(FilledButton, 'Continue'));
    if (weight != null) await typeNumber(tester, weight);
    await tap(tester, find.text('Record'));
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
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
  }

  testWidgets('a workout without a program is recorded and finished', (
    tester,
  ) async {
    await startWithBenchPress(tester);
    expect(find.text('0 of 1', findRichText: true), findsOneWidget);

    await record(tester, count: '9', weight: '5');

    expect(find.text('3 × 9 × 5 kg', findRichText: true), findsOneWidget);
    expect(find.text('1 of 1', findRichText: true), findsOneWidget);
    expect(find.text('Everything is recorded'), findsOneWidget);
    expect(find.text('Recorded'), findsOneWidget);
    expect(find.text('Outside plan'), findsNothing);
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
    await tap(tester, find.text('Set by set'));
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
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
  });

  testWidgets('cancelling removes the workout and returns home', (
    tester,
  ) async {
    await startWithBenchPress(tester);
    await tap(tester, find.widgetWithText(TextButton, 'Finish'));
    // Nothing is recorded, so there is nothing to keep.
    expect(find.widgetWithText(FilledButton, 'Finish'), findsNothing);
    await tap(tester, find.text('Cancel the workout'));
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
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
    final before = await onlyWorkout();
    await tap(tester, find.byTooltip('Back'));
    expect(find.text('Workout in progress'), findsOneWidget);
    expect(await onlyWorkout(), before);
  });

  testWidgets('a program is built, started and its plan copied', (
    tester,
  ) async {
    await openApp(tester);
    await tap(tester, find.text('New program'));
    await tester.enterText(find.byType(TextField), 'Strength');
    await settle(tester);
    expect(find.text('Day 1'), findsOneWidget);
    // Once it has a name it is stored, so it can already be deleted.
    expect(find.text('Delete program'), findsOneWidget);
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
    // A new plan opens the keypad at sets, then reps, then weight.
    expect(find.textContaining('Not recorded before'), findsOneWidget);
    expect(find.text('Note for the trainee'), findsNothing);
    await tap(tester, find.widgetWithText(FilledButton, 'Continue'));
    await tap(tester, find.widgetWithText(FilledButton, 'Continue'));
    await tap(tester, find.widgetWithText(PbPill, '7'));
    await tap(tester, find.byTooltip('Decimal point'));
    await tap(tester, find.widgetWithText(PbPill, '5'));
    await tap(tester, find.text('Done'));
    expect(find.text('3 × 10 × 7.5 kg', findRichText: true), findsOneWidget);
    // The program name does not take the keyboard back and cover the list.
    expect(tester.testTextInput.isVisible, isFalse);
    // The keypad saves and closes the whole sheet in one tap. Reopen the
    // saved plan to adjust its steps and set count.
    expect(find.text('Note for the trainee'), findsNothing);
    await tap(tester, find.text('3 × 10 × 7.5 kg', findRichText: true));
    // From here on the weight is stepped, up in the top row and down below.
    expect(find.text('Note for the trainee'), findsOneWidget);
    await tap(tester, find.text('+0.5'));
    await tap(tester, find.text('−5'));
    await tap(tester, find.text('−1'));
    await tap(tester, find.byKey(const ValueKey('entry-sets')));
    await typeNumber(tester, '4');
    await tap(tester, find.widgetWithText(FilledButton, 'Continue'));
    await tap(tester, find.widgetWithText(FilledButton, 'Continue'));
    await tap(tester, find.text('Done'));
    expect(find.text('4 × 10 × 2 kg', findRichText: true), findsOneWidget);

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
    expect(find.text('4 × 10 × 2 kg', findRichText: true), findsOneWidget);
    await record(tester);
    expect(find.text('on plan'), findsOneWidget);

    final workout = await onlyWorkout();
    expect(workout['programName'], 'Strength');
    expect(workout['dayName'], 'Day 1');
    final sets = workout['exercises'][0]['sets'] as List;
    expect(sets.length, 4);
    expect(sets.map((s) => s['plan']['weightKg']), everyElement(2));
    expect(sets.map((s) => s['fact']['weightKg']), everyElement(2));

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
    await record(tester);
    await tap(tester, find.widgetWithText(FilledButton, 'Finish'));
    // With results recorded the workout is finished, not thrown away; the
    // day it counts for is today unless changed.
    expect(find.text('Cancel the workout'), findsNothing);
    expect(find.textContaining('Today, '), findsOneWidget);
    await tap(tester, find.widgetWithText(FilledButton, 'Finish').last);
    expect((await onlyWorkout())['performedOn'], isNull);

    await tap(tester, find.text('History'));
    expect(find.text('No program'), findsOneWidget);
    expect(find.text('1 exercise'), findsOneWidget);
    expect(find.text('3 × 10 × 0 kg', findRichText: true), findsOneWidget);
    expect(find.text('edited after completion'), findsNothing);

    await tap(tester, find.text('Hide details'));
    expect(find.text('3 × 10 × 0 kg', findRichText: true), findsNothing);
    await tap(tester, find.text('No program'));
    expect(find.text('3 × 10 × 0 kg', findRichText: true), findsOneWidget);

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
    await record(tester, sets: '2', weight: '2,5');
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

    // A completed workout can be removed from history, after a question.
    await tap(tester, find.byTooltip('Edit workout'));
    await tap(tester, find.text('Delete workout'));
    expect(find.textContaining('Delete this workout?'), findsOneWidget);
    await tap(tester, find.text('Keep'));
    expect((await db.collection('users/user-1/workouts').get()).docs.length, 1);
    await tap(tester, find.text('Delete workout'));
    await tap(tester, find.text('Delete'));
    expect((await db.collection('users/user-1/workouts').get()).docs, isEmpty);
    expect(find.text('Delete workout'), findsNothing);
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

  testWidgets(
    'history reveals drop plan beside fact including missing stages',
    (tester) async {
      await openApp(tester);
      final done = DateTime(2026, 10, 17, 18);
      final workout = Workout(
        id: 'drop-history',
        traineeId: 'user-1',
        status: WorkoutStatus.completed,
        startedAt: done,
        completedAt: done,
        exercises: const [
          WorkoutExercise(
            id: 'leg-press',
            exerciseId: 'leg-press',
            name: 'Leg press',
            measure: Measure.reps,
            usesBodyWeight: false,
            executionMode: ExecutionMode.dropSet,
            sets: [
              WorkoutSet(
                id: 'set',
                plan: SetValues(reps: 10, weightKg: 100),
                fact: SetValues(reps: 9, weightKg: 100),
                dropComplete: true,
                drops: [
                  DropStage(
                    id: 'reduction',
                    plan: SetValues(reps: 8, weightKg: 75),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      await tester.runAsync(
        () => db
            .doc('users/user-1/workouts/drop-history')
            .set(workoutToMap(workout)),
      );
      await settle(tester);
      await tap(tester, find.text('History'));
      expect(find.text('100 kg × 9\n—'), findsNothing);
      await tap(tester, find.text('Leg press'));
      expect(find.text('100 kg × 10\n75 kg × 8'), findsOneWidget);
      expect(find.text('100 kg × 9\n—'), findsOneWidget);
      await tap(tester, find.text('Leg press').first);
      expect(find.text('100 kg × 9\n—'), findsNothing);
      expect(await onlyWorkout(), workoutToMap(workout));
    },
  );

  testWidgets('progress lists exercises and opens a chart per metric', (
    tester,
  ) async {
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
      // The second draft suggests the previous result; typing replaces it.
      await record(tester, weight: presses == 2 ? '5' : '12,5');
      await tap(tester, find.widgetWithText(FilledButton, 'Finish'));
      await tap(tester, find.widgetWithText(FilledButton, 'Finish').last);
    }

    // 3 × 10 × 5 kg, then 3 × 10 × 12.5 kg: estimated at 6.5 and 16.5 kg.
    await tap(tester, find.text('Progress'));
    expect(find.text('12.5 kg × 10'), findsOneWidget);
    expect(find.text('≈ 16.5 kg', findRichText: true), findsOneWidget);
    expect(find.text('+10 kg'), findsOneWidget);
    // Search stays available with a single exercise.
    expect(find.byType(TextField), findsOneWidget);

    await tap(tester, find.textContaining('Bench Press'));
    expect(find.text('Estimated one-rep max'), findsOneWidget);
    expect(find.text('+10 kg over 2 workouts'), findsOneWidget);
    expect(find.text('Best set: 12.5 kg × 10'), findsOneWidget);
    // Every point under the chart, the oldest last.
    await tester.dragUntilVisible(
      find.text('≈ 6.5 kg'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('5 kg × 10', findRichText: true), findsOneWidget);

    await tap(tester, find.text('Weight'));
    expect(find.text('Heaviest weight'), findsOneWidget);
    expect(find.text('+7.5 kg over 2 workouts'), findsOneWidget);
    await tap(tester, find.text('Reps'));
    expect(find.text('Reps in the heaviest set'), findsOneWidget);
    expect(find.text('10 reps', findRichText: true), findsOneWidget);

    // The choice stays when the chart is opened again.
    await tap(tester, find.byTooltip('Back'));
    expect(find.text('≈ 16.5 kg', findRichText: true), findsOneWidget);
    await tap(tester, find.textContaining('Bench Press'));
    expect(find.text('Reps in the heaviest set'), findsOneWidget);
  });

  testWidgets('progress finds an exercise by name', (tester) async {
    await openApp(tester);
    final picked = catalog.values
        .where((e) => e.measure == Measure.reps && !e.usesBodyWeight)
        .take(3)
        .toList();
    final ids = <String>[];
    var n = 0;
    var workout = startWorkout(
      id: 'past',
      traineeId: 'user-1',
      now: DateTime(2026, 10, 1, 18),
      newId: () => 'id${n++}',
      catalog: catalog,
      languageCode: 'en',
    );
    for (final exercise in picked) {
      workout = addExercise(
        workout,
        exercise,
        languageCode: 'en',
        newId: () => 'id${n++}',
        now: workout.startedAt,
      );
      ids.add(workout.exercises.last.id);
      workout = addExtraSet(
        workout,
        ids.last,
        fact: const SetValues(reps: 5, weightKg: 50),
        newId: () => 'id${n++}',
        now: workout.startedAt,
      );
    }
    workout = completeWorkout(workout, now: workout.startedAt);
    await tester.runAsync(
      () => db.doc('users/user-1/workouts/past').set(workoutToMap(workout)),
    );
    await settle(tester);

    await tap(tester, find.text('Progress'));
    for (final exercise in picked) {
      expect(find.text(exercise.nameFor('en')), findsOneWidget);
    }
    final target = picked.last.nameFor('en');
    await tester.enterText(find.byType(TextField), target.toUpperCase());
    await settle(tester);
    expect(find.text(target), findsOneWidget);
    expect(find.text(picked.first.nameFor('en')), findsNothing);

    await tester.enterText(find.byType(TextField), 'no such exercise');
    await settle(tester);
    expect(find.text('Nothing found'), findsOneWidget);
  });

  testWidgets(
    'profile changes language, theme, entry mode, name and body weight',
    (tester) async {
      await openApp(tester);
      await tap(tester, find.text('Profile'));
      expect(find.text('Арман'), findsOneWidget);
      expect(find.text('80 kg', findRichText: true), findsOneWidget);

      await tap(tester, find.text('Result entry'));
      await tap(tester, find.text('Set by set'));
      expect(profiles.profileOf('user-1')!.entryMode, EntryMode.perSet);

      // The look follows the phone until one is chosen.
      await tap(tester, find.text('Theme'));
      await tap(tester, find.text('Dark'));
      expect(profiles.profileOf('user-1')!.theme, ThemeChoice.dark);
      expect(
        Theme.of(tester.element(find.text('Theme'))).brightness,
        Brightness.dark,
      );

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
    },
  );

  testWidgets('large Kazakh navigation labels stay inside the panel', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openApp(tester);
    await profiles.save(
      profiles.profileOf('user-1')!.copyWith(languageCode: () => 'kk'),
    );
    await settle(tester);
    final bar = find.byType(NavigationBar);
    final bounds = tester.getRect(bar);
    for (final label in [
      'Басты бет',
      'Тарих',
      'Прогресс',
      'Адамдар',
      'Профиль',
    ]) {
      final text = find.descendant(of: bar, matching: find.text(label));
      final rect = tester.getRect(text);
      expect(rect.top, greaterThanOrEqualTo(bounds.top));
      expect(rect.bottom, lessThanOrEqualTo(bounds.bottom));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('the catalog takes own exercises and edits of built-in ones', (
    tester,
  ) async {
    await openApp(tester);
    await tap(tester, find.text('Profile'));
    // The test font is far wider than the real one, so the settings take
    // more room here than on a phone and the last row starts off screen.
    await tester.dragUntilVisible(
      find.text('Exercise catalog'),
      find.byType(ListView),
      const Offset(0, -200),
    );
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

  testWidgets('a coach is accepted by code, supervises, then is deactivated', (
    tester,
  ) async {
    await openApp(tester);
    final links = FirestoreLinkRepository(db);
    late Invitation fromCoach;
    await tester.runAsync(() async {
      fromCoach = await links.createInvitation(
        inviterId: 'sergey',
        inviterName: 'Сергей',
        role: LinkRole.coach,
      );
    });

    await tap(tester, find.text('People'));
    expect(find.textContaining('No one here yet'), findsOneWidget);
    await tap(tester, find.text('Enter an invitation code'));
    // A wrong code is explained, not accepted.
    await tester.enterText(find.byType(TextField), 'ZZZ ZZZ');
    await settle(tester);
    await tap(tester, find.text('Find'));
    expect(find.textContaining('No such invitation'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      formatInviteCode(fromCoach.code).toLowerCase(),
    );
    await settle(tester);
    await tap(tester, find.text('Find'));
    expect(find.text('Сергей'), findsOneWidget);
    expect(find.text('invites you as a coach'), findsOneWidget);
    await tap(tester, find.text('Accept'));

    expect(find.text('My coaches'), findsOneWidget);
    expect(find.text('Сергей'), findsOneWidget);
    expect(find.text('active'), findsOneWidget);
    expect(
      (await db.doc('links/sergey_user-1').get()).data()!['status'],
      'active',
    );
    expect(
      (await db.doc('invitations/${fromCoach.code}').get()).exists,
      isFalse,
    );

    // A workout started now is recorded under this coach.
    await tap(tester, find.text('Home'));
    await tap(tester, find.text('Workout without a program'));
    expect((await onlyWorkout())['supervisorCoachId'], 'sergey');
    await tester.binding.handlePopRoute();
    await settle(tester);

    await tap(tester, find.text('People'));
    await tap(tester, find.text('Сергей'));
    expect(find.text('Сергей, coach'), findsOneWidget);
    await tap(tester, find.text('Deactivate'));
    expect(find.text('view only'), findsOneWidget);
    expect(
      (await db.doc('links/sergey_user-1').get()).data()!['status'],
      'readOnly',
    );

    await tap(tester, find.text('Сергей'));
    // A read-only coach can only be removed.
    expect(find.text('Deactivate'), findsNothing);
    await tap(tester, find.text('Delete'));
    expect(find.text('Сергей'), findsNothing);
    expect(
      (await db.doc('links/sergey_user-1').get()).data()!['status'],
      'removed',
    );
  });

  testWidgets('an invitation is created in the chosen role', (tester) async {
    await openApp(tester);
    await tap(tester, find.text('People'));
    await tap(tester, find.text('Invite'));
    await tap(tester, find.text('I am the trainee'));
    await tap(tester, find.text('Create invitation'));
    expect(find.textContaining('You invite as a trainee'), findsOneWidget);

    final stored = (await db.collection('invitations').get()).docs.single;
    expect(stored.data()['inviterId'], 'user-1');
    expect(stored.data()['inviterName'], 'Арман');
    expect(stored.data()['inviterRole'], 'trainee');
    expect(find.text(formatInviteCode(stored.id)), findsOneWidget);
    // The same code goes out as a QR code and as a link to share.
    expect(
      tester.widget<QrCodeView>(find.byType(QrCodeView)).data,
      inviteLink(stored.id),
    );
    await tap(tester, find.text('Share link'));
    expect(shared.single, contains(inviteLink(stored.id)));
    expect(shared.single, contains(formatInviteCode(stored.id)));

    // The other person accepts: they appear among the coaches.
    await tester.runAsync(() async {
      final links = FirestoreLinkRepository(db);
      await links.accept(
        (await links.findInvitation(stored.id))!,
        acceptorId: 'madina',
        acceptorName: 'Мадина',
      );
    });
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.text('Мадина'), findsOneWidget);
    expect(find.text('Assigns programs'), findsOneWidget);
  });

  testWidgets('an invitation link opens the invitation, ready to accept', (
    tester,
  ) async {
    await openApp(tester);
    late Invitation fromCoach;
    await tester.runAsync(() async {
      fromCoach = await FirestoreLinkRepository(db).createInvitation(
        inviterId: 'sergey',
        inviterName: 'Сергей',
        role: LinkRole.coach,
      );
    });
    // The way the system hands a link to a running app.
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(
        MethodCall('pushRouteInformation', {
          'location': inviteLink(fromCoach.code),
        }),
      ),
      (_) {},
    );
    await settle(tester);
    expect(find.text('invites you as a coach'), findsOneWidget);
    await tap(tester, find.text('Accept'));
    expect(find.text('Home'), findsWidgets);
    expect(
      (await db.doc('links/sergey_user-1').get()).data()!['status'],
      'active',
    );

    // A link that is not an invitation leaves the app where it was.
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(
        const MethodCall('pushRouteInformation', {
          'location': 'progressbar://app/join/nonsense',
        }),
      ),
      (_) {},
    );
    await settle(tester);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Find'), findsNothing);
  });

  testWidgets('started by an invitation link, the app opens the invitation', (
    tester,
  ) async {
    final seeded = FakeFirebaseFirestore();
    late Invitation fromCoach;
    await tester.runAsync(() async {
      fromCoach = await FirestoreLinkRepository(seeded).createInvitation(
        inviterId: 'sergey',
        inviterName: 'Сергей',
        role: LinkRole.coach,
      );
    });
    // The link arrives before the session is known; it waits for sign-in.
    tester.binding.platformDispatcher.defaultRouteNameTestValue = inviteLink(
      fromCoach.code,
    );
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );
    await openApp(tester, seeded: seeded);
    await settle(tester);
    expect(find.text('invites you as a coach'), findsOneWidget);
    await tap(tester, find.text('Accept'));
    expect(find.text('Home'), findsWidgets);
  });

  testWidgets('the entry panel stays in view as recorded exercises pile up', (
    tester,
  ) async {
    await openApp(tester);
    await tester.runAsync(
      () => FirestoreProgramRepository(db).save(
        Program(
          id: 'long',
          authorId: 'user-1',
          name: 'Long day',
          days: [
            ProgramDay(
              id: 'd1',
              name: 'Day 1',
              exercises: [
                for (final (index, id) in catalog.keys.take(9).indexed)
                  ProgramExercise(
                    id: 'pe$index',
                    exerciseId: id,
                    sets: const [SetValues(reps: 10, weightKg: 20)],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    await settle(tester);
    await tap(tester, find.text('Long day'));
    await tap(tester, find.text('Start workout'));
    // No scrolling by hand: the button must be under the finger every time.
    for (var recorded = 0; recorded < 9; recorded++) {
      for (final label in ['Continue', 'Continue', 'Record']) {
        final button = find.widgetWithText(FilledButton, label).hitTestable();
        expect(button, findsOneWidget, reason: 'after $recorded recorded');
        await tester.tap(button);
        await settle(tester);
      }
      await settle(tester);
    }
    expect(find.text('Everything is recorded'), findsOneWidget);
  });

  for (final mode in EntryMode.values) {
    testWidgets('selecting and recording cards keeps program order in $mode', (
      tester,
    ) async {
      await openApp(tester);
      final exercises = catalog.values
          .where((e) => e.measure == Measure.reps && !e.usesBodyWeight)
          .take(3)
          .toList();
      await tester.runAsync(
        () => FirestoreProgramRepository(db).save(
          Program(
            id: 'order',
            authorId: 'user-1',
            name: 'Order test',
            days: [
              ProgramDay(
                id: 'day',
                name: 'Day 1',
                exercises: [
                  for (final (i, exercise) in exercises.indexed)
                    ProgramExercise(
                      id: 'pe$i',
                      exerciseId: exercise.id,
                      sets: const [SetValues(reps: 8, weightKg: 20)],
                    ),
                ],
              ),
            ],
          ),
        ),
      );
      await settle(tester);
      await tap(tester, find.text('Order test'));
      await tap(tester, find.text('Start workout'));
      if (mode == EntryMode.perSet) {
        await tap(tester, find.text('Set by set'));
      }
      void expectOrder() {
        final positions = [
          for (final exercise in exercises)
            tester.getTopLeft(find.text(exercise.nameFor('en'))).dy,
        ];
        expect(positions, orderedEquals([...positions]..sort()));
      }

      expectOrder();
      for (final index in [2, 1]) {
        await tap(tester, find.text(exercises[index].nameFor('en')));
        expect(
          find.descendant(
            of: find.byType(EntryPanel),
            matching: find.text(exercises[index].nameFor('en')),
          ),
          findsOneWidget,
        );
        expectOrder();
        if (mode == EntryMode.summary) {
          await record(tester, weight: '7,5');
        } else {
          await tap(tester, find.text('Record set 1'));
        }
        expectOrder();
      }
      final stored = (await onlyWorkout())['exercises'] as List;
      expect(stored.map((e) => e['exerciseId']), exercises.map((e) => e.id));
      expect(stored.first['sets'][0]['fact'], isNull);
      expect(stored[1]['sets'][0]['fact'], isNotNull);
      expect(stored[2]['sets'][0]['fact'], isNotNull);
    });
  }

  /// Saves a program of one day with [exercises], each planned once, and
  /// starts it. Exercises with the same group form a superset.
  Future<void> startPlanned(
    WidgetTester tester,
    List<(Exercise, String?)> exercises, {
    SetValues plan = const SetValues(reps: 8, weightKg: 20),
  }) async {
    await tester.runAsync(
      () => FirestoreProgramRepository(db).save(
        Program(
          id: 'planned',
          authorId: 'user-1',
          name: 'Planned test',
          days: [
            ProgramDay(
              id: 'day',
              name: 'Day 1',
              exercises: [
                for (final (i, (exercise, group)) in exercises.indexed)
                  ProgramExercise(
                    id: 'pe$i',
                    exerciseId: exercise.id,
                    sets: [plan],
                    executionMode: group == null
                        ? ExecutionMode.ordinary
                        : ExecutionMode.superset,
                    groupId: group,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    await settle(tester);
    await tap(tester, find.text('Planned test'));
    await tap(tester, find.text('Start workout'));
  }

  List<Exercise> weighted(int count) => catalog.values
      .where((e) => e.measure == Measure.reps && !e.usesBodyWeight)
      .take(count)
      .toList();

  Finder inPanel(String name) =>
      find.descendant(of: find.byType(EntryPanel), matching: find.text(name));

  testWidgets('a skipped exercise moves on, can be taken back and is counted', (
    tester,
  ) async {
    await openApp(tester);
    final exercises = weighted(3);
    final names = [for (final e in exercises) e.nameFor('en')];
    await startPlanned(tester, [for (final e in exercises) (e, null)]);
    expect(inPanel(names[0]), findsOneWidget);

    await tap(tester, find.text('Skip'));
    var stored = (await onlyWorkout())['exercises'] as List;
    expect(stored.map((e) => e['skipped']), [true, false, false]);
    expect(inPanel(names[1]), findsOneWidget);
    expect(find.text('Skipped'), findsOneWidget);
    expect(
      tester.widget<Barbell>(find.byType(Barbell)).label,
      'Recorded 0 of 3 exercises, 1 skipped',
    );
    expect(tester.widget<Barbell>(find.byType(Barbell)).plates, [
      Plate.skipped,
      Plate.now,
      Plate.waiting,
    ]);

    // Opened again, it can be taken back without recording anything.
    await tap(tester, find.text(names[0]));
    expect(inPanel(names[0]), findsOneWidget);
    await tap(tester, find.text('Undo skip'));
    stored = (await onlyWorkout())['exercises'] as List;
    expect(stored.first['skipped'], isFalse);
    expect(find.text('Skipped'), findsNothing);
    expect(inPanel(names[0]), findsOneWidget);

    await tap(tester, find.text('Skip'));
    await record(tester, weight: '7,5');
    await record(tester, weight: '7,5');
    expect(find.text('Everything is recorded or skipped'), findsOneWidget);
    await tap(tester, find.widgetWithText(FilledButton, 'Finish'));
    expect(find.text('2 of 3'), findsWidgets);
    expect(find.text('Skipped'), findsWidgets);
    expect(find.text(names[0]), findsWidgets);
    await tap(tester, find.widgetWithText(FilledButton, 'Finish').last);
    stored = (await onlyWorkout())['exercises'] as List;
    expect(stored.map((e) => e['skipped']), [true, false, false]);
    expect(stored.first['sets'][0]['plan'], isNotNull);

    await tap(tester, find.text('History'));
    expect(find.text('1 skipped'), findsOneWidget);
  });

  testWidgets('a superset is skipped as a whole from its panel', (
    tester,
  ) async {
    await openApp(tester);
    final exercises = weighted(3);
    await startPlanned(tester, [
      (exercises[0], 'pair'),
      (exercises[1], 'pair'),
      (exercises[2], null),
    ]);
    expect(find.byType(ExecutionEntryPanel), findsOneWidget);
    await tap(tester, find.text('Skip'));
    final stored = (await onlyWorkout())['exercises'] as List;
    expect(stored.map((e) => e['skipped']), [true, true, false]);
    expect(inPanel(exercises[2].nameFor('en')), findsOneWidget);
    expect(find.text('Skipped'), findsNWidgets(2));
  });

  testWidgets('a long press moves a card; the open exercise stays open', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await openApp(tester);
    final exercises = weighted(3);
    final names = [for (final e in exercises) e.nameFor('en')];
    await startPlanned(tester, [for (final e in exercises) (e, null)]);
    final before = [
      for (final e in (await onlyWorkout())['exercises'] as List) e['id'],
    ];

    // The third card is held, then dragged above the second one.
    final from = tester.getCenter(find.text(names[2]));
    final above = tester.getTopLeft(find.text(names[1])).dy;
    final gesture = await tester.startGesture(from);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(
        Offset(from.dx, from.dy + (above - from.dy) * i / 10),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await settle(tester);

    final stored = await onlyWorkout();
    expect((stored['exercises'] as List).map((e) => e['exerciseId']), [
      exercises[0].id,
      exercises[2].id,
      exercises[1].id,
    ]);
    expect(stored['originalOrder'], before);
    expect(inPanel(names[0]), findsOneWidget);
    final positions = [
      for (final name in [names[0], names[2], names[1]])
        tester.getTopLeft(find.text(name)).dy,
    ];
    expect(positions, orderedEquals([...positions]..sort()));

    // The next exercise follows the new order.
    await record(tester, weight: '7,5');
    expect(inPanel(names[2]), findsOneWidget);
  });

  /// A workout of [count] exercises, all recorded, that is longer than the
  /// screen; the workout screen is open on it.
  Future<List<String>> openLongWorkout(WidgetTester tester, int count) async {
    await openApp(tester);
    var n = 0;
    String id() => 'id${n++}';
    final program = Program(
      id: 'long',
      authorId: 'user-1',
      name: 'Long',
      days: [
        ProgramDay(
          id: 'day',
          name: 'Day 1',
          exercises: [
            for (final (i, exercise) in weighted(count).indexed)
              ProgramExercise(
                id: 'pe$i',
                exerciseId: exercise.id,
                sets: const [SetValues(reps: 8, weightKg: 20)],
              ),
          ],
        ),
      ],
    );
    var workout = startWorkout(
      id: 'long-workout',
      traineeId: 'user-1',
      now: DateTime(2026, 11, 15, 18),
      newId: id,
      catalog: catalog,
      languageCode: 'en',
      program: program,
      day: program.days.single,
    );
    for (final exercise in workout.exercises) {
      workout = recordSummary(
        workout,
        exercise.id,
        setCount: 1,
        fact: const SetValues(reps: 8, weightKg: 20),
        newId: id,
        now: workout.startedAt,
      );
    }
    await tester.runAsync(() => FirestoreWorkoutRepository(db).start(workout));
    await settle(tester);
    await tap(tester, find.text('Continue'));
    expect(find.text('Everything is recorded'), findsOneWidget);
    return [for (final e in workout.exercises) e.id];
  }

  ScrollPosition screenScroll(WidgetTester tester) => tester
      .state<ScrollableState>(
        find
            .ancestor(
              of: find.byType(ReorderableList),
              matching: find.byType(Scrollable),
            )
            .first,
      )
      .position;

  testWidgets('a card held still at the edge scrolls on and lands there', (
    tester,
  ) async {
    final ids = await openLongWorkout(tester, 10);
    final screen = screenScroll(tester);
    screen.jumpTo(0);
    await tester.pump();
    final bottom = tester.getBottomLeft(find.byType(Scaffold).last).dy;

    final from = tester.getCenter(
      find.byKey(ValueKey('workout-exercise-${ids.first}')),
    );
    final gesture = await tester.startGesture(from);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    final edge = Offset(from.dx, bottom - 4);
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(Offset.lerp(from, edge, i / 10)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    // The finger stays where it is while the screen scrolls under it.
    for (var i = 0; i < 300; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(screen.pixels, screen.maxScrollExtent);
    await gesture.up();
    await settle(tester);

    final stored = [
      for (final e in (await onlyWorkout())['exercises'] as List) e['id'],
    ];
    expect(stored.indexOf(ids.first), greaterThanOrEqualTo(ids.length - 2));
  });

  testWidgets('a cancelled drag stops scrolling the screen', (tester) async {
    final ids = await openLongWorkout(tester, 10);
    final screen = screenScroll(tester);
    screen.jumpTo(0);
    await tester.pump();
    final bottom = tester.getBottomLeft(find.byType(Scaffold).last).dy;

    final from = tester.getCenter(
      find.byKey(ValueKey('workout-exercise-${ids.first}')),
    );
    final gesture = await tester.startGesture(from);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveTo(Offset(from.dx, bottom - 4));
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.cancel();
    await tester.pump(const Duration(milliseconds: 500));
    final stopped = screen.pixels;
    expect(stopped, lessThan(screen.maxScrollExtent));
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(screen.pixels, stopped);

    // An ordinary touch near the edge afterwards does not scroll either.
    final touch = await tester.startGesture(Offset(from.dx, bottom - 30));
    await touch.moveBy(const Offset(0, 4));
    await tester.pump(const Duration(milliseconds: 500));
    await touch.up();
    await tester.pump(const Duration(milliseconds: 500));
    expect(screen.pixels, closeTo(stopped, 8));
    expect([
      for (final e in (await onlyWorkout())['exercises'] as List) e['id'],
    ], ids);
  });

  testWidgets('a superset panel keeps an order changed while it is open', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openApp(tester);
    final exercises = weighted(3);
    await startPlanned(tester, [
      (exercises[0], 'pair'),
      (exercises[1], 'pair'),
      (exercises[2], null),
    ]);
    expect(find.byType(ExecutionEntryPanel), findsOneWidget);
    final ids = [
      for (final e in (await onlyWorkout())['exercises'] as List)
        e['id'] as String,
    ];

    // A screen reader moves the last exercise to the start.
    final node = tester.getSemantics(
      find.byKey(ValueKey('workout-exercise-${ids[2]}')),
    );
    final action = node.getSemanticsData().customSemanticsActionIds!.firstWhere(
      (id) => CustomSemanticsAction.getAction(id)!.label == 'Move to the start',
    );
    node.owner!.performAction(node.id, SemanticsAction.customAction, action);
    await settle(tester);
    List<String?> order(Map<String, dynamic> workout) => [
      for (final e in workout['exercises'] as List) e['id'] as String?,
    ];
    expect(order(await onlyWorkout()), [ids[2], ids[0], ids[1]]);
    expect(find.byType(ExecutionEntryPanel), findsOneWidget);

    // Recording the superset writes the panel's copy of the workout; the new
    // order stays.
    for (var member = 0; member < 2; member++) {
      if (member == 0) {
        await tap(tester, find.widgetWithText(FilledButton, 'Continue'));
      }
      await tap(tester, find.widgetWithText(FilledButton, 'Continue'));
      await tap(
        tester,
        find.widgetWithText(
          FilledButton,
          member == 0 ? 'Continue' : 'Record superset',
        ),
      );
    }
    final stored = await onlyWorkout();
    expect(order(stored), [ids[2], ids[0], ids[1]]);
    final members = (stored['exercises'] as List).skip(1);
    expect(members.map((e) => e['sets'][0]['fact']), everyElement(isNotNull));
    expect(inPanel(exercises[2].nameFor('en')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a plan starts from the weight lifted last time', (tester) async {
    await openApp(tester);
    final bench = catalog.values.firstWhere(
      (e) => e.nameFor('en').contains('Bench Press'),
    );
    final done = DateTime(2026, 10, 1, 18);
    await tester.runAsync(
      () => db
          .doc('users/user-1/workouts/past')
          .set(
            workoutToMap(
              Workout(
                id: 'past',
                traineeId: 'user-1',
                status: WorkoutStatus.completed,
                startedAt: done,
                completedAt: done,
                exercises: [
                  WorkoutExercise(
                    id: 'we1',
                    exerciseId: bench.id,
                    name: bench.nameFor('en'),
                    measure: bench.measure,
                    usesBodyWeight: false,
                    sets: const [
                      WorkoutSet(
                        id: 's1',
                        fact: SetValues(reps: 8, weightKg: 57.5),
                      ),
                      WorkoutSet(
                        id: 's2',
                        fact: SetValues(reps: 8, weightKg: 57.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
    await settle(tester);
    await tap(tester, find.text('New program'));
    await tester.enterText(find.byType(TextField), 'Strength');
    await settle(tester);
    await tap(tester, find.widgetWithText(OutlinedButton, 'Exercise'));
    await tester.enterText(find.byType(TextField), bench.nameFor('en'));
    await settle(tester);
    // The first match is the search field itself.
    await tap(tester, find.text(bench.nameFor('en')).last);

    expect(find.text('Last time: 2 × 8 × 57.5 kg'), findsOneWidget);
    expect(find.text('57.5 kg', findRichText: true), findsOneWidget);
    await tap(tester, find.text('+5'));
    await tap(tester, find.text('Done'));
    expect(find.text('3 × 10 × 62.5 kg', findRichText: true), findsOneWidget);

    // Touching the number opens the keypad for an exact weight.
    await tap(tester, find.text('3 × 10 × 62.5 kg', findRichText: true));
    expect(find.textContaining('Last time'), findsNothing);
    await tap(tester, find.text('62.5 kg', findRichText: true));
    await tap(tester, find.widgetWithText(PbPill, '6'));
    await tap(tester, find.widgetWithText(PbPill, '1'));
    await tap(tester, find.text('Done'));
    expect(find.text('Note for the trainee'), findsNothing);
    expect(find.text('3 × 10 × 61 kg', findRichText: true), findsOneWidget);
  });

  testWidgets('summary entry finishes an exercise added beyond the plan', (
    tester,
  ) async {
    await openApp(tester);
    final exercises = catalog.values
        .where((e) => e.measure == Measure.reps && !e.usesBodyWeight)
        .take(2)
        .toList();
    await tester.runAsync(
      () => FirestoreProgramRepository(db).save(
        Program(
          id: 'extra-test',
          authorId: 'user-1',
          name: 'Extra exercise test',
          days: [
            ProgramDay(
              id: 'day',
              name: 'Day 1',
              exercises: [
                ProgramExercise(
                  id: 'planned',
                  exerciseId: exercises.first.id,
                  sets: const [SetValues(reps: 8, weightKg: 40)],
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await settle(tester);
    await tap(tester, find.text('Extra exercise test'));
    await tap(tester, find.text('Start workout'));
    await tap(tester, find.text('Add exercise'));
    final extra = exercises.last;
    await tester.enterText(find.byType(TextField), extra.nameFor('en'));
    await settle(tester);
    await tap(tester, find.text(extra.nameFor('en')).last);
    expect(find.text('Outside plan'), findsOneWidget);
    expect(find.text('Recorded'), findsNothing);

    for (var step = 0; step < 2; step++) {
      await tap(tester, find.widgetWithText(FilledButton, 'Continue'));
      final stored = await onlyWorkout();
      expect(stored['exercises'][1]['sets'], isEmpty);
      expect(find.text('0 of 2', findRichText: true), findsOneWidget);
    }
    await typeNumber(tester, '7,5');
    await tap(tester, find.text('Record'));
    expect(find.text('1 of 2', findRichText: true), findsOneWidget);
    expect(find.text('3 × 10 × 7.5 kg', findRichText: true), findsOneWidget);
    expect(find.text('Outside plan'), findsOneWidget);
    expect(find.text('Recorded'), findsOneWidget);
    final stored = await onlyWorkout();
    final planned = stored['exercises'][0]['sets'] as List;
    final added = stored['exercises'][1]['sets'] as List;
    expect(planned.single['plan']['weightKg'], 40);
    expect(planned.single['fact'], isNull);
    expect(added.length, 3);
    expect(added.map((s) => s['plan']), everyElement(isNull));
    expect(added.map((s) => s['fact']['weightKg']), everyElement(7.5));

    // Reopening a recorded extra exercise corrects its result, not the plan.
    await tap(tester, find.text(extra.nameFor('en')));
    await record(tester, sets: '2', count: '12', weight: '5');
    expect(find.text('1 of 2', findRichText: true), findsOneWidget);
    expect(find.text('2 × 12 × 5 kg', findRichText: true), findsOneWidget);
    expect(find.text('Recorded'), findsOneWidget);
    final corrected = (await onlyWorkout())['exercises'] as List;
    expect(corrected.first['sets'], planned);
    expect((corrected.last['sets'] as List).length, 2);
    expect(corrected.last['sets'][0]['fact']['reps'], 12);
  });
  testWidgets(
    'a free superset adds its next exercise directly from execution setup',
    (tester) async {
      await startWithBenchPress(tester);
      final first = (await onlyWorkout())['exercises'][0]['exerciseId'];
      final extra = catalog.values.firstWhere(
        (e) => e.id != first && e.measure == Measure.reps,
      );
      await tap(tester, find.text('Execution style'));
      await tap(tester, find.text('Superset'));
      await tap(tester, find.text('Add exercise to superset'));
      await tester.enterText(find.byType(TextField), extra.nameFor('en'));
      await settle(tester);
      await tap(tester, find.text(extra.nameFor('en')).last);
      await tap(tester, find.widgetWithText(FilledButton, 'Done'));
      expect(find.byType(ExecutionEntryPanel), findsOneWidget);
      final stored = await onlyWorkout();
      final members = stored['exercises'] as List;
      expect(members.length, 2);
      expect(members.map((e) => e['executionMode']), everyElement('superset'));
      expect(members.map((e) => e['groupId']).toSet().length, 1);
      expect(members.map((e) => (e['sets'] as List).length), [3, 3]);
      for (var member = 0; member < 2; member++) {
        if (member == 0) {
          await tap(tester, find.widgetWithText(FilledButton, 'Continue'));
        }
        await tap(tester, find.widgetWithText(FilledButton, 'Continue'));
        await tap(
          tester,
          find.widgetWithText(
            FilledButton,
            member == 0 ? 'Continue' : 'Record superset',
          ),
        );
      }
      expect(find.text('Everything is recorded'), findsOneWidget);
      final restored = await onlyWorkout();
      expect(
        (restored['exercises'] as List).map((e) => e['executionComplete']),
        everyElement(true),
      );
    },
  );
  testWidgets(
    'handle starts before long press and preserves draft and semantics',
    (tester) async {
      await openApp(tester);
      final exercises = weighted(3);
      await startPlanned(tester, [for (final e in exercises) (e, null)]);
      await typeNumber(tester, '2');
      final original = [
        for (final e in (await onlyWorkout())['exercises'] as List)
          e['id'] as String,
      ];
      final handle = find.byKey(ValueKey('workout-drag-handle-${original[2]}'));
      await tester.ensureVisible(handle);
      await tester.pump();
      final size = tester.getSize(handle);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(
        find.byKey(ValueKey('workout-drag-handle-${original[0]}')),
        findsNothing,
      );
      await tester.tap(handle);
      await settle(tester);
      expect((await onlyWorkout())['originalOrder'], isNull);
      expect(inPanel(exercises[0].nameFor('en')), findsOneWidget);
      final semantics = tester.ensureSemantics();
      final node = tester.getSemantics(
        find.byKey(ValueKey('workout-exercise-${original[2]}')),
      );
      expect(node.getSemanticsData().customSemanticsActionIds, isNotEmpty);
      final from = tester.getCenter(handle);
      final target = tester
          .getTopLeft(find.byKey(ValueKey('workout-exercise-${original[1]}')))
          .dy;
      final gesture = await tester.startGesture(from);
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(milliseconds: 20));
      for (var i = 1; i <= 10; i++) {
        await gesture.moveTo(
          Offset(from.dx, from.dy + (target - from.dy) * i / 10),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await settle(tester);
      final saved = await onlyWorkout();
      expect((saved['exercises'] as List).map((e) => e['id']), [
        original[0],
        original[2],
        original[1],
      ]);
      expect(saved['originalOrder'], original);
      await record(tester, weight: '20');
      expect(
        ((await onlyWorkout())['exercises'][0]['sets'] as List)
            .where((s) => s['fact'] != null)
            .length,
        2,
      );
      semantics.dispose();
    },
  );

  testWidgets('immediate handle auto scroll stops on cancel', (tester) async {
    final ids = await openLongWorkout(tester, 10);
    final scroll = screenScroll(tester);
    scroll.jumpTo(0);
    await tester.pump();
    final from = tester.getCenter(
      find.byKey(ValueKey('workout-drag-handle-${ids.first}')),
    );
    final gesture = await tester.startGesture(from);
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.moveTo(
      Offset(from.dx, tester.getBottomLeft(find.byType(Scaffold).last).dy - 4),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(scroll.pixels, greaterThan(0));
    await gesture.cancel();
    await tester.pump(const Duration(milliseconds: 500));
    final stopped = scroll.pixels;
    await tester.pump(const Duration(seconds: 1));
    expect(scroll.pixels, stopped);
  });

  testWidgets('owner comparison travels through entry, history and edit', (
    tester,
  ) async {
    await openApp(tester);
    final exercise = weighted(1).single;
    await startPlanned(tester, [
      (exercise, null),
    ], plan: const SetValues(reps: 12, weightKg: 60));
    await record(tester, count: '10', weight: '80');
    expect(find.text('above plan'), findsOneWidget);
    await tap(tester, find.widgetWithText(FilledButton, 'Finish'));
    await tap(tester, find.widgetWithText(FilledButton, 'Finish').last);
    await tap(tester, find.text('History'));
    expect(find.text('above plan'), findsOneWidget);
    expect(find.text('≈ 106.5 kg vs ≈ 84 kg'), findsOneWidget);
    expect(find.textContaining('below plan'), findsNothing);
    await tap(tester, find.byTooltip('Edit workout'));
    expect(find.text('≈ 106.5 kg vs ≈ 84 kg'), findsOneWidget);
    final saved = await onlyWorkout();
    expect(saved['exercises'][0]['sets'][0]['plan'], {
      'reps': 12,
      'seconds': null,
      'weightKg': 60.0,
    });
  });

  testWidgets('body comparison receives the workout snapshot through labels', (
    tester,
  ) async {
    await openApp(tester);
    final body = catalog.values.firstWhere(
      (e) => e.measure == Measure.reps && e.usesBodyWeight,
    );
    await startPlanned(tester, [(body, null)], plan: const SetValues(reps: 12));
    await profiles.save(
      profiles.profileOf('user-1')!.copyWith(bodyWeightKg: 120),
    );
    await settle(tester);
    await record(tester, count: '6', weight: '10');
    expect(find.text('below plan'), findsOneWidget);
    expect((await onlyWorkout())['bodyWeightKg'], 80);
  });

  testWidgets(
    'order block stays read-only through history editing and discard',
    (tester) async {
      final seeded = FakeFirebaseFirestore();
      final es = weighted(3);
      var n = 0;
      final p = Program(
        id: 'p',
        authorId: 'user-1',
        name: 'P',
        days: [
          ProgramDay(
            id: 'd',
            name: 'D',
            exercises: [
              for (final (i, e) in es.indexed)
                ProgramExercise(
                  id: 'pe$i',
                  exerciseId: e.id,
                  sets: const [SetValues(reps: 8, weightKg: 20)],
                ),
            ],
          ),
        ],
      );
      var w = startWorkout(
        id: 'history-order',
        traineeId: 'user-1',
        now: DateTime.now(),
        newId: () => 'id${n++}',
        catalog: catalog,
        languageCode: 'en',
        program: p,
        day: p.days.single,
      );
      w = moveExerciseGroup(w, 2, 0, now: DateTime.now());
      w = recordSummary(
        w,
        w.exercises[1].id,
        setCount: 1,
        fact: const SetValues(reps: 6, weightKg: 25),
        newId: () => 'extra',
        now: DateTime.now(),
      );
      w = completeWorkout(w, now: DateTime.now());
      await tester.runAsync(() => FirestoreWorkoutRepository(seeded).save(w));
      await openApp(tester, seeded: seeded);
      await tap(tester, find.text('History'));
      expect(find.text('Order changed'), findsOneWidget);
      await tap(tester, find.text('Order changed'));
      expect(find.text('Planned order'), findsOneWidget);
      final snapshot = (await onlyWorkout())['originalOrder'];
      await tap(tester, find.byTooltip('Edit workout'));
      await tap(tester, find.text('Order changed'));
      expect(find.text('Planned order'), findsOneWidget);
      expect(find.byType(ReorderableList), findsNothing);
      await tap(tester, find.text("Don't save"));
      expect((await onlyWorkout())['originalOrder'], snapshot);
    },
  );
  for (final language in ['ru', 'en', 'kk']) {
    for (final theme in [ThemeChoice.light, ThemeChoice.dark]) {
      testWidgets(
        'handles and superset fit $language $theme with text scale 2',
        (tester) async {
          await openApp(tester);
          await profiles.save(
            profiles
                .profileOf('user-1')!
                .copyWith(languageCode: () => language, theme: theme),
          );
          await settle(tester);
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final es = weighted(3);
          // Start through the repository so the check targets the workout layout.
          var n = 0;
          final p = Program(
            id: 'p',
            authorId: 'user-1',
            name: 'P',
            days: [
              ProgramDay(
                id: 'd',
                name: 'D',
                exercises: [
                  for (final (i, e) in es.indexed)
                    ProgramExercise(
                      id: 'pe$i',
                      exerciseId: e.id,
                      sets: const [SetValues(reps: 999, weightKg: 999.75)],
                      executionMode: i > 0
                          ? ExecutionMode.superset
                          : ExecutionMode.ordinary,
                      groupId: i > 0 ? 'pair' : null,
                    ),
                ],
              ),
            ],
          );
          final w = startWorkout(
            id: 'large',
            traineeId: 'user-1',
            now: DateTime.now(),
            newId: () => 'id${n++}',
            catalog: catalog,
            languageCode: language,
            program: p,
            day: p.days.single,
          );
          await tester.runAsync(() => FirestoreWorkoutRepository(db).start(w));
          await settle(tester);
          final l = AppLocalizations.of(
            tester.element(find.byType(HomeScreen)),
          )!;
          await tap(tester, find.text(l.homeContinue));
          expect(
            find.byKey(ValueKey('workout-drag-handle-${w.exercises[1].id}')),
            findsOneWidget,
          );
          expect(
            find.byKey(ValueKey('workout-drag-handle-${w.exercises[2].id}')),
            findsNothing,
          );
          expect(
            find.byKey(ValueKey('workout-drag-handle-${w.exercises[0].id}')),
            findsNothing,
          );
          expect(find.byType(EntryPanel), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
