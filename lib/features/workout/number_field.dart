import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../widgets/step_button.dart';

class NumberValue extends StatelessWidget {
  const NumberValue({
    super.key,
    required this.value,
    required this.style,
    this.unit,
    this.muted = false,
  });

  final String value;
  final String? unit;
  final TextStyle style;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.pb;
    return Text.rich(
      TextSpan(
        text: value,
        children: [
          if (unit != null)
            TextSpan(
              text: ' $unit',
              style: PbText.numMd.copyWith(color: c.inkMuted),
            ),
        ],
      ),
      style: style.copyWith(color: muted ? c.inkMuted : c.ink),
    );
  }
}

/// A labelled number with «minus» and «plus» next to it.
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.label,
    required this.value,
    required this.style,
    required this.onStep,
    this.unit,
    this.onTapValue,
  });

  final String label;
  final String value;
  final String? unit;
  final TextStyle style;
  final ValueChanged<int> onStep;

  /// Opens the keypad; only weight has one.
  final VoidCallback? onTapValue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    // Shrinks to stay on one line at large system font sizes.
    final number = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.bottomLeft,
      child: NumberValue(value: value, unit: unit, style: style),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: PbText.label.copyWith(color: c.inkMuted)),
              if (onTapValue == null)
                number
              else
                Semantics(
                  button: true,
                  child: InkWell(
                    onTap: onTapValue,
                    borderRadius: BorderRadius.circular(PbRadius.sm),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: PbSize.touchMin,
                        minHeight: PbSize.touchMin,
                      ),
                      child: number,
                    ),
                  ),
                ),
            ],
          ),
        ),
        StepButton(
          icon: Icons.remove,
          label: l10n.entryDecrease(label),
          onTap: () => onStep(-1),
        ),
        const SizedBox(width: PbSpace.s2),
        StepButton(
          icon: Icons.add,
          label: l10n.entryIncrease(label),
          onTap: () => onStep(1),
        ),
      ],
    );
  }
}
