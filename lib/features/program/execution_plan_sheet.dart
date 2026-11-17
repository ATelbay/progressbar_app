import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/program_logic.dart';
import '../../domain/workout_logic.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../widgets/step_button.dart';
import '../execution_widgets.dart';
import '../format.dart';
import '../workout/summary_entry.dart';

class ExecutionPlanResult {
  const ExecutionPlanResult(this.members, {this.remove = false});
  final List<ProgramExercise> members;
  final bool remove;
}

class _Member {
  _Member(
    this.exercise,
    this.id,
    this.values, {
    this.note = '',
    this.existing = false,
  });
  final Exercise exercise;
  final String id;
  SetValues values;
  String note;
  final bool existing;
}

class ExecutionPlanSheet extends StatefulWidget {
  const ExecutionPlanSheet({
    super.key,
    required this.exercise,
    required this.initial,
    required this.catalog,
    required this.newId,
    required this.onPick,
    required this.earlier,
  });
  final Exercise exercise;
  final List<ProgramExercise> initial;
  final Map<String, Exercise> catalog;
  final IdGenerator newId;
  final Future<Exercise?> Function() onPick;
  final List<Workout> earlier;
  @override
  State<ExecutionPlanSheet> createState() => _ExecutionPlanSheetState();
}

class _ExecutionPlanSheetState extends State<ExecutionPlanSheet> {
  late ExecutionMode _mode =
      widget.initial.firstOrNull?.executionMode ?? ExecutionMode.ordinary;
  late final String _groupId =
      widget.initial.firstOrNull?.groupId ?? widget.newId();
  late final List<_Member> _members = widget.initial.isEmpty
      ? [_create(widget.exercise)]
      : [
          for (final p in widget.initial)
            _Member(
              widget.catalog[p.exerciseId]!,
              p.id,
              p.sets.first,
              note: p.note ?? '',
              existing: true,
            ),
        ];
  final _detached = <_Member>[];
  late int _count = widget.initial.firstOrNull?.sets.length ?? 3;
  late final List<SetValues> _drops = [
    _members.first.values,
    ...?widget.initial.firstOrNull?.dropStages,
  ];
  int _member = 0, _stage = 0, _revision = 0;
  final _note = TextEditingController();
  _Member _create(Exercise e) => _Member(
    e,
    widget.newId(),
    SetValues(
      reps: e.measure == Measure.reps ? 10 : null,
      seconds: e.measure == Measure.time ? 30 : null,
      weightKg: lastRecorded(e.id, widget.earlier)?.weightKg ?? 0,
    ),
  );
  _Member get _current => _members[_member];
  @override
  void initState() {
    super.initState();
    _note.text = _current.note;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _select(int member) {
    _current.note = _note.text;
    _member = member;
    _stage = 0;
    _note.text = _current.note;
    _revision++;
  }

  Future<void> _addMember() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final exercise = await widget.onPick();
    if (exercise == null || !mounted) return;
    setState(() => _members.add(_create(exercise)));
  }

  void _finish() {
    _current.note = _note.text;
    final members = <ProgramExercise>[
      for (final (i, m) in _members.indexed)
        ProgramExercise(
          id: m.id,
          exerciseId: m.exercise.id,
          sets: uniformSets(
            _count,
            _mode == ExecutionMode.dropSet && i == 0 ? _drops.first : m.values,
          ),
          note: m.note.trim().isEmpty ? null : m.note.trim(),
          executionMode: _mode == ExecutionMode.superset
              ? _mode
              : i == 0
              ? _mode
              : ExecutionMode.ordinary,
          groupId: _mode == ExecutionMode.superset ? _groupId : null,
          dropStages: _mode == ExecutionMode.dropSet && i == 0
              ? _drops.skip(1).toList()
              : const [],
        ),
      for (final m in _detached)
        ProgramExercise(
          id: m.id,
          exerciseId: m.exercise.id,
          sets: uniformSets(_count, m.values),
          note: m.note.isEmpty ? null : m.note,
        ),
    ];
    Navigator.pop(context, ExecutionPlanResult(members));
  }

