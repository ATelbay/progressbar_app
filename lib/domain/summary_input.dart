import 'models.dart';
import 'workout_logic.dart';

enum SummaryField { sets, count, weight }

/// A local numeric draft. Moving between fields never records a result.
/// Each field's first digit replaces its suggestion; subsequent digits append.
class SummaryInput {
  SummaryInput({
    required int setCount,
    required int count,
    required double? weightKg,
    required this.timed,
    this.active = SummaryField.sets,
  }) : _text = {
         SummaryField.sets: '$setCount',
         SummaryField.count: '$count',
         SummaryField.weight: _weightText(weightKg ?? 0),
       };

  final bool timed;
  final Map<SummaryField, String> _text;
  SummaryField? active;
  bool _replace = true;

  String text(SummaryField field) => _text[field]!;
  int get setCount => int.parse(text(SummaryField.sets));
  SetValues get values => timed
      ? SetValues(seconds: int.parse(text(SummaryField.count)))
      : SetValues(
          reps: int.parse(text(SummaryField.count)),
          weightKg: parseWeight(text(SummaryField.weight))!,
        );

  bool get isLast =>
      active == null ||
      active == (timed ? SummaryField.count : SummaryField.weight);

  bool _valid(SummaryField field) {
    final value = text(field);
    if (field == SummaryField.weight) return parseWeight(value) != null;
    final number = int.tryParse(value);
    return number != null &&
        number >= 1 &&
        number <= (field == SummaryField.sets ? 20 : 999);
  }

  bool get canContinue => isLast
      ? _valid(SummaryField.sets) &&
            _valid(SummaryField.count) &&
            (timed || _valid(SummaryField.weight))
      : _valid(active!);

  void select(SummaryField field) {
    if (timed && field == SummaryField.weight) return;
    active = field;
    _replace = true;
  }

  void type(String key) {
    final field = active;
    if (field == null) return;
    final decimal = key == ',' || key == '.';
    if (decimal && field != SummaryField.weight) return;
    if (!decimal && !RegExp(r'^\d$').hasMatch(key)) return;
    var value = _replace ? '' : text(field);
    if (decimal) {
      if (value.contains(',')) return;
      value = value.isEmpty ? '0,' : '$value,';
    } else {
      final limit = switch (field) {
        SummaryField.sets => 2,
        SummaryField.count => 3,
        SummaryField.weight => 6,
      };
      if (value.length >= limit) return;
      value += key;
    }
    _text[field] = value;
    _replace = false;
  }

  void erase() {
    final field = active;
    if (field == null) return;
    final value = text(field);
    _text[field] = value.isEmpty ? '' : value.substring(0, value.length - 1);
    _replace = false;
  }

  /// True only when the whole draft is ready to submit on its final field.
  bool advance() {
    if (!canContinue) return false;
    if (isLast) return true;
    select(
      active == SummaryField.sets ? SummaryField.count : SummaryField.weight,
    );
    return false;
  }

  /// Used only by the planning buttons when a starting weight is known.
  void step(double by) {
    final kg = stepWeight(parseWeight(text(SummaryField.weight)) ?? 0, by);
    _text[SummaryField.weight] = _weightText(kg);
  }

  static String _weightText(double kg) => kg == kg.roundToDouble()
      ? kg.toInt().toString()
      : kg.toString().replaceAll('.', ',');
}
