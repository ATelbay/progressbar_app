import 'package:flutter/material.dart';

import '../../domain/workout_logic.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../widgets/step_button.dart';
import '../format.dart';
import 'number_field.dart';
import 'number_keypad.dart';

/// Types a weight exactly: digits, a comma and quick additions. Takes the
/// place of the fields it is opened from until «done».
class WeightKeypad extends StatefulWidget {
  const WeightKeypad({
    super.key,
    required this.label,
    required this.weightKg,
    required this.onDone,
    this.quickAdd = const [2.5, 5.0, 10.0],
  });

  final String label;

  /// The weight before typing, shown until a key is pressed; null when there
  /// is none yet.
  final double? weightKg;
  final List<double> quickAdd;

  /// The typed weight; null when «done» is pressed with nothing typed.
  final ValueChanged<double?> onDone;

  @override
  State<WeightKeypad> createState() => _WeightKeypadState();
}

class _WeightKeypadState extends State<WeightKeypad> {
  String _typed = '';

  void _type(String key) => setState(() {
    if (key == ',' && _typed.contains(',')) return;
    if (_typed.length < 6) _typed += key;
  });

  void _add(double kg) => setState(() {
    final sum = stepWeight(parseWeight(_typed) ?? widget.weightKg ?? 0, kg);
    _typed = formatNumber(context, sum).replaceAll('.', ',');
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final shown = _typed.isEmpty
        ? formatNumber(context, widget.weightKg ?? 0)
        : _typed;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PbSpace.s2,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          runSpacing: PbSpace.s2,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: PbText.label.copyWith(color: c.inkMuted),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: c.accentText, width: 3),
                    ),
                  ),
                  child: NumberValue(
                    value: shown,
                    unit: l10n.unitKg,
                    style: PbText.numHero,
                    muted: _typed.isEmpty,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: PbSpace.s2,
              children: [
                for (final kg in widget.quickAdd)
                  PbPill(
                    onTap: () => _add(kg),
                    child: Text('+${formatNumber(context, kg)}'),
                  ),
              ],
            ),
          ],
        ),
        NumberKeypad(
          decimal: true,
          onKey: _type,
          onErase: () => setState(() {
            if (_typed.isNotEmpty) {
              _typed = _typed.substring(0, _typed.length - 1);
            }
          }),
        ),
        FilledButton(
          onPressed: _typed.isEmpty
              ? () => widget.onDone(null)
              : parseWeight(_typed) == null
              ? null
              : () => widget.onDone(parseWeight(_typed)),
          child: Text(l10n.welcomeDone),
        ),
      ],
    );
  }
}
