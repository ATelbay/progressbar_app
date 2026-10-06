import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/workout_repository.dart';
import '../../domain/models.dart';
import '../../domain/program_logic.dart';
import '../../domain/workout_logic.dart';
import '../../l10n/app_localizations.dart';
import '../../router.dart';
import '../../theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/step_button.dart';
import '../auth/auth_controller.dart';
import '../exercises/personal_exercises_provider.dart';
import '../format.dart';
import '../people/people_providers.dart';
import '../workout/number_field.dart';
import '../workout/workout_providers.dart';
import 'program_providers.dart';

/// Builds a program: days, exercises in a day, planned sets. Every change is
/// saved at once, as soon as the program has a name.
class ProgramBuilderScreen extends ConsumerStatefulWidget {
  const ProgramBuilderScreen({super.key, this.programId});

  /// Null for a new program.
  final String? programId;

  @override
  ConsumerState<ProgramBuilderScreen> createState() =>
      _ProgramBuilderScreenState();
}

class _ProgramBuilderScreenState extends ConsumerState<ProgramBuilderScreen> {
  final _name = TextEditingController();
  Program? _program;
  String? _dayId;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Opens the stored program once it is loaded, or starts a new one.
  Program? _open(AppLocalizations l10n) {
    if (_program != null) return _program;
    final uid = ref.watch(uidProvider).value;
    final programs = ref.watch(ownProgramsProvider).value;
    if (uid == null) return null;
    final newId = ref.read(newIdProvider);
    if (widget.programId == null) {
      _program = Program(
        id: newId(),
        authorId: uid,
        name: '',
        days: [
          ProgramDay(
            id: newId(),
            name: l10n.builderDayDefault(1),
            exercises: const [],
          ),
        ],
      );
    } else {
      _program = programs?.where((p) => p.id == widget.programId).firstOrNull;
    }
    _name.text = _program?.name ?? '';
    _dayId = _program?.days.firstOrNull?.id;
    return _program;
  }

  /// Applies an edit and stores it. A program without a name is not stored.
  void _apply(Program program) {
    final named = renameProgram(program, _name.text.trim());
    setState(() => _program = named);
    if (named.name.isNotEmpty) {
      unawaited(ref.read(programRepositoryProvider).save(named));
    }
  }

  void _addDay(Program program, AppLocalizations l10n) {
    final id = ref.read(newIdProvider)();
    _dayId = id;
    _apply(
      addDay(
        program,
        id: id,
        name: l10n.builderDayDefault(program.days.length + 1),
      ),
    );
  }

