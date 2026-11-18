import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart' show GestureBinding;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models.dart';
import '../../domain/workout_logic.dart';
import '../../domain/execution_logic.dart';
import '../../l10n/app_localizations.dart';
import '../../router.dart';
import '../../theme.dart';
import '../../widgets/barbell.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glow_background.dart';
import '../auth/auth_controller.dart';
import '../format.dart';
import '../execution_widgets.dart';
import '../storage_status_providers.dart';
import 'entry_panel.dart';
import 'execution_entry_panel.dart';
import 'execution_setup_sheet.dart';
import 'exercise_labels.dart';
import 'workout_day_button.dart';
import 'workout_providers.dart';

/// Plates for the workout's exercises: done, the one being recorded,
/// skipped, waiting.
List<Plate> platesOf(Workout workout, {String? currentId}) => [
  for (final exercise in workout.exercises)
    exercise.id == currentId
        ? Plate.now
        : exercise.hasFact
        ? Plate.done
        : exercise.skipped
        ? Plate.skipped
        : Plate.waiting,
];

/// «Записано 2 из 5 упражнений», with the skipped ones when there are any.
String workoutProgressText(AppLocalizations l10n, Workout workout) {
  final done = recordedCount(workout);
  final total = workout.exercises.length;
  final skipped = skippedCount(workout);
  return skipped == 0
      ? l10n.workoutProgressLabel(done, total)
      : l10n.workoutProgressLabelSkipped(done, total, skipped);
}

