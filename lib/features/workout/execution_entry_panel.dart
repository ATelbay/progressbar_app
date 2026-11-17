import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/workout_logic.dart';
import '../../domain/execution_logic.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/step_button.dart';
import '../../widgets/sheet.dart';
import '../execution_widgets.dart';
import 'summary_entry.dart';
import 'exercise_labels.dart';

/// Uses one keypad throughout a group. Completed full-entry steps are sent
/// through the same repository callback as ordinary sets, without waiting for
/// the network. Summary drafts are committed together at the last member.
class ExecutionEntryPanel extends StatefulWidget {
  const ExecutionEntryPanel({
    super.key,
    required this.workout,
    required this.exerciseId,
    required this.mode,
    required this.newId,
    required this.onChanged,
    required this.onModeChanged,
    required this.onFinished,
    this.pending = false,
    this.earlier = const [],
    this.lastSetCount,
    this.onSummaryCount,
  });
  final Workout workout;
  final String exerciseId;
  final EntryMode mode;
  final IdGenerator newId;
  final ValueChanged<Workout> onChanged;
  final ValueChanged<EntryMode> onModeChanged;
  final VoidCallback onFinished;
  final bool pending;
  final List<Workout> earlier;
  final int? lastSetCount;
  final ValueChanged<int>? onSummaryCount;
  @override
  State<ExecutionEntryPanel> createState() => _ExecutionEntryPanelState();
}

class _ExecutionEntryPanelState extends State<ExecutionEntryPanel> {
  late Workout _workout = widget.workout;
  late EntryMode _mode = canSummarizeExecution(_group)
      ? widget.mode
      : EntryMode.perSet;
  int _member = 0, _stage = 0, _revision = 0;
  final _entryAnchor = GlobalKey();
  int _followedRevision = -1;
  String? _setId;
  int _rounds = 3;
  final _summaries = <String, SetValues>{};
  List<SetValues> _drops = [];
  Effort? _effort;
  List<WorkoutExercise> get _group =>
      executionGroups(_workout.exercises)
          .firstWhere((g) => g.any((e) => e.id == widget.exerciseId));
  WorkoutExercise get _exercise => _group[_member];
  bool get _isDrop => _exercise.executionMode == ExecutionMode.dropSet;
  WorkoutSet get _set => _exercise.sets.firstWhere((s) => s.id == _setId);
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  /// The panel writes the whole workout from its own copy, so it takes the
  /// rest of the workout from the screen as it changes — the order above
  /// all — and keeps only its own group, which may hold a round not yet
  /// stored.
  @override
  void didUpdateWidget(ExecutionEntryPanel old) {
    super.didUpdateWidget(old);
    if (identical(widget.workout, old.workout)) return;
    final mine = {for (final e in _group) e.id: e};
    _workout = widget.workout.copyWith(
      exercises: [for (final e in widget.workout.exercises) mine[e.id] ?? e],
    );
  }

  void _toggleSkip() {
    final now = DateTime.now();
    if (_group.every((e) => e.skipped)) {
      setState(() => _emit(unskipExercise(_workout, _exercise.id, now: now)));
    } else {
      _emit(skipExercise(_workout, _exercise.id, now: now));
      widget.onFinished();
    }
  }

  void _initialize() {
    _member = 0;
    _stage = 0;
    _summaries.clear();
    final first = _group.first;
    _rounds =
        !first.hasFact &&
            first.sets.isNotEmpty &&
            first.sets.every((s) => s.plan == null)
        ? first.sets.length
        : summaryDraft(
            first,
            widget.earlier,
            lastSetCount: widget.lastSetCount,
          ).setCount;
    if (_mode == EntryMode.perSet) {
      final next = nextGroupSet(_group);
      _member = next == null
          ? _group.indexWhere((e) => e.id == widget.exerciseId)
          : _group.indexOf(next.exercise);
      _setId = next?.set.id ?? _exercise.sets.firstOrNull?.id;
      if (_setId == null) {
        _workout = addExecutionRound(
          _workout,
          _group,
          newId: widget.newId,
          now: DateTime.now(),
        );
        _setId = _exercise.sets.first.id;
      }
      _stage = _isDrop && !_set.dropComplete ? nextDropStage(_set) : 0;
      _effort = _set.rpe == null ? null : Effort.of(_set.rpe!);
    }
    _seedDrops();
    _revision++;
  }

