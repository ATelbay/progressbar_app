import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/workout_logic.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/step_button.dart';
import '../format.dart';
import 'number_field.dart';
import 'weight_keypad.dart';

/// Where a result is typed in. Summary mode takes «sets × reps × weight» in
/// one go, per-set mode takes one set at a time; both end up stored per set.
class EntryPanel extends StatefulWidget {
  const EntryPanel({
    super.key,
    required this.workout,
    required this.exercise,
    required this.earlier,
    required this.mode,
    required this.lastSetCount,
    required this.onRecordSummary,
    required this.onRecordSet,
    required this.onExtraSet,
    required this.onModeChanged,
  });

  final Workout workout;
  final WorkoutExercise exercise;
  final List<Workout> earlier;
  final EntryMode mode;
  final int? lastSetCount;
  final void Function(int setCount, SetValues fact) onRecordSummary;
  final void Function(String setId, SetValues fact, double? rpe) onRecordSet;
  final void Function(SetValues fact, double? rpe) onExtraSet;
  final ValueChanged<EntryMode> onModeChanged;

  @override
  State<EntryPanel> createState() => _EntryPanelState();
}

class _EntryPanelState extends State<EntryPanel> {
  late int _setCount;
  late int _count;
  late double _weightKg;
  Effort? _effort;

  /// The set being recorded in per-set mode; null adds one beyond the plan.
  String? _setId;

  /// Whether the weight keypad is open in place of the fields.
  bool _typing = false;

  WorkoutExercise get _exercise => widget.exercise;
  bool get _timed => _exercise.measure == Measure.time;

  @override
  void initState() {
    super.initState();
    if (widget.mode == EntryMode.summary) {
      final draft = summaryDraft(
        _exercise,
        widget.earlier,
        lastSetCount: widget.lastSetCount,
      );
      _setCount = draft.setCount;
      _use(draft.values);
    } else {
      _setCount = 1;
      _select(nextSet(_exercise));
    }
  }

  void _use(SetValues values) {
    _count = values.reps ?? values.seconds ?? 0;
    _weightKg = values.weightKg;
  }

  void _select(WorkoutSet? set) {
    _setId = set?.id;
    _effort = set?.rpe == null ? null : Effort.of(set!.rpe!);
    _use(
      set != null
          ? setDraft(_exercise, set, widget.earlier)
          : summaryDraft(_exercise, widget.earlier).values,
    );
  }

  SetValues get _values => _timed
      ? SetValues(seconds: _count, weightKg: _weightKg)
      : SetValues(reps: _count, weightKg: _weightKg);

  void _stepCount(int direction) => setState(() {
    final step = _timed ? secondsStep : 1;
    _count = (_count + direction * step).clamp(step, 999);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final plan = planSummary(_exercise);
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PbSpace.s2,
        children: [
          Text(_exercise.name, style: PbText.heading.copyWith(color: c.ink)),
          if (_exercise.note case final note?)
            Text(note, style: PbText.caption.copyWith(color: c.inkMuted)),
          if (_typing)
            WeightKeypad(
              label: _exercise.usesBodyWeight
                  ? l10n.entryExtraWeight
                  : l10n.entryWeight,
              weightKg: _weightKg,
              onDone: (kg) => setState(() {
                if (kg != null) _weightKg = kg;
                _typing = false;
              }),
            )
          else if (widget.mode == EntryMode.summary) ...[
            if (plan != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.entryPlan,
                    style: PbText.label.copyWith(color: c.inkMuted),
                  ),
                  const SizedBox(width: PbSpace.s3),
                  // A long plan shrinks instead of pushing out of the panel.
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: NumberText(
                        summaryLine(
                          context,
                          plan,
                          measure: _exercise.measure,
                          usesBodyWeight: _exercise.usesBodyWeight,
                        ),
                        style: PbText.numSm,
                        color: c.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ..._summary(l10n, c),
          ] else
            ..._perSet(l10n, c),
        ],
      ),
    );
  }

  List<Widget> _summary(AppLocalizations l10n, PbColors c) {
    final last = lastResult(_exercise, widget.earlier);
    final bodyWeight = widget.workout.bodyWeightKg;
    final hints = [
      if (_exercise.usesBodyWeight && bodyWeight != null)
        l10n.entryBodyWeightNote(formatNumber(context, bodyWeight)),
      if (last != null)
        l10n.entryLastTime(
          summaryLine(
            context,
            last,
            measure: _exercise.measure,
            usesBodyWeight: _exercise.usesBodyWeight,
          ).text,
        ),
    ];
    return [
      NumberField(
        label: l10n.entrySets,
        value: '$_setCount',
        style: PbText.numLg,
        onStep: (d) => setState(() => _setCount = (_setCount + d).clamp(1, 20)),
      ),
      ..._valueFields(l10n),
      if (hints.isNotEmpty)
        Text(
          hints.join(' '),
          style: PbText.caption.copyWith(color: c.inkMuted),
        ),
      FilledButton(
        onPressed: () => widget.onRecordSummary(_setCount, _values),
        child: Text(l10n.entryRecord),
      ),
      TextButton(
        onPressed: () => widget.onModeChanged(EntryMode.perSet),
        child: Text(l10n.entryEachSet),
      ),
    ];
  }

