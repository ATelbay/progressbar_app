import 'package:flutter/material.dart';

import '../../domain/exercise_catalog.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../widgets/sheet.dart';
import '../../widgets/step_button.dart';
import 'exercise_picker_screen.dart';

/// What the sheet returns: the exercise to store, or a request to drop the
/// user's edit of a built-in one.
typedef ExerciseEdit = ({Exercise? exercise, bool restore});

/// Creates the user's own exercise or changes an existing one. The name is
/// edited in the interface language; other languages keep theirs.
class ExerciseEditSheet extends StatefulWidget {
  const ExerciseEditSheet({
    super.key,
    required this.ownerId,
    required this.newId,
    this.exercise,
  });

  final String ownerId;

  /// ID for a new exercise.
  final String newId;
  final Exercise? exercise;

  @override
  State<ExerciseEditSheet> createState() => _ExerciseEditSheetState();
}

class _ExerciseEditSheetState extends State<ExerciseEditSheet> {
  late final _name = TextEditingController();
  late MuscleArea _area =
      areaOf(widget.exercise?.muscleGroup ?? '') ?? MuscleArea.chest;
  late Measure _measure = widget.exercise?.measure ?? Measure.reps;
  late bool _bodyWeight = widget.exercise?.usesBodyWeight ?? false;
  bool _named = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_named) return;
    _named = true;
    _name.text =
        widget.exercise?.nameFor(
          Localizations.localeOf(context).languageCode,
        ) ??
        '';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final old = widget.exercise;
    final language = Localizations.localeOf(context).languageCode;
    Navigator.pop<ExerciseEdit>(context, (
      exercise: Exercise(
        id: old?.id ?? '$customExercisePrefix${widget.newId}',
        names: {...?old?.names, language: name},
        // Keeps the exact group of a built-in exercise unless the area moved.
        muscleGroup: old != null && areaOf(old.muscleGroup) == _area
            ? old.muscleGroup
            : muscleGroupFor(_area),
        equipment: old?.equipment,
        measure: _measure,
        usesBodyWeight: _bodyWeight,
        ownerId: widget.ownerId,
      ),
      restore: false,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final old = widget.exercise;
    final label = PbText.label.copyWith(color: c.inkMuted);
    return PbSheet(
      children: [
        TextField(
          controller: _name,
          autofocus: old == null,
          textCapitalization: TextCapitalization.sentences,
          style: PbText.heading.copyWith(color: c.ink),
          decoration: InputDecoration(labelText: l10n.exerciseName),
          onChanged: (_) => setState(() {}),
        ),
        Wrap(
          spacing: PbSpace.s2,
          runSpacing: PbSpace.s2,
          children: [
            for (final area in MuscleArea.values)
              PbPill(
                selected: _area == area,
                onTap: () => setState(() => _area = area),
                child: Text(areaName(l10n, area)),
              ),
          ],
        ),
        Text(l10n.exerciseMeasure, style: label),
        Row(
          spacing: PbSpace.s2,
          children: [
            for (final (measure, name) in [
              (Measure.reps, l10n.entryReps),
              (Measure.time, l10n.entryTime),
            ])
              Expanded(
                child: PbPill(
                  selected: _measure == measure,
                  onTap: () => setState(() => _measure = measure),
                  child: Text(name),
                ),
              ),
          ],
        ),
        SwitchListTile.adaptive(
          value: _bodyWeight,
          onChanged: (value) => setState(() => _bodyWeight = value),
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.exerciseBodyWeight,
            style: PbText.bodyStrong.copyWith(color: c.ink),
          ),
          subtitle: Text(
            l10n.exerciseBodyWeightHint,
            style: PbText.caption.copyWith(color: c.inkMuted),
          ),
        ),
        FilledButton(
          onPressed: _name.text.trim().isEmpty ? null : _save,
          child: Text(l10n.exerciseSave),
        ),
        if (old != null && old.ownerId != null && isBuiltInExercise(old.id))
          TextButton(
            onPressed: () => Navigator.pop<ExerciseEdit>(context, (
              exercise: null,
              restore: true,
            )),
            child: Text(l10n.exerciseRestore),
          ),
      ],
    );
  }
}