  void _seedDrops() {
    if (!_isDrop) return;
    final s = _exercise.sets.firstOrNull;
    _drops = [
      s?.fact ?? s?.plan ?? summaryDraft(_exercise, widget.earlier).values,
      if (s != null)
        for (final d in s.drops)
          if (d.fact != null || d.plan != null) d.fact ?? d.plan!,
    ];
  }

  void _emit(Workout updated) {
    _workout = updated;
    widget.onChanged(updated);
  }

  void _nextFull() {
    final next = nextGroupSet(_group);
    if (next == null) {
      widget.onFinished();
      return;
    }
    setState(() {
      _member = _group.indexOf(next.exercise);
      _setId = next.set.id;
      _stage = _isDrop ? nextDropStage(next.set) : 0;
      _revision++;
      _effort = null;
    });
  }

  void _superset(int count, SetValues values) {
    if (_mode == EntryMode.summary) {
      _rounds = count;
      _summaries[_exercise.id] = values;
      final missing = _group.indexWhere((e) => !_summaries.containsKey(e.id));
      if (missing >= 0) {
        setState(() {
          _member = missing;
          _revision++;
        });
        return;
      }
      var updated = _workout;
      for (final e in _group) {
        updated = recordSummary(
          updated,
          e.id,
          setCount: _rounds,
          fact: _summaries[e.id]!,
          newId: widget.newId,
          now: DateTime.now(),
        );
      }
      _emit(finishExecutionGroup(updated, _group));
      widget.onSummaryCount?.call(_rounds);
      widget.onFinished();
    } else {
      _emit(
        recordSet(
          _workout,
          _exercise.id,
          _set.id,
          fact: values,
          rpe: _effort?.rpe,
          now: DateTime.now(),
        ),
      );
      _nextFull();
    }
  }

  void _drop(
    int count,
    SetValues values, {
    bool add = false,
    bool finish = false,
  }) {
    if (_mode == EntryMode.summary) {
      _rounds = count;
      _drops[_stage] = values;
      if (add) {
        setState(() {
          _drops.add(values);
          _stage = _drops.length - 1;
          _revision++;
        });
        return;
      }
      if (!finish && _stage + 1 < _drops.length) {
        setState(() {
          _stage++;
          _revision++;
        });
        return;
      }
      _emit(
        recordDropSummary(
          _workout,
          _exercise.id,
          setCount: _rounds,
          stages: finish ? _drops.take(_stage + 1).toList() : _drops,
          newId: widget.newId,
          now: DateTime.now(),
        ),
      );
      widget.onSummaryCount?.call(_rounds);
      widget.onFinished();
    } else {
      final another = _stage < _set.drops.length;
      final end = finish || (!add && !another);
      _emit(
        recordDropStage(
          _workout,
          _exercise.id,
          _set.id,
          stage: _stage,
          fact: values,
          newId: widget.newId,
          now: DateTime.now(),
          finish: end,
          rpe: _effort?.rpe,
        ),
      );
      if (end) {
        _nextFull();
      } else {
        setState(() {
          _stage++;
          _revision++;
        });
      }
    }
  }

  SetValues get _values {
    if (_mode == EntryMode.summary) {
      return _isDrop
          ? _drops[_stage]
          : _summaries[_exercise.id] ??
                summaryDraft(_exercise, widget.earlier).values;
    }
    if (!_isDrop || _stage == 0) {
      return setDraft(_exercise, _set, widget.earlier);
    }
    final d = _stage <= _set.drops.length ? _set.drops[_stage - 1] : null;
    return d?.fact ??
        d?.plan ??
        (_stage == 1 ? _set.fact : _set.drops[_stage - 2].fact) ??
        summaryDraft(_exercise, widget.earlier).values;
  }