  void _submit(int count, SetValues values, {bool add = false}) {
    _count = count;
    _current.note = _note.text;
    if (_mode == ExecutionMode.dropSet) {
      _drops[_stage] = values;
      _members.first.values = _drops.first;
      if (add) {
        setState(() {
          _drops.add(values);
          _stage = _drops.length - 1;
          _revision++;
        });
        return;
      }
      if (_stage + 1 < _drops.length) {
        setState(() {
          _stage++;
          _revision++;
        });
        return;
      }
    } else {
      _current.values = values;
      if (_mode == ExecutionMode.superset) {
        if (_members.length < 2) {
          _addMember();
          return;
        }
        if (_member + 1 < _members.length) {
          setState(() => _select(_member + 1));
          return;
        }
      }
    }
    _finish();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!, c = context.pb;
    final current = _current, e = current.exercise;
    final language = Localizations.localeOf(context).languageCode;
    final last = lastRecorded(e.id, widget.earlier);
    final more = _mode == ExecutionMode.superset
        ? _member + 1 < _members.length
        : _mode == ExecutionMode.dropSet && _stage + 1 < _drops.length;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: PbSpace.s4,
          right: PbSpace.s4,
          top: PbSpace.s4,
          bottom: PbSpace.s4 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: PbSpace.s2,
          children: [
            Text(
              e.nameFor(language),
              style: PbText.heading.copyWith(color: c.ink),
            ),
            Text(
              l10n.executionStyle,
              style: PbText.label.copyWith(color: c.inkMuted),
            ),
            ExecutionSelector(
              value: _mode,
              onChanged: (mode) => setState(() {
                _select(0);
                _mode = mode;
                _stage = 0;
                if (mode == ExecutionMode.dropSet) {
                  _drops[0] = _members.first.values;
                }
              }),
            ),
            if (_mode == ExecutionMode.superset) ...[
              Wrap(
                spacing: PbSpace.s2,
                runSpacing: PbSpace.s2,
                children: [
                  for (final (i, m) in _members.indexed)
                    PbPill(
                      selected: i == _member,
                      onTap: () => setState(() => _select(i)),
                      child: Text(m.exercise.nameFor(language)),
                    ),
                ],
              ),
              if (_members.length < 2)
                Text(
                  l10n.executionMinMembers,
                  style: PbText.caption.copyWith(color: c.inkMuted),
                ),
              OutlinedButton.icon(
                onPressed: _addMember,
                icon: const Icon(Icons.add),
                label: Text(l10n.executionAddMember),
              ),
              if (_members.length > 1)
                TextButton(
                  onPressed: () => setState(() {
                    final removed = _members.removeAt(_member);
                    if (removed.existing) _detached.add(removed);
                    _member = 0;
                    _note.text = _current.note;
                    _revision++;
                  }),
                  child: Text(l10n.executionRemoveMember),
                ),
              Text(
                l10n.executionMember(_member + 1, _members.length),
                style: PbText.label.copyWith(color: c.accentText),
              ),
            ],
            if (_mode == ExecutionMode.dropSet) ...[
              Text(
                l10n.executionPlanStagesHint,
                style: PbText.caption.copyWith(color: c.inkMuted),
              ),
              Wrap(
                spacing: PbSpace.s2,
                runSpacing: PbSpace.s2,
                children: [
                  for (var i = 0; i < _drops.length; i++)
                    PbPill(
                      selected: i == _stage,
                      onTap: () => setState(() {
                        _stage = i;
                        _revision++;
                      }),
                      child: Text(
                        i == 0
                            ? l10n.executionInitialStage
                            : l10n.executionDropStage(i),
                      ),
                    ),
                ],
              ),
              if (_stage > 0)
                TextButton.icon(
                  onPressed: () => setState(() {
                    _drops.removeAt(_stage);
                    _stage = (_stage - 1).clamp(0, _drops.length - 1);
                    _revision++;
                  }),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.executionRemoveDrop),
                ),
            ],
            if (widget.initial.isEmpty &&
                _mode == ExecutionMode.ordinary &&
                e.measure != Measure.time)
              Text(
                last == null
                    ? l10n.builderNoHistory
                    : l10n.builderLastTime(
                        summaryLine(
                          context,
                          last.summary,
                          measure: e.measure,
                          usesBodyWeight: e.usesBodyWeight,
                        ).text,
                      ),
                style: PbText.caption.copyWith(color: c.inkMuted),
              ),
            SummaryEntry(
              key: ValueKey(_revision),
              setCount: _count,
              values: _mode == ExecutionMode.dropSet
                  ? _drops[_stage]
                  : current.values,
              measure: e.measure,
              usesBodyWeight: e.usesBodyWeight,
              showSetCount:
                  _mode == ExecutionMode.ordinary ||
                  (_mode == ExecutionMode.dropSet ? _stage == 0 : _member == 0),
              setCountLabel: _mode == ExecutionMode.superset
                  ? l10n.executionRounds
                  : null,
              knownPlanningWeight:
                  e.measure != Measure.time &&
                  _mode == ExecutionMode.ordinary &&
                  (widget.initial.isNotEmpty || last != null),
              submitLabel: more
                  ? l10n.entryContinue
                  : _mode == ExecutionMode.superset && _members.length < 2
                  ? l10n.executionAddMember
                  : l10n.welcomeDone,
              onSubmit: (n, v) => _submit(n, v),
              extraSubmitLabel: l10n.executionAddDrop,
              onExtraSubmit: _mode == ExecutionMode.dropSet && !more
                  ? (n, v) => _submit(n, v, add: true)
                  : null,
              details: TextField(
                controller: _note,
                onChanged: (value) => current.note = value,
                decoration: InputDecoration(labelText: l10n.builderNote),
              ),
            ),
            if (_mode != ExecutionMode.ordinary)
              TextField(
                controller: _note,
                onChanged: (value) => current.note = value,
                decoration: InputDecoration(labelText: l10n.builderNote),
              ),
            if (widget.initial.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.pop(
                  context,
                  const ExecutionPlanResult([], remove: true),
                ),
                style: TextButton.styleFrom(foregroundColor: c.danger),
                child: Text(l10n.builderRemoveExercise),
              ),
          ],
        ),
      ),
    );
  }
}