enum _Finish { complete, cancel }

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  final _panelKey = GlobalKey();
  Object? _followed;

  /// Keep the selected exercise and its record button in reach, while its
  /// slot in the workout stays in the original order.
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

  /// The order of exercise groups the user dropped them in, shown until the
  /// stored workout has it: the write reaches the screen a moment later.
  List<String>? _order;

  /// The workout as the screen shows it, with the dropped order on top.
  /// Everything recorded here is built from it.
  Workout _shown(Workout stored) {
    final order = _order;
    if (order == null) return stored;
    if (listEquals(groupOrder(stored), order)) {
      _order = null;
      return stored;
    }
    return arrangeGroups(stored, order, now: _now);
  }

  /// Scrolls the screen while a card is dragged to its edge: the list of
  /// cards has no scrolling of its own.
  EdgeDraggingAutoScroller? _autoScroller;

  /// The finger that last touched the list, and the one dragging a card.
  int? _pressed, _dragPointer;
  PointerMoveEvent? _lastMove;
  final _sinceMove = Stopwatch();

  void _dragStarted() {
    _dragPointer = _pressed;
    unawaited(HapticFeedback.mediumImpact());
  }

  void _dragMoved(BuildContext context, PointerMoveEvent event) {
    if (event.pointer != _dragPointer) return;
    final scrollable = Scrollable.of(context);
    if (_autoScroller?.scrollable != scrollable) {
      _autoScroller?.stopAutoScroll();
      _autoScroller = EdgeDraggingAutoScroller(
        scrollable,
        onScrollViewScrolled: _screenScrolled,
        velocityScalar: _autoScrollVelocity,
      );
    }
    _follow(event);
  }

  void _follow(PointerMoveEvent event) {
    _lastMove = event;
    _sinceMove
      ..reset()
      ..start();
    // Scrolling starts once this much around the finger leaves the screen.
    _autoScroller?.startAutoScrollIfNecessary(
      Rect.fromCenter(
        center: event.position,
        width: 1,
        height: 2 * PbSize.touchMin,
      ),
    );
  }

  /// The list works out where the card would land only when the finger moves.
  /// When the screen has scrolled under a finger held still, the finger's
  /// place is handed to the drag again: the gap follows it and the scrolling
  /// goes on.
  void _screenScrolled() {
    final last = _lastMove;
    if (last == null || last.pointer != _dragPointer || !mounted) return;
    final again = last.copyWith(
      timeStamp: last.timeStamp + _sinceMove.elapsed,
      delta: Offset.zero,
      synthesized: true,
    );
    // Only to the gestures following this finger, that is to the drag.
    GestureBinding.instance.pointerRouter.route(again);
    _follow(again);
  }

  static const _autoScrollVelocity = 50.0;

  /// A drop, a lifted finger or a gesture the system took away.
  void _dragEnded() {
    _dragPointer = null;
    _lastMove = null;
    _sinceMove.stop();
    _autoScroller?.stopAutoScroll();
  }

  void _pointerGone(PointerEvent event) {
    if (event.pointer == _dragPointer) _dragEnded();
  }

  @override
  void dispose() {
    _autoScroller?.stopAutoScroll();
    super.dispose();
  }

  void _reorder(Workout workout, WorkoutExercise? current, int from, int to) {
    if (from == to) return;
    final moved = moveExerciseGroup(workout, from, to, now: _now);
    setState(() {
      // The exercise being entered stays open, with whatever is typed in it.
      _pickedId ??= current?.id;
      _order = groupOrder(moved);
    });
    _save(moved);
  }

  void _skip(Workout workout, WorkoutExercise exercise) {
    if (exercise.skipped) {
      _save(unskipExercise(workout, exercise.id, now: _now));
      setState(() => _pickedId = exercise.id);
    } else {
      _save(skipExercise(workout, exercise.id, now: _now));
      setState(() => _pickedId = null);
    }
  }

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

  Future<void> _configure(Workout workout, WorkoutExercise exercise) async {
    var draft = workout;
    // Exercises added from the sheet are kept only when they end up in the
    // chosen superset: closing the sheet or leaving one out adds nothing.
    final added = <String>{};
    final result = await showModalBottomSheet<(ExecutionMode, List<String>)>(
      context: context,
      useSafeArea: true,
      backgroundColor: context.pb.surface,
      isScrollControlled: true,
      builder: (_) => ExecutionSetupSheet(
        workout: workout,
        exercise: exercise,
        onAdd: () async {
          final picked = await context.push<Exercise>(Routes.exercisePicker);
          if (picked == null || !mounted) return null;
          draft = addExercise(
            draft,
            picked,
            languageCode: Localizations.localeOf(context).languageCode,
            newId: ref.read(newIdProvider),
            now: _now,
          );
          added.add(draft.exercises.last.id);
          return draft.exercises.last;
        },
      ),
    );
    if (result == null || !mounted) return;
    final (mode, ids) = result;
    final updated = configureExecution(
      draft.copyWith(
        exercises: [
          for (final e in draft.exercises)
            if (!added.contains(e.id) || ids.contains(e.id)) e,
        ],
      ),
      ids,
      mode,
      newId: ref.read(newIdProvider),
      now: _now,
      setCount: ref.read(profileProvider).value?.lastSetCount ?? 3,
    );
    _save(updated);
    setState(() => _pickedId = exercise.id);
  }

  Widget _entryPanel(
    Workout workout,
    WorkoutExercise exercise,
    List<Workout> earlier,
    EntryMode mode,
    int? lastSetCount,
    IdGenerator newId, {
    required bool pending,
  }) => exercise.executionMode != ExecutionMode.ordinary
      ? ExecutionEntryPanel(
          key: ValueKey(exercise.groupId ?? exercise.id),
          workout: workout,
          exerciseId: exercise.id,
          mode: mode,
          newId: newId,
          earlier: earlier,
          lastSetCount: lastSetCount,
          onSummaryCount: (count) => _remember(setCount: count),
          pending: pending,
          onChanged: _save,
          onModeChanged: (value) {
            setState(() => _mode = value);
            _remember(mode: value);
          },
          onFinished: () => setState(() => _pickedId = null),
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EntryPanel(
              // A fresh panel for every exercise, mode and
              // recorded set, so its numbers start over.
              key: ValueKey((
                exercise.id,
                mode,
                exercise.sets.where((s) => s.fact != null).length,
              )),
              workout: workout,
              exercise: exercise,
              earlier: earlier,
              mode: mode,
              lastSetCount: lastSetCount,
              pending: pending,
              onModeChanged: (mode) {
                setState(() => _mode = mode);
                _remember(mode: mode);
              },
              onRecordSummary: (setCount, fact) {
                _save(
                  recordSummary(
                    workout,
                    exercise.id,
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
                  exercise.id,
                  setId,
                  fact: fact,
                  rpe: rpe,
                  now: _now,
                );
                _save(updated);
                final same = updated.exercises.firstWhere(
                  (e) => e.id == exercise.id,
                );
                // Stay on the exercise until its plan is done.
                setState(
                  () => _pickedId = nextSet(same) == null ? null : exercise.id,
                );
              },
              onExtraSet: (fact, rpe) {
                _save(
                  addExtraSet(
                    workout,
                    exercise.id,
                    fact: fact,
                    rpe: rpe,
                    newId: newId,
                    now: _now,
                  ),
                );
                setState(() => _pickedId = exercise.id);
              },
            ),
            if (!exercise.hasFact)
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => _configure(workout, exercise),
                    child: Text(AppLocalizations.of(context)!.executionStyle),
                  ),
                  TextButton(
                    onPressed: () => _skip(workout, exercise),
                    child: Text(
                      exercise.skipped
                          ? AppLocalizations.of(context)!.workoutUnskip
                          : AppLocalizations.of(context)!.workoutSkip,
                    ),
                  ),
                ],
              ),
          ],
        );

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
    final stored = ref.watch(activeWorkoutProvider).value;
    if (stored == null) {
      return const Scaffold(
        body: GlowBackground(child: Center(child: CircularProgressIndicator())),
      );
    }
    final workout = _shown(stored);
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
    final groups = executionGroups(workout.exercises);
    _followPanel((
      current?.id,
      mode,
      current?.sets.where((s) => s.fact != null).length,
    ));

    Widget group(List<WorkoutExercise> members, int index) => GlassCard(
      padding: const EdgeInsets.only(left: PbSpace.s4, right: PbSpace.s1),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: PbSize.touchMin),
            child: ReorderableDelayedDragStartListener(
              index: index,
              child: InkWell(
                onTap: () => setState(() => _pickedId = members.first.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: PbSpace.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: PbSpace.s2,
                    children: [
                      if (members.first.executionMode != ExecutionMode.ordinary)
                        Text(
                          '${executionLabel(l10n, members.first.executionMode)} · ${members.first.executionMode == ExecutionMode.superset ? l10n.executionRoundCount(members.first.sets.length) : l10n.setsCount(members.first.sets.length)}',
                          style: PbText.label.copyWith(color: c.inkMuted),
                        ),
                      for (final exercise in members)
                        _ExerciseCard(
                          workout: workout,
                          exercise: exercise,
                          pending: pending.contains(exercise.id),
                          onTap: () => setState(() => _pickedId = exercise.id),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: PbSize.touchMin,
            child: ExcludeSemantics(
              child: ReorderableDragStartListener(
                index: index,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) => _pressed = event.pointer,
                  child: SizedBox(
                    key: ValueKey('workout-drag-handle-${groupKey(members)}'),
                    child: const Center(child: _DragHandleIcon()),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

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
                            IconButton(
                              tooltip: MaterialLocalizations.of(context)
                                  .backButtonTooltip,
                              onPressed: () => context.pop(),
                              icon: const Icon(Icons.chevron_left),
                              constraints: const BoxConstraints(
                                minWidth: PbSize.touchMin,
                                minHeight: PbSize.touchMin,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                workout.dayName ?? l10n.workoutTitle,
                                style: PbText.title.copyWith(color: c.ink),
                              ),
                            ),
                            Flexible(
                              child: TextButton(
                                onPressed: () => _finish(workout),
                                child: Text(l10n.workoutFinish),
                              ),
                            ),
                          ],
                        ),
                        Barbell(
                          plates: platesOf(workout, currentId: current?.id),
                          label: workoutProgressText(l10n, workout),
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
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Each exercise owns one slot throughout the workout.
                        // Selecting it expands that slot without moving
                        // others; a long press on a card moves it, a superset
                        // as a whole. The screen scrolls, not the list.
                        Builder(
                          // Inside the screen's scroll view, to find it.
                          builder: (inside) => Listener(
                            onPointerDown: (event) => _pressed = event.pointer,
                            onPointerMove: (event) => _dragMoved(inside, event),
                            onPointerUp: _pointerGone,
                            onPointerCancel: _pointerGone,
                            child: ReorderableList(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: groups.length,
                              onReorderStart: (_) => _dragStarted(),
                              onReorderEnd: (_) => _dragEnded(),
                              onReorderItem: (from, to) =>
                                  _reorder(workout, current, from, to),
                              proxyDecorator: (child, index, animation) =>
                                  _Lifted(animation: animation, child: child),
                              itemBuilder: (context, index) {
                                final members = groups[index];
                                final open = members.any(
                                  (e) => e.id == current?.id,
                                );
                                return Padding(
                                  key: ValueKey(
                                    'workout-exercise-${groupKey(members)}',
                                  ),
                                  padding: const EdgeInsets.only(
                                    bottom: PbSpace.s2,
                                  ),
                                  child: open
                                      // The panel with its keypad is not
                                      // dragged; the others move around it.
                                      ? KeyedSubtree(
                                          key: _panelKey,
                                          child: _entryPanel(
                                            workout,
                                            current!,
                                            earlier,
                                            mode,
                                            profile?.lastSetCount,
                                            newId,
                                            pending: members.any(
                                              (e) => pending.contains(e.id),
                                            ),
                                          ),
                                        )
                                      : group(members, index),
                                );
                              },
                            ),
                          ),
                        ),
                        if (current == null)
                          KeyedSubtree(
                            key: _panelKey,
                            child: _NothingToRecord(
                              empty: total == 0,
                              skipped: skippedCount(workout) > 0,
                              onAdd: () => _addExercise(workout),
                              onFinish: () => _finish(workout),
                            ),
                          )
                        else
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

/// A card being dragged: lifted off the list on a solid surface.
class _Lifted extends StatelessWidget {
  const _Lifted({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.pb;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final lift = MediaQuery.disableAnimationsOf(context)
            ? 0.0
            : Curves.easeOut.transform(animation.value);
        return Transform.scale(
          scale: 1 + PbSize.dragScaleIncrement * lift,
          child: Stack(
            children: [
              // Under the cards only, not the gap kept below them.
              Positioned.fill(
                bottom: PbSpace.s2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.glassLine),
                    borderRadius: BorderRadius.circular(PbRadius.lg),
                    boxShadow: [
                      BoxShadow(
                        color: c.scrim,
                        offset: const Offset(0, PbSize.dragShadowOffset),
                        blurRadius: PbSize.dragShadowBlur,
                      ),
                    ],
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: _DraggedCard(
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }
}

/// A recorded exercise with its result, or a waiting one with its plan.
class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.workout,
    required this.exercise,
    required this.onTap,
    required this.pending,
  });

  final Workout workout;
  final WorkoutExercise exercise;
  final VoidCallback onTap;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final c = context.pb;
    final fact = factSummary(exercise);
    final plan = planSummary(exercise);
    final line = fact != null || plan != null
        ? summaryLine(
            context,
            fact ?? plan!,
            measure: exercise.measure,
            usesBodyWeight: exercise.usesBodyWeight,
          )
        : null;
    final nameStyle = PbText.bodyStrong.copyWith(
      color: exercise.skipped ? c.inkMuted : c.ink,
    );
    final resultStyle = PbText.numSm.copyWith(
      color: fact != null ? c.ink : c.inkMuted,
    );
    return InkWell(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final name = Text(exercise.name, style: nameStyle);
          Widget heading = name;
          if (line != null) {
            final scaler = MediaQuery.textScalerOf(context);
            final direction = Directionality.of(context);
            final resultPainter = TextPainter(
              text: TextSpan(text: line.text, style: resultStyle),
              textDirection: direction,
              textScaler: scaler,
            )..layout();
            final resultWidth = math.min(
              resultPainter.width + PbSpace.s1,
              constraints.maxWidth * 0.55,
            );
            final resultTooWide = resultPainter.width > resultWidth;
            resultPainter.dispose();
            final namePainter =
                TextPainter(
                  text: TextSpan(text: exercise.name, style: nameStyle),
                  textDirection: direction,
                  textScaler: scaler,
                  maxLines: 2,
                )..layout(
                  maxWidth: math.max(
                    0,
                    constraints.maxWidth - resultWidth - PbSpace.s3,
                  ),
                );
            final stack = namePainter.didExceedMaxLines || resultTooWide;
            namePainter.dispose();
            final result = Text.rich(
              TextSpan(
                children: [
                  for (final (text, unit) in line.parts)
                    TextSpan(
                      text: text,
                      style: unit ? TextStyle(color: c.inkMuted) : null,
                    ),
                ],
              ),
              style: resultStyle,
            );
            heading = stack
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: PbSpace.s1,
                    children: [name, result],
                  )
                : Row(
                    spacing: PbSpace.s3,
                    children: [
                      Expanded(child: name),
                      SizedBox(width: resultWidth, child: result),
                    ],
                  );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: PbSpace.s2,
            children: [
              heading,
              if (fact != null ||
                  exercise.skipped ||
                  pending ||
                  isOutsidePlan(workout, exercise))
                ExerciseLabels(
                  workout: workout,
                  exercise: exercise,
                  pending: pending,
                  showComparison: true,
                ),
            ],
          );
        },
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
    required this.skipped,
    required this.onAdd,
    required this.onFinish,
  });

  final bool empty;

  /// Some exercises were skipped rather than recorded.
  final bool skipped;
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
            empty
                ? l10n.workoutEmptyHint
                : skipped
                ? l10n.workoutAllDone
                : l10n.workoutAllRecorded,
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
    final skipped = skippedCount(workout);
    final untouched = total - done - skipped;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(PbSpace.s2),
        child: SingleChildScrollView(
          child: GlassPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: PbSpace.s2,
              children: [
                Text(
                  l10n.finishTitle,
                  style: PbText.heading.copyWith(color: c.ink),
                ),
                if (done == total)
                  Text(
                    l10n.finishBodyAll,
                    style: PbText.body.copyWith(color: c.inkMuted),
                  )
                else ...[
                  if (done > 0)
                    _FinishRow(
                      label: l10n.finishRowRecorded,
                      value: '$done ${l10n.workoutOfTotal(total)}',
                    ),
                  if (skipped > 0)
                    _FinishRow(
                      label: l10n.finishRowSkipped,
                      value: '$skipped',
                      names: workout.exercises
                          .where((e) => e.skipped)
                          .map((e) => e.name)
                          .join(', '),
                    ),
                  if (untouched > 0)
                    _FinishRow(
                      label: l10n.finishRowEmpty,
                      value: '$untouched',
                      names: workout.exercises
                          .where((e) => !e.hasFact && !e.skipped)
                          .map((e) => e.name)
                          .join(', '),
                    ),
                  if (untouched > 0)
                    Text(
                      l10n.finishEmptyHint,
                      style: PbText.caption.copyWith(color: c.inkMuted),
                    ),
                ],
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
      ),
    );
  }
}

class _DraggedCard extends InheritedWidget {
  const _DraggedCard({required super.child});
  @override
  bool updateShouldNotify(_DraggedCard oldWidget) => false;
}

class _DragHandleIcon extends StatelessWidget {
  const _DragHandleIcon();
  @override
  Widget build(BuildContext context) => Icon(
    Icons.menu_rounded,
    size: PbSize.icon,
    color: context.dependOnInheritedWidgetOfExactType<_DraggedCard>() != null
        ? context.pb.accentText
        : context.pb.inkMuted,
  );
}

class _FinishRow extends StatelessWidget {
  const _FinishRow({required this.label, required this.value, this.names});
  final String label, value;
  final String? names;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: context.pb.line)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: PbSize.rowInset),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: PbSpace.s3,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PbSize.tinyGap,
              children: [
                Text(label, style: PbText.body.copyWith(color: context.pb.ink)),
                if (names != null)
                  Text(
                    names!,
                    style: PbText.caption.copyWith(color: context.pb.inkMuted),
                  ),
              ],
            ),
          ),
          Text(value, style: PbText.numSm.copyWith(color: context.pb.ink)),
        ],
      ),
    ),
  );
}