  Future<void> _showControls(SummaryEntryActions actions) => showPbSheet<void>(
    context,
    Builder(
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        final c = sheetContext.pb;
        final round = _mode == EntryMode.perSet
            ? _exercise.sets.indexOf(_set)
            : 0;
        void choose(VoidCallback change) {
          Navigator.pop(sheetContext);
          setState(change);
        }

        void submit(VoidCallback action) {
          Navigator.pop(sheetContext);
          action();
        }

        return PbSheet(
          children: [
            Text(
              _isDrop
                  ? l10n.executionControlsDrop
                  : l10n.executionControlsSuperset,
              style: PbText.heading.copyWith(color: c.ink),
            ),
            Text(
              l10n.executionControlsHint,
              style: PbText.caption.copyWith(color: c.inkMuted),
            ),
            if (!_isDrop)
              for (final (i, e) in _group.indexed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.name),
                  selected: i == _member,
                  selectedColor: c.ink,
                  selectedTileColor: c.selection,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PbRadius.md),
                  ),
                  trailing: i == _member
                      ? const Icon(Icons.radio_button_checked)
                      : null,
                  onTap: i == _member
                      ? () => Navigator.pop(sheetContext)
                      : () => choose(() {
                          _member = i;
                          if (_mode == EntryMode.perSet) {
                            final selected =
                                e.sets[round.clamp(0, e.sets.length - 1)];
                            _setId = selected.id;
                            _effort = selected.rpe == null
                                ? null
                                : Effort.of(selected.rpe!);
                          }
                          _revision++;
                        }),
                ),
            if (_mode == EntryMode.perSet) ...[
              Text(
                _isDrop ? l10n.entrySets : l10n.executionRounds,
                style: PbText.label.copyWith(color: c.inkMuted),
              ),
              Wrap(
                spacing: PbSpace.s2,
                runSpacing: PbSpace.s2,
                children: [
                  for (final (i, s) in _exercise.sets.indexed)
                    PbPill(
                      selected: s.id == _setId,
                      onTap: s.id == _setId
                          ? () => Navigator.pop(sheetContext)
                          : () => choose(() {
                              _setId = s.id;
                              _effort = s.rpe == null
                                  ? null
                                  : Effort.of(s.rpe!);
                              _stage = 0;
                              _revision++;
                            }),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: PbSpace.s1,
                        children: [
                          Text('${i + 1}'),
                          if (_isDrop ? s.dropComplete : s.fact != null)
                            const Icon(Icons.check, size: PbSpace.s4),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            if (_isDrop)
              for (
                var i = 0;
                i <
                    (_mode == EntryMode.summary
                        ? _drops.length
                        : _set.drops.length + 1);
                i++
              )
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    i == 0
                        ? l10n.executionInitialStage
                        : l10n.executionDropStage(i),
                  ),
                  selected: i == _stage,
                  selectedColor: c.ink,
                  selectedTileColor: c.selection,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PbRadius.md),
                  ),
                  trailing: i == _stage
                      ? const Icon(Icons.radio_button_checked)
                      : null,
                  enabled:
                      _mode != EntryMode.perSet || i <= nextDropStage(_set),
                  onTap: i == _stage
                      ? () => Navigator.pop(sheetContext)
                      : () => choose(() {
                          _stage = i;
                          _revision++;
                        }),
                ),
            if (_isDrop &&
                (_mode == EntryMode.summary
                    ? _stage + 1 == _drops.length
                    : _stage == _set.drops.length))
              TextButton.icon(
                onPressed: actions.add == null
                    ? null
                    : () => submit(actions.add!),
                icon: const Icon(Icons.add),
                label: Text(l10n.executionAddDrop),
              ),
            if (_isDrop &&
                (_mode == EntryMode.summary
                    ? _stage + 1 < _drops.length
                    : _stage < _set.drops.length))
              TextButton(
                onPressed: actions.finish == null
                    ? null
                    : () => submit(actions.finish!),
                child: Text(l10n.executionFinishDrop),
              ),
            if (_mode == EntryMode.perSet) ...[
              if (!_isDrop)
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _emit(
                      addExecutionRound(
                        _workout,
                        _group,
                        newId: widget.newId,
                        now: DateTime.now(),
                      ),
                    );
                    setState(() {
                      _setId = _exercise.sets.last.id;
                      _stage = 0;
                      _revision++;
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l10n.executionExtraRound),
                ),
              Text(
                l10n.entryEffort,
                style: PbText.label.copyWith(color: c.inkMuted),
              ),
              Wrap(
                spacing: PbSpace.s2,
                runSpacing: PbSpace.s2,
                children: [
                  for (final effort in Effort.values)
                    PbPill(
                      selected: _effort == effort,
                      onTap: () => choose(
                        () => _effort = _effort == effort ? null : effort,
                      ),
                      child: Text(switch (effort) {
                        Effort.more => l10n.effortMore,
                        Effort.some => l10n.effortSome,
                        Effort.none => l10n.effortNone,
                      }),
                    ),
                ],
              ),
              if (_isDrop)
                TextButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _emit(
                      addExecutionRound(
                        _workout,
                        _group,
                        newId: widget.newId,
                        now: DateTime.now(),
                      ),
                    );
                    setState(() {
                      _setId = _exercise.sets.last.id;
                      _stage = 0;
                      _revision++;
                    });
                  },
                  child: Text(l10n.entryExtraSet),
                ),
            ],
            OutlinedButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: Text(l10n.executionContinueRecord),
            ),
          ],
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!, c = context.pb;
    final canSummary = canSummarizeExecution(_group);
    final round = _mode == EntryMode.perSet
        ? _exercise.sets.indexOf(_set) + 1
        : 1;
    final anotherDrop =
        _isDrop &&
        (_mode == EntryMode.summary
            ? _stage + 1 < _drops.length
            : _stage < _set.drops.length);
    final remainingFull =
        _mode == EntryMode.perSet &&
        _group.any((e) => e.sets.any((s) => s.id != _setId && s.fact == null));
    final label = _isDrop
        ? (anotherDrop
              ? l10n.entryContinue
              : _mode == EntryMode.summary
              ? l10n.executionRecordDrops
              : l10n.executionRecordDropSet)
        : (_mode == EntryMode.summary
              ? _group.any(
                  (e) => e.id != _exercise.id && !_summaries.containsKey(e.id),
                )
              : remainingFull)
        ? l10n.entryContinue
        : l10n.executionRecordSuperset;
    if (_followedRevision != _revision) {
      _followedRevision = _revision;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _entryAnchor.currentContext;
        if (target == null || !target.mounted) return;
        Scrollable.ensureVisible(
          target,
          alignment: 1,
          duration: MediaQuery.disableAnimationsOf(target)
              ? Duration.zero
              : const Duration(milliseconds: 180),
        );
      });
    }
    final detailsTitle = _isDrop
        ? l10n.executionControlsDrop
        : l10n.executionControlsSuperset;
    return GlassPanel(
      child: Column(
        key: _entryAnchor,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PbSpace.s2,
        children: [
          Text(_exercise.name, style: PbText.heading.copyWith(color: c.ink)),
          Wrap(
            spacing: PbSpace.s2,
            runSpacing: PbSpace.s1,
            children: [
              Text(
                executionLabel(l10n, _exercise.executionMode),
                style: PbText.caption.copyWith(color: c.inkMuted),
              ),
              if (_mode == EntryMode.perSet)
                Text(
                  _isDrop
                      ? l10n.executionDropNumber(round, _exercise.sets.length)
                      : l10n.executionRound(round, _exercise.sets.length),
                  style: PbText.caption.copyWith(color: c.inkMuted),
                ),
              Text(
                _isDrop
                    ? (_stage == 0
                          ? l10n.executionInitialStage
                          : l10n.executionDropStage(_stage))
                    : l10n.executionMember(_member + 1, _group.length),
                style: PbText.caption.copyWith(color: c.inkMuted),
              ),
            ],
          ),
          EntryModeSelector(
            value: _mode,
            canSummary: canSummary,
            onChanged: (value) {
              setState(() {
                _mode = value;
                _initialize();
              });
              widget.onModeChanged(_mode);
            },
          ),
          if (!canSummary)
            Text(
              l10n.executionDifferentResults,
              style: PbText.caption.copyWith(color: c.inkMuted),
            ),
          if (_exercise.note case final note?)
            Text(note, style: PbText.caption.copyWith(color: c.inkMuted)),
          ExerciseLabels(
            workout: _workout,
            exercise: _exercise,
            pending: widget.pending,
          ),
          SummaryEntry(
            key: ValueKey(_revision),
            setCount: _rounds,
            values: _values,
            showSetCount:
                _mode == EntryMode.summary &&
                (_isDrop ? _stage == 0 : _member == 0),
            setCountLabel: _isDrop ? l10n.entrySets : l10n.executionRounds,
            measure: _exercise.measure,
            usesBodyWeight: _exercise.usesBodyWeight,
            submitLabel: label,
            onSubmit: _isDrop ? (n, v) => _drop(n, v) : _superset,
            onExtraSubmit: _isDrop && !anotherDrop
                ? (n, v) => _drop(n, v, add: true)
                : null,
            onFinishSubmit: anotherDrop
                ? (n, v) => _drop(n, v, finish: true)
                : null,
            controls: (actions) => TextButton.icon(
              key: const ValueKey("execution-controls"),
              onPressed: () => _showControls(actions),
              icon: const Icon(Icons.format_list_bulleted),
              label: Text(detailsTitle),
            ),
          ),
          if (!_group.any((e) => e.hasFact))
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: _toggleSkip,
                child: Text(
                  _group.every((e) => e.skipped)
                      ? l10n.workoutUnskip
                      : l10n.workoutSkip,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
