import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/domain/workout_logic.dart';
import 'package:progressbar_app/features/workout/execution_entry_panel.dart';
import 'package:progressbar_app/features/program/execution_plan_sheet.dart';
import 'package:progressbar_app/features/workout/summary_entry.dart';
import 'package:progressbar_app/features/workout/number_keypad.dart';
import 'package:progressbar_app/l10n/app_localizations.dart';
import 'package:progressbar_app/theme.dart';
import 'package:progressbar_app/widgets/step_button.dart';

const catalog = {
  'a': Exercise(
    id: 'a',
    names: {'en': 'Lunges', 'ru': 'Выпады', 'kk': 'Алға адымдау'},
    muscleGroup: 'legs',
  ),
  'b': Exercise(
    id: 'b',
    names: {'en': 'Squats', 'ru': 'Приседания', 'kk': 'Отырып-тұру'},
    muscleGroup: 'legs',
  ),
};
const initial = SetValues(reps: 10, weightKg: 60);
const lower = SetValues(reps: 8, weightKg: 45);
void main() {
  var id = 0;
  String newId() => 'id${id++}';
  Workout workout(ExecutionMode mode, {int rounds = 2}) => startWorkout(
    id: 'w',
    traineeId: 'me',
    now: DateTime(2026, 10, 13),
    newId: newId,
    catalog: catalog,
    languageCode: 'en',
    day: ProgramDay(
      id: 'd',
      name: 'Day',
      exercises: [
        for (final key in mode == ExecutionMode.superset ? ['a', 'b'] : ['a'])
          ProgramExercise(
            id: key,
            exerciseId: key,
            sets: List.filled(rounds, initial),
            executionMode: mode,
            groupId: mode == ExecutionMode.superset ? 'group' : null,
            dropStages: mode == ExecutionMode.dropSet ? [lower] : const [],
          ),
      ],
    ),
  );
  Future<void> tap(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.pump();
    await t.tap(f);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }

  Future<void> type(WidgetTester t, String text) async {
    for (final digit in text.split('')) {
      await tap(
        t,
        find.descendant(
          of: find.byType(NumberKeypad),
          matching: find.widgetWithText(PbPill, digit),
        ),
      );
    }
  }

  Future<void> next(WidgetTester t) async =>
      tap(t, find.byType(FilledButton).last);
  Future<void> values(WidgetTester t, {String? reps, String? weight}) async {
    if (reps != null) await type(t, reps);
    await next(t);
    if (weight != null) await type(t, weight);
  }

  Widget app(
    Widget child, {
    String language = 'en',
    double scale = 1,
    Brightness brightness = Brightness.dark,
  }) => MaterialApp(
    locale: Locale(language),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildTheme(brightness),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  Future<void> open(
    WidgetTester t,
    Widget child, {
    String language = 'en',
    double scale = 1,
    Brightness brightness = Brightness.dark,
  }) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      app(child, language: language, scale: scale, brightness: brightness),
    );
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }

  testWidgets(
    'summary superset saves the whole group only at the last member',
    (t) async {
      final w = workout(ExecutionMode.superset);
      final saves = <Workout>[];
      var finished = 0;
      await open(
        t,
        ExecutionEntryPanel(
          workout: w,
          exerciseId: w.exercises.first.id,
          mode: EntryMode.summary,
          newId: newId,
          onChanged: saves.add,
          onModeChanged: (_) {},
          onFinished: () => finished++,
        ),
      );
      await type(t, '1');
      await next(t);
      await values(t, reps: '12', weight: '20');
      await next(t);
      expect(saves, isEmpty);
      expect(find.text('Exercise 2 of 2'), findsWidgets);
      expect(find.byKey(const ValueKey('entry-sets')), findsNothing);
      await values(t, reps: '8', weight: '50');
      await tap(t, find.text('Record superset'));
      expect(finished, 1);
      expect(saves.single.exercises.first.sets.first.fact!.weightKg, 20);
      expect(saves.single.exercises.last.sets.first.fact!.reps, 8);
      expect(saves.single.exercises.last.sets.last.fact, isNull);
      expect(nextExercise(saves.single), isNull);
    },
  );
  testWidgets(
    'full superset proceeds A1 B1 A2 B2 and saves each finished set',
    (t) async {
      final w = workout(ExecutionMode.superset);
      final saves = <Workout>[];
      var finished = 0;
      await open(
        t,
        ExecutionEntryPanel(
          workout: w,
          exerciseId: w.exercises.first.id,
          mode: EntryMode.perSet,
          newId: newId,
          onChanged: saves.add,
          onModeChanged: (_) {},
          onFinished: () => finished++,
        ),
      );
      for (var i = 0; i < 4; i++) {
        expect(find.text('Exercise ${i.isEven ? 1 : 2} of 2'), findsOneWidget);
        expect(find.text('Round ${i ~/ 2 + 1} of 2'), findsOneWidget);
        await values(t, weight: '${20 + i}');
        await next(t);
        expect(saves.length, i + 1);
      }
      expect(finished, 1);
      expect(saves.last.exercises.first.sets.map((s) => s.fact!.weightKg), [
        20,
        22,
      ]);
      expect(saves.last.exercises.last.sets.map((s) => s.fact!.weightKg), [
        21,
        23,
      ]);
    },
  );
  testWidgets('full drop entry persists stages, resumes and adds a reduction', (
    t,
  ) async {
    final w = workout(ExecutionMode.dropSet, rounds: 1);
    final saves = <Workout>[];
    var finished = 0;
    Widget panel(Workout source) => ExecutionEntryPanel(
      key: ValueKey(source),
      workout: source,
      exerciseId: source.exercises.first.id,
      mode: EntryMode.perSet,
      newId: newId,
      onChanged: saves.add,
      onModeChanged: (_) {},
      onFinished: () => finished++,
    );
    await open(t, panel(w));
    await values(t);
    await next(t);
    expect(saves.single.exercises.single.sets.single.fact, initial);
    await t.pumpWidget(app(panel(saves.single)));
    await t.pumpAndSettle();
    expect(find.text('Reduction 1'), findsWidgets);
    await values(t, reps: '8', weight: '44');
    await tap(t, find.byKey(const ValueKey('execution-controls')));
    await tap(t, find.text('Add reduction'));
    expect(
      saves.last.exercises.single.sets.single.drops.single.fact,
      const SetValues(reps: 8, weightKg: 44),
    );
    await values(t, reps: '6', weight: '30');
    await tap(t, find.text('Record drop set'));
    final result = saves.last.exercises.single.sets.single;
    expect(result.drops.map((d) => d.fact!.weightKg), [44, 30]);
    expect(result.dropComplete, isTrue);
    expect(result.drops.last.plan, isNull);
    expect(finished, 1);
  });
  testWidgets('drop summary expands stages into equal logical sets', (t) async {
    final w = workout(ExecutionMode.dropSet);
    final saves = <Workout>[];
    await open(
      t,
      ExecutionEntryPanel(
        workout: w,
        exerciseId: w.exercises.first.id,
        mode: EntryMode.summary,
        newId: newId,
        onChanged: saves.add,
        onModeChanged: (_) {},
        onFinished: () {},
      ),
    );
    await type(t, '3');
    await next(t);
    await values(t);
    await next(t);
    expect(saves, isEmpty);
    await values(t);
    await tap(t, find.text('Record drop sets'));
    expect(saves.single.exercises.single.sets.length, 3);
    expect(
      saves.single.exercises.single.sets.map((s) => s.drops.single.fact),
      everyElement(lower),
    );
  });
  testWidgets('finishing a drop early preserves missing planned stages', (
    t,
  ) async {
    final w = workout(ExecutionMode.dropSet, rounds: 1);
    Workout? saved;
    await open(
      t,
      ExecutionEntryPanel(
        workout: w,
        exerciseId: w.exercises.first.id,
        mode: EntryMode.perSet,
        newId: newId,
        onChanged: (v) => saved = v,
        onModeChanged: (_) {},
        onFinished: () {},
      ),
    );
    await values(t, reps: '13', weight: '55');
    await tap(t, find.byKey(const ValueKey('execution-controls')));
    await tap(t, find.text('Finish set here'));
    expect(
      saved!.exercises.single.sets.single.fact,
      const SetValues(reps: 13, weightKg: 55),
    );
    expect(saved!.exercises.single.sets.single.dropComplete, isTrue);
    expect(saved!.exercises.single.sets.single.drops.single.plan, lower);
    expect(saved!.exercises.single.sets.single.drops.single.fact, isNull);
  });
  testWidgets('jumping to the last member still visits unfilled members', (
    t,
  ) async {
    final w = workout(ExecutionMode.superset);
    final saves = <Workout>[];
    await open(
      t,
      ExecutionEntryPanel(
        workout: w,
        exerciseId: w.exercises.first.id,
        mode: EntryMode.summary,
        newId: newId,
        onChanged: saves.add,
        onModeChanged: (_) {},
        onFinished: () {},
      ),
    );
    await tap(t, find.byKey(const ValueKey('execution-controls')));
    await tap(t, find.widgetWithText(ListTile, 'Squats'));
    await values(t);
    await next(t);
    expect(saves, isEmpty);
    expect(find.text('Exercise 1 of 2'), findsWidgets);
  });
  testWidgets('controls preserve the numeric draft and effort without saving', (
    t,
  ) async {
    final w = workout(ExecutionMode.superset);
    final saves = <Workout>[];
    await open(
      t,
      ExecutionEntryPanel(
        workout: w,
        exerciseId: w.exercises.first.id,
        mode: EntryMode.perSet,
        newId: newId,
        onChanged: saves.add,
        onModeChanged: (_) {},
        onFinished: () {},
      ),
    );
    await values(t, reps: '13', weight: '42');
    await tap(t, find.byKey(const ValueKey('execution-controls')));
    await tap(t, find.widgetWithText(ListTile, 'Lunges'));
    expect(saves, isEmpty);
    await tap(t, find.byKey(const ValueKey('execution-controls')));
    await tap(t, find.text('Some left'));
    expect(saves, isEmpty);
    await tap(t, find.byKey(const ValueKey('execution-controls')));
    await tap(t, find.text('Continue entry'));
    expect(saves, isEmpty);
    await next(t);
    final set = saves.single.exercises.first.sets.first;
    expect(set.fact, const SetValues(reps: 13, weightKg: 42));
    expect(set.rpe, Effort.some.rpe);
  });
  for (final language in ['ru', 'en', 'kk']) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '$language $brightness large text: styles and full drop input fit',
        (t) async {
          final w = workout(ExecutionMode.dropSet, rounds: 1);
          await open(
            t,
            ExecutionEntryPanel(
              workout: w,
              exerciseId: w.exercises.first.id,
              mode: EntryMode.perSet,
              newId: newId,
              onChanged: (_) {},
              onModeChanged: (_) {},
              onFinished: () {},
            ),
            language: language,
            scale: 2,
            brightness: brightness,
          );
          await values(t);
          expect(t.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('plan sheet builds a drop template with a separate reduction', (
    t,
  ) async {
    ExecutionPlanResult? result;
    await open(
      t,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await showModalBottomSheet<ExecutionPlanResult>(
              context: context,
              isScrollControlled: true,
              builder: (_) => ExecutionPlanSheet(
                exercise: catalog['a']!,
                initial: const [],
                catalog: catalog,
                newId: newId,
                onPick: () async => catalog['b'],
                earlier: const [],
              ),
            );
          },
          child: const Text('Open'),
        ),
      ),
    );
    await tap(t, find.text('Open'));
    await tap(t, find.text('Drop set'));
    await type(t, '3');
    await next(t);
    await values(t, reps: '10', weight: '60');
    await tap(t, find.text('Add reduction'));
    await values(t, reps: '8', weight: '45');
    await tap(t, find.text('Done'));
    expect(result!.members.single.executionMode, ExecutionMode.dropSet);
    expect(result!.members.single.sets, [initial, initial, initial]);
    expect(result!.members.single.dropStages, [lower]);
    expect(find.byType(SummaryEntry), findsNothing);
  });
  testWidgets('plan sheet groups exercises and keeps individual loads', (
    t,
  ) async {
    ExecutionPlanResult? result;
    await open(
      t,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await showModalBottomSheet<ExecutionPlanResult>(
              context: context,
              isScrollControlled: true,
              builder: (_) => ExecutionPlanSheet(
                exercise: catalog['a']!,
                initial: const [],
                catalog: catalog,
                newId: newId,
                onPick: () async => catalog['b'],
                earlier: const [],
              ),
            );
          },
          child: const Text('Open'),
        ),
      ),
    );
    await tap(t, find.text('Open'));
    await tap(t, find.text('Superset'));
    await tap(t, find.text('Add exercise to superset'));
    await type(t, '2');
    await next(t);
    await values(t, reps: '12', weight: '20');
    await next(t);
    await values(t, reps: '8', weight: '50');
    await tap(t, find.text('Done'));
    expect(result!.members.length, 2);
    expect(result!.members.map((m) => m.groupId).toSet().length, 1);
    expect(result!.members.first.sets.first.weightKg, 20);
    expect(result!.members.last.sets.first.weightKg, 50);
  });
}
