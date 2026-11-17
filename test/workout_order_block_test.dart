import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/features/history/workout_order_block.dart';
import 'package:progressbar_app/l10n/app_localizations.dart';
import 'package:progressbar_app/theme.dart';

WorkoutExercise _ex(String id) => WorkoutExercise(
  id: id,
  exerciseId: 'catalog/$id',
  name: 'Exercise $id',
  measure: Measure.reps,
  usesBodyWeight: false,
  executionMode: ExecutionMode.ordinary,
  sets: const [WorkoutSet(id: 's', plan: SetValues(reps: 12, weightKg: 60))],
);

/// Planned order a, b; done as b, a.
Workout _reordered(String id) => Workout(
  id: id,
  traineeId: 'me',
  status: WorkoutStatus.completed,
  startedAt: DateTime(2026, 11, 16),
  exercises: [_ex('b'), _ex('a')],
  originalOrder: const ['a', 'b'],
);

Widget _app(Workout workout) => MaterialApp(
  theme: buildTheme(Brightness.light),
  locale: const Locale('ru'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SingleChildScrollView(child: WorkoutOrderBlock(workout)),
  ),
);

void main() {
  testWidgets('switching to another workout resets the expand label', (
    t,
  ) async {
    await t.pumpWidget(_app(_reordered('first')));
    expect(find.text('Порядок изменён'), findsOneWidget);
    expect(find.text('По плану'), findsOneWidget);

    await t.tap(find.text('Порядок изменён'));
    await t.pumpAndSettle();
    expect(find.text('Свернуть'), findsOneWidget);

    // Same position in the tree, different workout (e.g. «Мои» → «Все»).
    await t.pumpWidget(_app(_reordered('second')));
    await t.pumpAndSettle();
    expect(find.text('Свернуть'), findsNothing);
    expect(find.text('По плану'), findsOneWidget);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);

    // Back to the first one: PageStorage restores it expanded.
    await t.pumpWidget(_app(_reordered('first')));
    await t.pumpAndSettle();
    expect(find.text('Свернуть'), findsOneWidget);
    expect(find.byIcon(Icons.expand_less), findsOneWidget);
  });
}