  Future<void> _editDay(Program program, ProgramDay day) async {
    final result = await showModalBottomSheet<_DayEdit>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: context.pb.scrim,
      isScrollControlled: true,
      builder: (_) => _DaySheet(day: day, canDelete: program.days.length > 1),
    );
    if (result == null || !mounted) return;
    if (result.delete) {
      _dayId = program.days.where((d) => d.id != day.id).first.id;
      _apply(removeDay(program, day.id));
    } else if (result.name.isNotEmpty) {
      _apply(renameDay(program, day.id, result.name));
    }
  }

  Future<void> _editExercise(
    Program program,
    ProgramDay day,
    Exercise exercise, {
    ProgramExercise? planned,
  }) async {
    final result = await showModalBottomSheet<_PlanEdit>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: context.pb.scrim,
      isScrollControlled: true,
      builder: (_) => _PlanSheet(exercise: exercise, planned: planned),
    );
    if (result == null || !mounted) return;
    final id = planned?.id ?? ref.read(newIdProvider)();
    _apply(
      result.remove
          ? removeExercise(program, day.id, id)
          : putExercise(
              program,
              day.id,
              ProgramExercise(
                id: id,
                exerciseId: exercise.id,
                sets: uniformSets(result.setCount, result.values),
                note: result.note.isEmpty ? null : result.note,
              ),
            ),
    );
  }

  Future<void> _addExercise(Program program, ProgramDay day) async {
    final exercise = await context.push<Exercise>(Routes.exercisePicker);
    if (exercise == null || !mounted) return;
    await _editExercise(program, day, exercise);
  }

  Future<void> _start(
    Program program,
    ProgramDay day,
    Map<String, Exercise> catalog,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final newId = ref.read(newIdProvider);
    final workout = startWorkout(
      id: newId(),
      traineeId: program.authorId,
      now: DateTime.now(),
      newId: newId,
      catalog: catalog,
      languageCode: Localizations.localeOf(context).languageCode,
      program: program,
      day: day,
      supervisorCoachId: ref.read(activeCoachProvider)?.coachId,
      bodyWeightKg: ref.read(profileProvider).value?.bodyWeightKg,
    );
    try {
      await ref.read(workoutRepositoryProvider).start(workout);
    } on ActiveWorkoutExists {
      messenger.showSnackBar(SnackBar(content: Text(l10n.builderActiveExists)));
      return;
    } on WorkoutStoreUnavailable {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.errorStoreUnavailable)),
      );
      return;
    }
    if (mounted) context.pushReplacement(Routes.workout);
  }

  Future<void> _delete(Program program) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.builderDeleteConfirm(program.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.builderKeep),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: context.pb.danger),
            child: Text(l10n.builderDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    unawaited(ref.read(programRepositoryProvider).delete(program));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final program = _open(l10n);
    final catalog = ref.watch(userCatalogProvider).value;
    if (program == null || catalog == null) {
      return const Scaffold(
        body: GlowBackground(child: Center(child: CircularProgressIndicator())),
      );
    }
    final day =
        program.days.where((d) => d.id == _dayId).firstOrNull ??
        program.days.first;
    final language = Localizations.localeOf(context).languageCode;
    final stored = program.name.isNotEmpty;

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
                      child: TextField(
                        controller: _name,
                        autofocus: widget.programId == null,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        style: PbText.title.copyWith(color: c.ink),
                        // The title is edited in place, without a field frame.
                        decoration: InputDecoration(
                          isCollapsed: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: l10n.builderNameHint,
                          hintStyle: PbText.title.copyWith(color: c.inkMuted),
                        ),
                        onChanged: (_) => _apply(program),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: PbSize.touchMin,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: [
                      for (final d in program.days)
                        Padding(
                          padding: const EdgeInsets.only(right: PbSpace.s2),
                          child: PbPill(
                            selected: d.id == day.id,
                            // A second tap on the open day edits it.
                            onTap: () => d.id == day.id
                                ? _editDay(program, d)
                                : setState(() => _dayId = d.id),
                            child: Text(d.name),
                          ),
                        ),
                      PbPill(
                        tooltip: l10n.builderAddDay,
                        onTap: () => _addDay(program, l10n),
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      if (day.exercises.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: PbSpace.s3,
                          ),
                          child: Text(
                            l10n.builderEmptyDay,
                            style: PbText.body.copyWith(color: c.inkMuted),
                          ),
                        ),
                      for (final planned in day.exercises)
                        if (catalog[planned.exerciseId] case final exercise?)
                          Padding(
                            padding: const EdgeInsets.only(bottom: PbSpace.s2),
                            child: _PlannedCard(
                              name: exercise.nameFor(language),
                              exercise: exercise,
                              planned: planned,
                              onTap: () => _editExercise(
                                program,
                                day,
                                exercise,
                                planned: planned,
                              ),
                            ),
                          ),
                      OutlinedButton.icon(
                        onPressed: () => _addExercise(program, day),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.pickerTitle),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: stored && canStartDay(day, catalog)
                      ? () => _start(program, day, catalog)
                      : null,
                  child: Text(l10n.builderStart),
                ),
                if (stored && widget.programId != null)
                  TextButton(
                    onPressed: () => _delete(program),
                    style: TextButton.styleFrom(foregroundColor: c.danger),
                    child: Text(l10n.builderDeleteProgram),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlannedCard extends StatelessWidget {
  const _PlannedCard({
    required this.name,
    required this.exercise,
    required this.planned,
    required this.onTap,
  });

  final String name;
  final Exercise exercise;
  final ProgramExercise planned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final plan = summarizeSets(planned.sets);
    final caption = PbText.caption.copyWith(color: c.inkMuted);
    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: PbSpace.s1,
        children: [
          Row(
            spacing: PbSpace.s3,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: PbText.bodyStrong.copyWith(color: c.ink)),
                    if (exercise.measure == Measure.time)
                      Text(l10n.builderTimed, style: caption)
                    else if (exercise.usesBodyWeight)
                      Text(l10n.builderBodyWeight, style: caption),
                  ],
                ),
              ),
              if (plan != null)
                NumberText(
                  summaryLine(
                    context,
                    plan,
                    measure: exercise.measure,
                    usesBodyWeight: exercise.usesBodyWeight,
                  ),
                  style: PbText.numSm,
                  beside: true,
                ),
            ],
          ),
          if (planned.note case final note?)
            Text(l10n.builderNotePrefix(note), style: caption),
        ],
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      // Stays above the on-screen keyboard.
      padding: EdgeInsets.fromLTRB(
        PbSpace.s2,
        PbSpace.s2,
        PbSpace.s2,
        PbSpace.s2 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: GlassPanel(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: PbSpace.s3,
            children: children,
          ),
        ),
      ),
    ),
  );
}

