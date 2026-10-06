import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/assignment_logic.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../router.dart';
import '../../theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/sheet.dart';
import '../history/history_screen.dart';
import '../program/assignment_providers.dart';
import '../program/assignment_sheet.dart';
import '../program/program_providers.dart';
import 'people_providers.dart';
import 'people_screen.dart';

class TraineeScreen extends ConsumerStatefulWidget {
  const TraineeScreen({super.key, required this.traineeId});
  final String traineeId;

  @override
  ConsumerState<TraineeScreen> createState() => _TraineeScreenState();
}

class _TraineeScreenState extends ConsumerState<TraineeScreen> {
  bool _mine = true;
  String? _openId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final links = ref.watch(myTraineesProvider);
    final link = links.value
        ?.where((l) => l.traineeId == widget.traineeId)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          spacing: PbSpace.s3,
          children: [
            if (link != null) PersonAvatar(link.traineeName),
            Expanded(child: Text(link?.traineeName ?? l.traineeTitle)),
          ],
        ),
      ),
      body: GlowBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(PbSpace.s4),
            child: links.hasError
                ? _error(() => ref.invalidate(myTraineesProvider))
                : links.isLoading
                ? const Center(child: CircularProgressIndicator())
                : link == null
                ? Center(child: Text(l.traineeUnavailable))
                : _content(link),
          ),
        ),
      ),
    );
  }

  Widget _error(VoidCallback retry) {
    final l = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l.dataLoadFailed),
        TextButton(onPressed: retry, child: Text(l.retry)),
      ],
    );
  }

  Widget _content(CoachLink link) {
    final l = AppLocalizations.of(context)!;
    final c = context.pb;
    final source = ref.watch(traineeWorkoutsProvider(widget.traineeId));
    final assignments = ref.watch(traineeAssignmentsProvider(widget.traineeId));
    final programs = ref.watch(ownProgramsProvider);
    final workouts = traineeWorkouts(source.value ?? [], link, mineOnly: _mine);
    final openId = _openId ?? workouts.firstOrNull?.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PbSpace.s3,
      children: [
        if (link.status == LinkStatus.readOnly)
          Text(
            l.traineeReadOnly,
            style: PbText.body.copyWith(color: c.inkMuted),
          ),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(l.traineeMine)),
            ButtonSegment(value: false, label: Text(l.traineeAll)),
          ],
          selected: {_mine},
          onSelectionChanged: (value) => setState(() {
            _mine = value.single;
            _openId = null;
          }),
        ),
        Expanded(
          child: ListView(
            children: [
              if (source.hasError)
                _error(
                  () =>
                      ref.invalidate(traineeWorkoutsProvider(widget.traineeId)),
                )
              else if (source.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (workouts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: PbSpace.s4),
                  child: Text(
                    l.traineeEmpty,
                    style: PbText.body.copyWith(color: c.inkMuted),
                  ),
                )
              else
                for (final workout in workouts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: PbSpace.s2),
                    child: GlassCard(
                      onTap: () => setState(() => _openId = workout.id),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: PbSpace.s2,
                        children: [
                          WorkoutHeading(workout),
                          if (workout.id == openId) ...[
                            for (final exercise in workout.exercises)
                              PlanFactRow(
                                exercise,
                                completed: workout.isCompleted,
                              ),
                            if (workout.comment case final comment?)
                              Text(
                                comment,
                                style: PbText.body.copyWith(color: c.inkMuted),
                              ),
                          ],
                          Wrap(
                            spacing: PbSpace.s2,
                            runSpacing: PbSpace.s2,
                            children: workout.isCompleted
                                ? verdictChips(context, workout)
                                : [
                                    Text(
                                      l.homeActiveLabel,
                                      style: PbText.caption.copyWith(
                                        color: c.accentText,
                                      ),
                                    ),
                                  ],
                          ),
                        ],
                      ),
                    ),
                  ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: PbSpace.s3),
                child: Text(
                  l.assignedPrograms,
                  style: PbText.label.copyWith(color: c.inkMuted),
                ),
              ),
              if (assignments.hasError || programs.hasError)
                _error(() {
                  ref.invalidate(traineeAssignmentsProvider(widget.traineeId));
                  ref.invalidate(ownProgramsProvider);
                })
              else if (assignments.isLoading || programs.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                for (final assignment in assignments.value ?? <Assignment>[])
                  if (programs.value
                          ?.where((p) => p.id == assignment.programId)
                          .firstOrNull
                      case final program?)
                    Padding(
                      padding: const EdgeInsets.only(bottom: PbSpace.s2),
                      child: GlassCard(
                        onTap: () => context.push(
                          '${Routes.programBuilder}/${program.id}',
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              program.name,
                              style: PbText.bodyStrong.copyWith(color: c.ink),
                            ),
                            Text(
                              l.assignedOn(
                                DateFormat.yMMMd(
                                  Localizations.localeOf(context).languageCode,
                                ).format(assignment.assignedAt),
                              ),
                              style: PbText.caption.copyWith(color: c.inkMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
        if (link.status == LinkStatus.active)
          FilledButton(
            onPressed: () => showPbSheet<void>(
              context,
              AssignmentSheet(traineeId: widget.traineeId),
            ),
            child: Text(l.assignProgram),
          ),
      ],
    );
  }
}