  /// Reps or time, then weight. The number the user changes most is the
  /// biggest: weight, or reps and time when there is no weight to speak of.
  List<Widget> _valueFields(AppLocalizations l10n) {
    final weightLeads = !_timed && !_exercise.usesBodyWeight;
    return [
      NumberField(
        label: _timed ? l10n.entryTime : l10n.entryReps,
        value: '$_count',
        unit: _timed ? l10n.unitSec : null,
        style: weightLeads ? PbText.numLg : PbText.numHero,
        onStep: _stepCount,
      ),
      if (!_timed)
        NumberField(
          label: _exercise.usesBodyWeight
              ? l10n.entryExtraWeight
              : l10n.entryWeight,
          value: formatNumber(context, _weightKg),
          unit: l10n.unitKg,
          style: weightLeads ? PbText.numHero : PbText.numLg,
          onStep: (d) => setState(
            () => _weightKg = stepWeight(_weightKg, d * weightStepKg),
          ),
          onTapValue: () => setState(() => _typing = true),
        ),
    ];
  }

  List<Widget> _perSet(AppLocalizations l10n, PbColors c) {
    final sets = _exercise.sets;
    final index = sets.indexWhere((s) => s.id == _setId);
    final number = index < 0 ? sets.length + 1 : index + 1;
    final label = PbText.label.copyWith(color: c.inkMuted);
    return [
      Table(
        columnWidths: const {
          0: FixedColumnWidth(PbSpace.s8),
          3: IntrinsicColumnWidth(),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              Text('№', style: label),
              Text(l10n.entryPlan, style: label),
              Text(l10n.entryFact, style: label),
              const SizedBox(),
            ],
          ),
          for (final (i, set) in sets.indexed)
            TableRow(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.line)),
              ),
              children: [
                for (final cell in _setRow(l10n, c, i, set))
                  TableRowInkWell(
                    onTap: () => setState(() => _select(set)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: PbSpace.s2),
                      child: cell,
                    ),
                  ),
              ],
            ),
        ],
      ),
      ..._valueFields(l10n),
      Text(l10n.entryEffort, style: label),
      // Equal height even when one label wraps to two lines.
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: PbSpace.s2,
          children: [
            for (final effort in Effort.values)
              Expanded(
                child: PbPill(
                  selected: _effort == effort,
                  onTap: () => setState(
                    () => _effort = _effort == effort ? null : effort,
                  ),
                  child: Text(switch (effort) {
                    Effort.more => l10n.effortMore,
                    Effort.some => l10n.effortSome,
                    Effort.none => l10n.effortNone,
                  }, textAlign: TextAlign.center),
                ),
              ),
          ],
        ),
      ),
      FilledButton(
        onPressed: () => index < 0
            ? widget.onExtraSet(_values, _effort?.rpe)
            : widget.onRecordSet(_setId!, _values, _effort?.rpe),
        child: Text(l10n.entryRecordSet(number)),
      ),
      // Wraps when the labels do not fit side by side.
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: index < 0 ? null : () => setState(() => _select(null)),
            child: Text(l10n.entryExtraSet),
          ),
          TextButton(
            onPressed: () => widget.onModeChanged(EntryMode.summary),
            child: Text(l10n.entrySummaryOnly),
          ),
        ],
      ),
    ];
  }

  List<Widget> _setRow(
    AppLocalizations l10n,
    PbColors c,
    int index,
    WorkoutSet set,
  ) {
    final chip = set.id == _setId && set.fact == null
        ? PbChip(l10n.chipNow, color: c.accentText)
        : deviationChip(context, compareSet(set).kind);
    Widget values(SetValues? v, TextStyle style, Color color) => v == null
        ? Text('—', style: style.copyWith(color: c.inkMuted))
        : NumberText(
            setLine(
              context,
              v,
              measure: _exercise.measure,
              usesBodyWeight: _exercise.usesBodyWeight,
            ),
            style: style,
            color: color,
          );
    return [
      Text('${index + 1}', style: PbText.numSm.copyWith(color: c.inkMuted)),
      values(set.plan, PbText.numSm, c.inkMuted),
      values(set.fact, PbText.numMd, c.ink),
      Align(alignment: Alignment.centerRight, child: chip ?? const SizedBox()),
    ];
  }
}
