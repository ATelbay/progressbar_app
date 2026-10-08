import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models.dart';
import '../../domain/workout_logic.dart';
import '../../l10n/app_localizations.dart';
import '../../router.dart';
import '../../theme.dart';
import '../../widgets/barbell.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glow_background.dart';
import '../auth/auth_controller.dart';
import '../format.dart';
import '../storage_status_providers.dart';
import 'entry_panel.dart';
import 'workout_day_button.dart';
import 'workout_providers.dart';

/// Plates for the workout's exercises: done, the one being recorded, waiting.
List<Plate> platesOf(Workout workout, {String? currentId}) => [
  for (final exercise in workout.exercises)
    exercise.id == currentId
        ? Plate.now
        : exercise.hasFact
        ? Plate.done
        : Plate.waiting,
];

enum _Finish { complete, cancel }

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  final _panelKey = GlobalKey();
  Object? _followed;

  /// Recorded exercises pile up above the entry panel and push it down. When
  /// what is being entered changes, the screen scrolls so that the panel and
  /// its «record» button are in view again.
  void _followPanel(Object entering) {
    if (entering == _followed) return;
    _followed = entering;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final panel = _panelKey.currentContext;
      if (panel == null || !panel.mounted) return;
      Scrollable.ensureVisible(
        panel,
        duration: MediaQuery.disableAnimationsOf(panel)
            ? Duration.zero
            : const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  /// An exercise the user picked themselves; otherwise the next unrecorded.
  String? _pickedId;
  EntryMode? _mode;

  DateTime get _now => DateTime.now();

  void _save(Workout workout) =>
      unawaited(ref.read(workoutRepositoryProvider).save(workout));

  /// The profile remembers the entry mode and the last number of sets.
  void _remember({EntryMode? mode, int? setCount}) {
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;
    unawaited(
      ref
          .read(profileRepositoryProvider)
          .save(profile.copyWith(entryMode: mode, lastSetCount: setCount))
          .catchError((_) {}),
    );
  }

  Future<void> _addExercise(Workout workout) async {
    final exercise = await context.push<Exercise>(Routes.exercisePicker);
    if (exercise == null || !mounted) return;
    final updated = addExercise(
      workout,
      exercise,
      languageCode: Localizations.localeOf(context).languageCode,
      newId: ref.read(newIdProvider),
      now: _now,
    );
    _save(updated);
    setState(() => _pickedId = updated.exercises.last.id);
  }

  Future<void> _finish(Workout workout) async {
    final result = await showModalBottomSheet<(_Finish, DateTime)>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: context.pb.scrim,
      isScrollControlled: true,
      builder: (_) => _FinishSheet(workout: workout),
    );
    if (result == null || !mounted) return;
    final (choice, day) = result;
    final workouts = ref.read(workoutRepositoryProvider);
    unawaited(
      choice == _Finish.complete
          ? workouts.save(completeWorkout(workout, now: _now, day: day))
          : workouts.cancel(workout),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    // Finished or cancelled: nothing left to show here.
    ref.listen(activeWorkoutProvider, (previous, next) {
      if (previous?.value != null && next.hasValue && next.value == null) {
        context.pop();
      }
    });
    final workout = ref.watch(activeWorkoutProvider).value;
    if (workout == null) {
      return const Scaffold(
        body: GlowBackground(child: Center(child: CircularProgressIndicator())),
      );
    }
    final earlier = ref.watch(completedWorkoutsProvider).value ?? const [];
    final sync = ref.watch(workoutSyncProvider(workout.id)).value;
    final pending = sync?.pendingExercises(workout) ?? const <String>{};
    final profile = ref.watch(profileProvider).value;
    final mode = _mode ?? profile?.entryMode ?? EntryMode.summary;
    final current =
        workout.exercises.where((e) => e.id == _pickedId).firstOrNull ??
        nextExercise(workout);
    final done = recordedCount(workout);
    final total = workout.exercises.length;
    final newId = ref.read(newIdProvider);
    _followPanel((
      current?.id,
      mode,
      current?.sets.where((s) => s.fact != null).length,
    ));

    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(PbSpace.s4),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 2 * PbSpace.s4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: PbSpace.s2,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: PbSpace.s2,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                workout.dayName ?? l10n.workoutTitle,
                                style: PbText.title.copyWith(color: c.ink),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _finish(workout),
                              child: Text(l10n.workoutFinish),
                            ),
                          ],
                        ),
                        Barbell(
                          plates: platesOf(workout, currentId: current?.id),
                          label: l10n.workoutProgressLabel(done, total),
                          count: TextSpan(
                            text: '$done',
                            children: [
                              TextSpan(
                                text: ' ${l10n.workoutOfTotal(total)}',
                                style: TextStyle(color: c.inkMuted),
                              ),
                            ],
                          ),
                        ),
                        if (sync?.fromCache == true)
                          _OfflineNotice(pending: sync!.hasPendingWrites),
                        // Per-set entry and the keypad are tall: recorded
                        // exercises move below so «record» stays in reach.
                        for (final exercise in workout.exercises)
                          if (exercise.hasFact &&
                              exercise.id != current?.id &&
                              mode == EntryMode.summary)
                            _ExerciseCard(
                              exercise: exercise,
                              pending: pending.contains(exercise.id),
                              onTap: () =>
                                  setState(() => _pickedId = exercise.id),
                            ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: PbSpace.s2,
                      children: [
                        KeyedSubtree(
                          key: _panelKey,
                          child: current == null
                              ? _NothingToRecord(
                                  empty: total == 0,
                                  onAdd: () => _addExercise(workout),
                                  onFinish: () => _finish(workout),
                                )
                              : EntryPanel(
                                  // A fresh panel for every exercise, mode and
                                  // recorded set, so its numbers start over.
                                  key: ValueKey((
                                    current.id,
                                    mode,
                                    current.sets
                                        .where((s) => s.fact != null)
                                        .length,
                                  )),
                                  workout: workout,
                                  exercise: current,
                                  earlier: earlier,
                                  mode: mode,
                                  lastSetCount: profile?.lastSetCount,
                                  onModeChanged: (mode) {
                                    setState(() => _mode = mode);
                                    _remember(mode: mode);
                                  },
                                  onRecordSummary: (setCount, fact) {
                                    _save(
                                      recordSummary(
                                        workout,
                                        current.id,
                                        setCount: setCount,
                                        fact: fact,
                                        newId: newId,
                                        now: _now,
                                      ),
                                    );
                                    _remember(setCount: setCount);
                                    setState(() => _pickedId = null);
                                  },
                                  onRecordSet: (setId, fact, rpe) {
                                    final updated = recordSet(
                                      workout,
                                      current.id,
                                      setId,
                                      fact: fact,
                                      rpe: rpe,
                                      now: _now,
                                    );
                                    _save(updated);
                                    final same = updated.exercises.firstWhere(
                                      (e) => e.id == current.id,
                                    );
                                    // Stay on the exercise until its plan is done.
                                    setState(
                                      () => _pickedId = nextSet(same) == null
                                          ? null
                                          : current.id,
                                    );
                                  },
                                  onExtraSet: (fact, rpe) {
                                    _save(
                                      addExtraSet(
                                        workout,
                                        current.id,
                                        fact: fact,
                                        rpe: rpe,
                                        newId: newId,
                                        now: _now,
                                      ),
                                    );
                                    setState(() => _pickedId = current.id);
                                  },
                                ),
                        ),
                        if (current != null && pending.contains(current.id))
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: PbChip(
                              l10n.workoutNotSent,
                              color: c.warning,
                            ),
                          ),
                        for (final exercise in workout.exercises)
                          if (exercise.id != current?.id &&
                              !(exercise.hasFact && mode == EntryMode.summary))
                            _ExerciseCard(
                              exercise: exercise,
                              pending: pending.contains(exercise.id),
                              onTap: () =>
                                  setState(() => _pickedId = exercise.id),
                            ),
                        if (current != null)
                          TextButton(
                            onPressed: () => _addExercise(workout),
                            child: Text(l10n.workoutAddExercise),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A recorded exercise with its result, or a waiting one with its plan.
class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.onTap,
    required this.pending,
  });

  final WorkoutExercise exercise;
  final VoidCallback onTap;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final c = context.pb;
    final fact = factSummary(exercise);
    final plan = planSummary(exercise);
    final chip = fact == null
        ? null
        : deviationChip(context, compareExercise(exercise));
    return GlassCard(
      onTap: onTap,
      child: Row(
        spacing: PbSpace.s3,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PbSpace.s1,
              children: [
                Text(
                  exercise.name,
                  style: PbText.bodyStrong.copyWith(color: c.ink),
                ),
                if (chip != null || pending)
                  Wrap(
                    spacing: PbSpace.s2,
                    runSpacing: PbSpace.s1,
                    children: [
                      ?chip,
                      if (pending)
                        PbChip(
                          AppLocalizations.of(context)!.workoutNotSent,
                          color: c.warning,
                        ),
                    ],
                  ),
              ],
            ),
          ),
          if (fact != null)
            NumberText(
              summaryLine(
                context,
                fact,
                measure: exercise.measure,
                usesBodyWeight: exercise.usesBodyWeight,
              ),
              style: PbText.numSm,
              beside: true,
            )
          else if (plan != null)
            Text(
              summaryLine(
                context,
                plan,
                measure: exercise.measure,
                usesBodyWeight: exercise.usesBodyWeight,
              ).text,
              style: PbText.caption.copyWith(color: c.inkMuted),
            ),
        ],
      ),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice({required this.pending});

  final bool pending;

  @override
  Widget build(BuildContext context) {
    final c = context.pb;
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.glassStrong,
          borderRadius: BorderRadius.circular(PbRadius.lg),
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
              Icon(Icons.cloud_off_outlined, color: c.warning),
              Expanded(
                child: Text(
                  pending ? l10n.workoutLocalSaved : l10n.workoutLocalReady,
                  style: PbText.caption.copyWith(color: c.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NothingToRecord extends StatelessWidget {
  const _NothingToRecord({
    required this.empty,
    required this.onAdd,
    required this.onFinish,
  });

  final bool empty;
  final VoidCallback onAdd;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PbSpace.s3,
        children: [
          Text(
            empty ? l10n.workoutEmptyHint : l10n.workoutAllRecorded,
            style: PbText.heading.copyWith(color: c.ink),
          ),
          if (empty)
            FilledButton(onPressed: onAdd, child: Text(l10n.workoutAddExercise))
          else ...[
            FilledButton(onPressed: onFinish, child: Text(l10n.workoutFinish)),
            TextButton(onPressed: onAdd, child: Text(l10n.workoutAddExercise)),
          ],
        ],
      ),
    );
  }
}

class _FinishSheet extends StatefulWidget {
  const _FinishSheet({required this.workout});

  final Workout workout;

  @override
  State<_FinishSheet> createState() => _FinishSheetState();
}

class _FinishSheetState extends State<_FinishSheet> {
  /// Today unless the workout is being written down after the fact.
  DateTime _day = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final workout = widget.workout;
    final done = recordedCount(workout);
    final total = workout.exercises.length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(PbSpace.s2),
        child: GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: PbSpace.s3,
            children: [
              Text(
                l10n.finishTitle,
                style: PbText.heading.copyWith(color: c.ink),
              ),
              Text(
                done == total
                    ? l10n.finishBodyAll
                    : l10n.finishBody(done, total),
                style: PbText.body.copyWith(color: c.inkMuted),
              ),
              // A workout with nothing recorded has nothing to keep, so it
              // can only be cancelled. Once something is recorded, it is
              // finished instead and can be deleted from history later.
              if (done > 0) ...[
                WorkoutDayButton(
                  day: _day,
                  onPicked: (day) => setState(() => _day = day),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, (_Finish.complete, _day)),
                  child: Text(l10n.workoutFinish),
                ),
              ],
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.finishBack),
              ),
              if (done == 0)
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, (_Finish.cancel, _day)),
                  style: TextButton.styleFrom(foregroundColor: c.danger),
                  child: Text(l10n.finishCancel, textAlign: TextAlign.center),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
