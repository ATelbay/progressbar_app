import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/summary_input.dart';
import '../../domain/workout_logic.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../widgets/step_button.dart';
import '../format.dart';
import 'number_field.dart';
import 'number_keypad.dart';

/// One numeric draft and one keypad, shared by planning and summary entry.
class SummaryEntry extends StatefulWidget {
  const SummaryEntry({
    super.key,
    required this.setCount,
    required this.values,
    required this.measure,
    required this.usesBodyWeight,
    required this.submitLabel,
    required this.onSubmit,
    this.knownPlanningWeight = false,
    this.hint,
    this.details,
  });

  final int setCount;
  final SetValues values;
  final Measure measure;
  final bool usesBodyWeight;
  final String submitLabel;
  final void Function(int setCount, SetValues values) onSubmit;

  /// Only a known planning weight starts with steps and a closed keypad.
  final bool knownPlanningWeight;
  final Widget? hint;
  final Widget? details;

  @override
  State<SummaryEntry> createState() => _SummaryEntryState();
}

class _SummaryEntryState extends State<SummaryEntry> {
  late final _input = SummaryInput(
    setCount: widget.setCount,
    count: widget.values.reps ?? widget.values.seconds ?? 10,
    weightKg: widget.values.weightKg,
    timed: widget.measure == Measure.time,
    active: widget.knownPlanningWeight ? null : SummaryField.sets,
  );

  void _select(SummaryField field) {
    // A note or the program name must not bring up the native keyboard.
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _input.select(field));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final weightLabel = widget.usesBodyWeight
        ? l10n.entryExtraWeight
        : l10n.entryWeight;
    final typing = _input.active != null;
    Widget field(SummaryField field, String label, {String? unit}) {
      final selected = field == _input.active;
      final numberStyle = field == SummaryField.weight
          ? PbText.numHero
          : PbText.numLg;
      var shown = _input.text(field);
      if (field == SummaryField.weight && !selected) {
        final kg = parseWeight(shown);
        if (kg != null) shown = formatNumber(context, kg);
      }
      return Semantics(
        button: true,
        selected: selected,
        label: label,
        value: unit == null ? shown : '$shown $unit',
        excludeSemantics: true,
        onTap: () => _select(field),
        child: InkWell(
          key: ValueKey('entry-${field.name}'),
          onTap: () => _select(field),
          borderRadius: BorderRadius.circular(PbRadius.sm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: PbSize.touchMin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  label,
                  style: PbText.label.copyWith(
                    color: selected ? c.accentText : c.inkMuted,
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selected ? c.accentText : c.lineStrong,
                        width: selected ? 3 : 1,
                      ),
                    ),
                  ),
                  // Labels follow the system font; the already large numeric
                  // display fits its token height, leaving room for the keypad.
                  child: SizedBox(
                    height: numberStyle.fontSize! * numberStyle.height!,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: NumberValue(
                        value: shown.isEmpty ? '—' : shown,
                        unit: unit,
                        style: numberStyle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PbSpace.s2,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: PbSpace.s3,
          children: [
            Expanded(child: field(SummaryField.sets, l10n.entrySets)),
            Expanded(
              child: field(
                SummaryField.count,
                _input.timed ? l10n.entryTime : l10n.entryReps,
                unit: _input.timed ? l10n.unitSec : null,
              ),
            ),
          ],
        ),
        if (!_input.timed)
          field(SummaryField.weight, weightLabel, unit: l10n.unitKg),
        if (widget.hint != null) widget.hint!,
        if (typing)
          NumberKeypad(
            decimal: _input.active == SummaryField.weight,
            onKey: (key) => setState(() => _input.type(key)),
            onErase: () => setState(_input.erase),
          )
        else ...[
          for (final sign in const [1, -1])
            Row(
              spacing: PbSpace.s2,
              children: [
                for (final kg in planWeightStepsKg)
                  Expanded(
                    child: PbPill(
                      tooltip: sign > 0
                          ? l10n.entryIncrease(weightLabel)
                          : l10n.entryDecrease(weightLabel),
                      onTap: () => setState(() => _input.step(sign * kg)),
                      child: Text(
                        '${sign > 0 ? '+' : '−'}${formatNumber(context, kg)}',
                      ),
                    ),
                  ),
              ],
            ),
          if (widget.details != null) widget.details!,
        ],
        FilledButton(
          onPressed: !_input.canContinue
              ? null
              : () {
                  if (_input.advance()) {
                    widget.onSubmit(_input.setCount, _input.values);
                  } else {
                    setState(() {});
                  }
                },
          child: Text(_input.isLast ? widget.submitLabel : l10n.entryContinue),
        ),
      ],
    );
  }
}
