import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../execution_widgets.dart';

class ExecutionSetupSheet extends StatefulWidget {
  const ExecutionSetupSheet({
    super.key,
    required this.workout,
    required this.exercise,
    required this.onAdd,
  });
  final Workout workout;
  final WorkoutExercise exercise;
  final Future<WorkoutExercise?> Function() onAdd;
  @override
  State<ExecutionSetupSheet> createState() => _ExecutionSetupSheetState();
}

class _ExecutionSetupSheetState extends State<ExecutionSetupSheet> {
  late ExecutionMode _mode = widget.exercise.executionMode;
  late final Set<String> _ids = {widget.exercise.id};
  late final _available = [...widget.workout.exercises];
  bool _adding = false;
  Future<void> _add() async {
    setState(() => _adding = true);
    final exercise = await widget.onAdd();
    if (!mounted) return;
    setState(() {
      _adding = false;
      if (exercise != null) {
        _available.add(exercise);
        _ids.add(exercise.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!, c = context.pb;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(PbSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: PbSpace.s3,
          children: [
            Text(
              l10n.executionStyle,
              style: PbText.heading.copyWith(color: c.ink),
            ),
            ExecutionSelector(
              value: _mode,
              onChanged: (mode) => setState(() => _mode = mode),
            ),
            if (_mode == ExecutionMode.superset) ...[
              Text(
                l10n.executionChooseMembers,
                style: PbText.bodyStrong.copyWith(color: c.ink),
              ),
              Text(
                widget.exercise.name,
                style: PbText.bodyStrong.copyWith(color: c.ink),
              ),
              for (final e in _available)
                if (e.id != widget.exercise.id &&
                    !e.hasFact &&
                    e.executionMode == ExecutionMode.ordinary)
                  CheckboxListTile(
                    value: _ids.contains(e.id),
                    title: Text(e.name),
                    onChanged: (selected) => setState(() {
                      selected == true ? _ids.add(e.id) : _ids.remove(e.id);
                    }),
                  ),
              if (_ids.length < 2)
                Text(
                  l10n.executionMinMembers,
                  style: PbText.caption.copyWith(color: c.inkMuted),
                ),
              OutlinedButton.icon(
                onPressed: _adding ? null : _add,
                icon: const Icon(Icons.add),
                label: Text(l10n.executionAddMember),
              ),
            ],
            FilledButton(
              onPressed: _mode == ExecutionMode.superset && _ids.length < 2
                  ? null
                  : () => Navigator.pop(context, (
                      _mode,
                      _mode == ExecutionMode.superset
                          ? _ids.toList()
                          : [widget.exercise.id],
                    )),
              child: Text(l10n.welcomeDone),
            ),
          ],
        ),
      ),
    );
  }
}
