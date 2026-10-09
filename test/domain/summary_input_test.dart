import 'package:flutter_test/flutter_test.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/domain/summary_input.dart';

SummaryInput draft({
  bool timed = false,
  SummaryField? active = SummaryField.sets,
}) => SummaryInput(
  setCount: 3,
  count: 10,
  weightKg: 42.5,
  timed: timed,
  active: active,
);

void main() {
  test('sets, reps, weight: only the last advance submits', () {
    final input = draft();
    input.type('2');
    expect(input.advance(), isFalse);
    expect(input.active, SummaryField.count);
    input.type('1');
    input.type('2');
    expect(input.advance(), isFalse);
    expect(input.active, SummaryField.weight);
    for (final key in ['7', ',', '5']) {
      input.type(key);
    }
    expect(input.advance(), isTrue);
    expect(input.setCount, 2);
    expect(input.values, const SetValues(reps: 12, weightKg: 7.5));
  });

  test(
    'suggestions survive advancing without typing, a tap selects any field',
    () {
      final input = draft();
      input.advance();
      input.advance();
      expect(input.advance(), isTrue);
      expect(input.values.weightKg, 42.5);
      input.select(SummaryField.sets);
      input.type('4');
      expect(input.setCount, 4);
      input.select(SummaryField.weight);
      input.type('6');
      input.select(SummaryField.weight);
      input.type('8');
      expect(input.values.weightKg, 8);
    },
  );

  test(
    'empty, zero and excessive counts block advancing; comma is weight only',
    () {
      final input = draft();
      input.erase();
      expect(input.canContinue, isFalse);
      expect(input.advance(), isFalse);
      input.type('0');
      expect(input.canContinue, isFalse);
      input.select(SummaryField.sets);
      input.type('2');
      input.type('1');
      expect(input.canContinue, isFalse);
      input.erase();
      input.type(',');
      expect(input.setCount, 2);
      expect(input.advance(), isFalse);
      input.type('0');
      expect(input.canContinue, isFalse);
      input.select(SummaryField.weight);
      // Skipping an invalid field must not enable the final submit.
      expect(input.canContinue, isFalse);
    },
  );

  test(
    'weights keep existing quarter-kilogram validation, erase can correct them',
    () {
      final input = draft()..select(SummaryField.weight);
      for (final key in ['9', '9', '9', ',', '7', '6']) {
        input.type(key);
      }
      expect(input.canContinue, isFalse);
      input.erase();
      input.type('5');
      expect(input.canContinue, isTrue);
      expect(input.values.weightKg, 999.75);
      input.select(SummaryField.weight);
      input.type(',');
      input.type('2');
      input.type('5');
      expect(input.values.weightKg, 0.25);
    },
  );

  test('timed entry finishes after seconds and stores no extra weight', () {
    final input = draft(timed: true);
    expect(input.advance(), isFalse);
    input.type('4');
    input.type('5');
    expect(input.isLast, isTrue);
    expect(input.advance(), isTrue);
    expect(input.values, const SetValues(seconds: 45));
    input.select(SummaryField.weight);
    expect(input.active, SummaryField.count);
  });

  test('known planning weight has steps until a field opens the keypad', () {
    final input = draft(active: null);
    input.step(0.5);
    input.step(-5);
    expect(input.values.weightKg, 38);
    expect(input.advance(), isTrue);
    input.select(SummaryField.count);
    input.type('8');
    expect(input.advance(), isFalse);
    expect(input.active, SummaryField.weight);
    expect(input.values.reps, 8);
  });
}