typedef _DayEdit = ({String name, bool delete});

class _DaySheet extends StatefulWidget {
  const _DaySheet({required this.day, required this.canDelete});

  final ProgramDay day;
  final bool canDelete;

  @override
  State<_DaySheet> createState() => _DaySheetState();
}

class _DaySheetState extends State<_DaySheet> {
  late final _name = TextEditingController(text: widget.day.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _close({bool delete = false}) =>
      Navigator.pop(context, (name: _name.text.trim(), delete: delete));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    return _Sheet(
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          style: PbText.heading.copyWith(color: c.ink),
          decoration: InputDecoration(labelText: l10n.builderDayName),
          onSubmitted: (_) => _close(),
        ),
        FilledButton(onPressed: _close, child: Text(l10n.welcomeDone)),
        if (widget.canDelete)
          TextButton(
            onPressed: () => _close(delete: true),
            style: TextButton.styleFrom(foregroundColor: c.danger),
            child: Text(l10n.builderRemoveDay),
          ),
      ],
    );
  }
}

typedef _PlanEdit = ({
  int setCount,
  SetValues values,
  String note,
  bool remove,
});

/// The plan for one exercise in one line: sets × reps or time × weight.
class _PlanSheet extends StatefulWidget {
  const _PlanSheet({required this.exercise, this.planned});

  final Exercise exercise;
  final ProgramExercise? planned;

  @override
  State<_PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends State<_PlanSheet> {
  late final _note = TextEditingController(text: widget.planned?.note ?? '');
  late int _setCount = widget.planned?.sets.length ?? 3;
  late int _count =
      widget.planned?.sets.firstOrNull?.reps ??
      widget.planned?.sets.firstOrNull?.seconds ??
      (_timed ? 30 : 10);
  late double _weightKg = widget.planned?.sets.firstOrNull?.weightKg ?? 0;

  bool get _timed => widget.exercise.measure == Measure.time;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _close({bool remove = false}) => Navigator.pop(context, (
    setCount: _setCount,
    values: _timed
        ? SetValues(seconds: _count, weightKg: _weightKg)
        : SetValues(reps: _count, weightKg: _weightKg),
    note: _note.text.trim(),
    remove: remove,
  ));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final exercise = widget.exercise;
    final step = _timed ? secondsStep : 1;
    return _Sheet(
      children: [
        Text(
          exercise.nameFor(Localizations.localeOf(context).languageCode),
          style: PbText.heading.copyWith(color: c.ink),
        ),
        NumberField(
          label: l10n.entrySets,
          value: '$_setCount',
          style: PbText.numLg,
          onStep: (d) =>
              setState(() => _setCount = (_setCount + d).clamp(1, 20)),
        ),
        NumberField(
          label: _timed ? l10n.entryTime : l10n.entryReps,
          value: '$_count',
          unit: _timed ? l10n.unitSec : null,
          style: PbText.numLg,
          onStep: (d) =>
              setState(() => _count = (_count + d * step).clamp(step, 999)),
        ),
        if (!_timed)
          NumberField(
            label: exercise.usesBodyWeight
                ? l10n.entryExtraWeight
                : l10n.entryWeight,
            value: formatNumber(context, _weightKg),
            unit: l10n.unitKg,
            style: PbText.numLg,
            onStep: (d) => setState(
              () => _weightKg = stepWeight(_weightKg, d * weightStepKg),
            ),
          ),
        TextField(
          controller: _note,
          textCapitalization: TextCapitalization.sentences,
          style: PbText.body.copyWith(color: c.ink),
          decoration: InputDecoration(labelText: l10n.builderNote),
        ),
        FilledButton(onPressed: _close, child: Text(l10n.welcomeDone)),
        if (widget.planned != null)
          TextButton(
            onPressed: () => _close(remove: true),
            style: TextButton.styleFrom(foregroundColor: c.danger),
            child: Text(l10n.builderRemoveExercise),
          ),
      ],
    );
  }
}
