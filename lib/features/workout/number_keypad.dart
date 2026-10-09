import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../widgets/step_button.dart';

/// The same custom numeric keys for counts and weight; no system keyboard.
class NumberKeypad extends StatelessWidget {
  const NumberKeypad({
    super.key,
    required this.decimal,
    required this.onKey,
    required this.onErase,
  });

  final bool decimal;
  final ValueChanged<String> onKey;
  final VoidCallback onErase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Like a system numeric keyboard, keys keep their touch size at large
    // text settings so the active value and all four rows fit together.
    Widget key({
      required Widget child,
      required VoidCallback onTap,
      String? tooltip,
    }) => SizedBox(
      height: PbSize.touchMin,
      child: PbPill(
        tooltip: tooltip,
        onTap: onTap,
        child: FittedBox(fit: BoxFit.scaleDown, child: child),
      ),
    );
    Widget digit(String value) => key(
      onTap: () => onKey(value),
      child: Text(value, style: PbText.numMd),
    );
    return Column(
      spacing: PbSpace.s2,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            spacing: PbSpace.s2,
            children: [for (final key in row) Expanded(child: digit(key))],
          ),
        Row(
          spacing: PbSpace.s2,
          children: [
            Expanded(
              child: decimal
                  ? key(
                      tooltip: l10n.keyComma,
                      onTap: () => onKey(','),
                      child: Text(',', style: PbText.numMd),
                    )
                  : const SizedBox(),
            ),
            Expanded(child: digit('0')),
            Expanded(
              child: key(
                tooltip: l10n.keyErase,
                onTap: onErase,
                child: const Icon(Icons.backspace_outlined),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
