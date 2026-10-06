import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models.dart';
import '../../domain/workout_logic.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/step_button.dart';
import '../workout/entry_panel.dart';
import '../workout/workout_providers.dart';
import 'history_screen.dart';

/// Corrects a completed workout. Changes are kept here until «save»; the
/// stored workout is then marked as edited after completion.
class WorkoutEditScreen extends ConsumerStatefulWidget {
  const WorkoutEditScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  ConsumerState<WorkoutEditScreen> createState() => _WorkoutEditScreenState();
}

class _WorkoutEditScreenState extends ConsumerState<WorkoutEditScreen> {
  /// The corrected copy; null until something is changed.
  Workout? _draft;

  Future<void> _edit(Workout workout, WorkoutExercise exercise) async {
    final newId = ref.read(newIdProvider);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: context.pb.scrim,
      isScrollControlled: true,
      builder: (_) => _EditSheet(
        workout: workout,
        exerciseId: exercise.id,
        newId: newId,
        onChanged: (updated) => setState(() => _draft = updated),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final stored = ref
        .watch(completedWorkoutsProvider)
        .value
        ?.where((w) => w.id == widget.workoutId)
        .firstOrNull;
    final workout = _draft ?? stored;
    if (workout == null) {
      return const Scaffold(
        body: GlowBackground(child: Center(child: CircularProgressIndicator())),
      );
    }
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(PbSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: PbSpace.s3,
              children: [
                Row(
                  spacing: PbSpace.s3,
                  children: [
                    StepButton(
                      icon: Icons.chevron_left,
                      label: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      size: PbSize.touchMin,
                      onTap: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        workoutTitle(context, workout),
                        style: PbText.title.copyWith(color: c.ink),
                      ),
                    ),
                  ],
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.glassStrong,
                    borderRadius: BorderRadius.circular(PbRadius.md),
                    border: Border.all(color: c.warning, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: PbSpace.s3,
                      vertical: PbSpace.s2,
                    ),
                    child: Row(
                      spacing: PbSpace.s2,
                      children: [
                        Icon(Icons.info_outline, color: c.warning),
                        Expanded(
                          child: Text(
                            l10n.editNotice,
                            style: PbText.caption.copyWith(color: c.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: workout.exercises.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: PbSpace.s2),
                    itemBuilder: (context, index) {
                      final exercise = workout.exercises[index];
                      return GlassCard(
                        child: PlanFactRow(
                          exercise,
                          action: StepButton(
                            icon: Icons.edit_outlined,
                            label: l10n.historyEditExercise(exercise.name),
                            size: PbSize.touchMin,
                            onTap: () => _edit(workout, exercise),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                FilledButton(
                  onPressed: _draft == null
                      ? null
                      : () {
                          unawaited(
                            ref.read(workoutRepositoryProvider).save(_draft!),
                          );
                          context.pop();
                        },
                  child: Text(l10n.editSave),
                ),
                OutlinedButton(
                  onPressed: () => context.pop(),
                  child: Text(l10n.editDiscard),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The entry panel in a sheet, working on a copy of the workout.
class _EditSheet extends StatefulWidget {
  const _EditSheet({
    required this.workout,
    required this.exerciseId,
    required this.newId,
    required this.onChanged,
  });

  final Workout workout;
  final String exerciseId;
  final IdGenerator newId;
  final ValueChanged<Workout> onChanged;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late Workout _workout = widget.workout;
  EntryMode _mode = EntryMode.summary;

  void _change(Workout updated, {bool close = false}) {
    widget.onChanged(updated);
    if (close) {
      Navigator.pop(context);
    } else {
      setState(() => _workout = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = _workout.exercises.firstWhere(
      (e) => e.id == widget.exerciseId,
    );
    final now = DateTime.now();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(PbSpace.s2),
        child: SingleChildScrollView(
          child: EntryPanel(
            key: ValueKey((
              _mode,
              exercise.sets.where((s) => s.fact != null).length,
            )),
            workout: _workout,
            exercise: exercise,
            earlier: const [],
            mode: _mode,
            lastSetCount: null,
            onModeChanged: (mode) => setState(() => _mode = mode),
            onRecordSummary: (setCount, fact) => _change(
              recordSummary(
                _workout,
                exercise.id,
                setCount: setCount,
                fact: fact,
                newId: widget.newId,
                now: now,
              ),
              close: true,
            ),
            onRecordSet: (setId, fact, rpe) => _change(
              recordSet(
                _workout,
                exercise.id,
                setId,
                fact: fact,
                rpe: rpe,
                now: now,
              ),
            ),
            onExtraSet: (fact, rpe) => _change(
              addExtraSet(
                _workout,
                exercise.id,
                fact: fact,
                rpe: rpe,
                newId: widget.newId,
                now: now,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
