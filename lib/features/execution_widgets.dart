import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';

String executionLabel(AppLocalizations l10n, ExecutionMode mode) =>
    switch (mode) {
      ExecutionMode.ordinary => l10n.executionOrdinary,
      ExecutionMode.superset => l10n.executionSuperset,
      ExecutionMode.dropSet => l10n.executionDropSet,
    };

class ExecutionSelector extends StatelessWidget {
  const ExecutionSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final ExecutionMode value;
  final ValueChanged<ExecutionMode> onChanged;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (MediaQuery.textScalerOf(context).scale(1) > 1.35) {
      return DropdownButton<ExecutionMode>(
        value: value,
        isExpanded: true,
        itemHeight: null,
        items: [
          for (final mode in ExecutionMode.values)
            DropdownMenuItem(
              value: mode,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: PbSize.touchMin),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(executionLabel(l10n, mode)),
                ),
              ),
            ),
        ],
        onChanged: (mode) {
          if (mode != null) onChanged(mode);
        },
      );
    }
    return SegmentedButton<ExecutionMode>(
      showSelectedIcon: false,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, PbSize.touchMin)),
        textStyle: WidgetStatePropertyAll(PbText.label),
      ),
      segments: [
        for (final mode in ExecutionMode.values)
          ButtonSegment(value: mode, label: Text(executionLabel(l10n, mode))),
      ],
      selected: {value},
      onSelectionChanged: (selected) => onChanged(selected.single),
    );
  }
}

class EntryModeSelector extends StatelessWidget {
  const EntryModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.canSummary,
  });
  final EntryMode value;
  final ValueChanged<EntryMode> onChanged;
  final bool canSummary;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String label(EntryMode mode) => mode == EntryMode.summary
        ? l10n.entrySummaryOnly
        : l10n.entryModePerSet;
    if (MediaQuery.textScalerOf(context).scale(1) > 1.35) {
      return DropdownButton<EntryMode>(
        value: value,
        isExpanded: true,
        itemHeight: null,
        items: [
          for (final mode in EntryMode.values)
            DropdownMenuItem(
              value: mode,
              enabled: mode != EntryMode.summary || canSummary,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: PbSize.touchMin),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(label(mode)),
                ),
              ),
            ),
        ],
        onChanged: (mode) {
          if (mode != null) onChanged(mode);
        },
      );
    }
    return SegmentedButton<EntryMode>(
      showSelectedIcon: false,
      segments: [
        for (final mode in EntryMode.values)
          ButtonSegment(
            value: mode,
            label: Text(label(mode)),
            enabled: mode != EntryMode.summary || canSummary,
          ),
      ],
      selected: {value},
      onSelectionChanged: (values) => onChanged(values.single),
    );
  }
}
