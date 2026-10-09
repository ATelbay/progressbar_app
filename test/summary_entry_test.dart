import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/features/workout/number_keypad.dart';
import 'package:progressbar_app/features/workout/summary_entry.dart';
import 'package:progressbar_app/l10n/app_localizations.dart';
import 'package:progressbar_app/theme.dart';
import 'package:progressbar_app/widgets/step_button.dart';

void main() {
  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> open(
    WidgetTester tester, {
    required void Function(int, SetValues) onSubmit,
    bool known = false,
    bool timed = false,
    Locale locale = const Locale('en'),
    Brightness brightness = Brightness.dark,
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildTheme(brightness),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(PbSpace.s4),
              child: SummaryEntry(
                setCount: 3,
                values: timed
                    ? const SetValues(seconds: 30)
                    : const SetValues(reps: 10, weightKg: 57.5),
                measure: timed ? Measure.time : Measure.reps,
                usesBodyWeight: false,
                knownPlanningWeight: known,
                submitLabel: 'Save',
                onSubmit: onSubmit,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('one keypad moves the selection; only the last button submits', (
    tester,
  ) async {
    final submissions = <(int, SetValues)>[];
    await open(
      tester,
      onSubmit: (sets, values) => submissions.add((sets, values)),
    );
    expect(find.byType(NumberKeypad), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byTooltip('Decimal point'), findsNothing);
    await tap(tester, find.widgetWithText(PbPill, '4'));
    await tap(tester, find.text('Continue'));
    expect(submissions, isEmpty);
    await tap(tester, find.widgetWithText(PbPill, '8'));
    await tap(tester, find.text('Continue'));
    expect(submissions, isEmpty);
    expect(find.byTooltip('Decimal point'), findsOneWidget);
    for (final key in ['6', '2', ',', '5']) {
      await tap(tester, find.widgetWithText(PbPill, key));
    }
    expect(find.text('62,5 kg', findRichText: true), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);
    await tap(tester, find.text('Save'));
    expect(submissions, [(4, const SetValues(reps: 8, weightKg: 62.5))]);
  });

  testWidgets(
    'known planning weight offers steps; tapping a count opens keys',
    (tester) async {
      SetValues? saved;
      await open(tester, known: true, onSubmit: (_, values) => saved = values);
      expect(find.byType(NumberKeypad), findsNothing);
      await tap(tester, find.text('+0.5'));
      await tap(tester, find.text('−5'));
      await tap(tester, find.byKey(const ValueKey('entry-count')));
      expect(find.text('+0.5'), findsNothing);
      expect(find.byType(NumberKeypad), findsOneWidget);
      await tap(tester, find.widgetWithText(PbPill, '9'));
      await tap(tester, find.text('Continue'));
      await tap(tester, find.text('Save'));
      expect(saved, const SetValues(reps: 9, weightKg: 53));
    },
  );

  for (final locale in ['ru', 'kk']) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '$locale $brightness: large type, fields and keys stay usable',
        (tester) async {
          SetValues? saved;
          await open(
            tester,
            locale: Locale(locale),
            brightness: brightness,
            scale: 2,
            onSubmit: (_, values) => saved = values,
          );
          expect(tester.takeException(), isNull);
          for (final field in ['sets', 'count']) {
            final size = tester.getSize(find.byKey(ValueKey('entry-$field')));
            expect(size.width, greaterThanOrEqualTo(48));
            expect(size.height, greaterThanOrEqualTo(48));
          }
          final l = AppLocalizations.of(
            tester.element(find.byType(SummaryEntry)),
          )!;
          await tap(tester, find.text(l.entryContinue));
          for (final key in ['4', '5']) {
            final finder = find.widgetWithText(PbPill, key);
            final size = tester.getSize(finder);
            expect(size.height, greaterThanOrEqualTo(48));
            await tap(tester, finder);
          }
          await tap(tester, find.text(l.entryContinue));
          await tester.ensureVisible(find.text('Save'));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('entry-weight')).hitTestable(),
            findsOneWidget,
          );
          expect(
            find.widgetWithText(PbPill, '1').hitTestable(),
            findsOneWidget,
          );
          expect(
            find.widgetWithText(PbPill, '0').hitTestable(),
            findsOneWidget,
          );
          await tap(tester, find.text('Save'));
          expect(saved, const SetValues(reps: 45, weightKg: 57.5));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
