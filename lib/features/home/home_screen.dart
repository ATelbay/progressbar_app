import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/workout_repository.dart';
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
import '../people/people_providers.dart';
import '../program/program_providers.dart';
import '../program/assignment_providers.dart';
import '../workout/workout_providers.dart';
import '../workout/workout_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _startFree(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(uidProvider).value;
    if (uid == null) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final newId = ref.read(newIdProvider);
    final workout = startWorkout(
      id: newId(),
      traineeId: uid,
      now: DateTime.now(),
      newId: newId,
      catalog: const {},
      languageCode: Localizations.localeOf(context).languageCode,
      supervisorCoachId: ref.read(activeCoachProvider)?.coachId,
      supervisorCoachName: ref.read(activeCoachProvider)?.coachName,
      bodyWeightKg: ref.read(profileProvider).value?.bodyWeightKg,
    );
    try {
      await ref.read(workoutRepositoryProvider).start(workout);
    } on ActiveWorkoutExists {
      // Already running: just open it.
    } on WorkoutStoreUnavailable {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.errorStoreUnavailable)),
      );
      return;
    }
    if (context.mounted) context.push(Routes.workout);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    // Watched from the first screen after sign-in, so a start without a
    // network already knows whether a workout is in progress.
    final active = ref.watch(activeWorkoutProvider).value;
    final programs = ref.watch(ownProgramsProvider).value ?? const <Program>[];
    final assigned = ref.watch(availableAssignmentsProvider);
    final assignments = assigned.value ?? <Assignment>[];
    final empty =
        active == null &&
        programs.isEmpty &&
        assignments.isEmpty &&
        !assigned.isLoading &&
        !assigned.hasError;

    void newProgram() => context.push(Routes.programBuilder);
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(PbSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: PbSpace.s3,
              children: [
                Text(l10n.tabHome, style: PbText.title.copyWith(color: c.ink)),
                Expanded(
                  child: empty
                      ? const _EmptyHome()
                      : ListView(
                          children: [
                            if (active != null) _ActiveWorkout(active),
                            if (assigned.isLoading)
                              const Center(child: CircularProgressIndicator()),
                            if (assigned.hasError) ...[
                              Text(l10n.dataLoadFailed),
                              TextButton(
                                onPressed: () {
                                  ref.invalidate(ownAssignmentsProvider);
                                  ref.invalidate(myCoachesProvider);
                                },
                                child: Text(l10n.retry),
                              ),
                            ],
                            if (programs.isNotEmpty ||
                                assignments.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: PbSpace.s3,
                                ),
                                child: Text(
                                  l10n.homeMyPrograms,
                                  style: PbText.label.copyWith(
                                    color: c.inkMuted,
                                  ),
                                ),
                              ),
                              for (final assignment in assignments)
                                _AssignedCard(assignment),
                              for (final program in programs)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: PbSpace.s2,
                                  ),
                                  child: _ProgramCard(program),
                                ),
                            ],
                          ],
                        ),
                ),
                if (empty) ...[
                  FilledButton(
                    onPressed: newProgram,
                    child: Text(l10n.homeNewProgram),
                  ),
                  OutlinedButton(
                    onPressed: () => _startFree(context, ref),
                    child: Text(l10n.homeStartFreeWorkout),
                  ),
                ] else ...[
                  if (active == null)
                    OutlinedButton(
                      onPressed: () => _startFree(context, ref),
                      child: Text(l10n.homeStartFreeWorkout),
                    ),
                  TextButton(
                    onPressed: newProgram,
                    child: Text(l10n.homeNewProgram),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveWorkout extends StatelessWidget {
  const _ActiveWorkout(this.workout);

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final done = recordedCount(workout);
    final total = workout.exercises.length;
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PbSpace.s3,
        children: [
          Text(
            l10n.homeActiveLabel,
            style: PbText.label.copyWith(color: c.inkMuted),
          ),
          Text(
            workout.dayName ?? l10n.workoutTitle,
            style: PbText.heading.copyWith(color: c.ink),
          ),
          Barbell(
            plates: platesOf(workout, currentId: nextExercise(workout)?.id),
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
          FilledButton(
            onPressed: () => context.push(Routes.workout),
            child: Text(l10n.homeContinue),
          ),
        ],
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard(this.program, {this.coachName});

  final Program program;
  final String? coachName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    return GlassCard(
      onTap: () => context.push(
        coachName == null
            ? '${Routes.programBuilder}/${program.id}'
            : '${Routes.assignedProgram}/${program.authorId}/${program.id}',
      ),
      child: Row(
        spacing: PbSpace.s3,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  program.name,
                  style: PbText.bodyStrong.copyWith(color: c.ink),
                ),
                Text(
                  coachName == null
                      ? l10n.homeOwnProgram
                      : l10n.assignedBy(coachName!),
                  style: PbText.caption.copyWith(color: c.inkMuted),
                ),
              ],
            ),
          ),
          PbChip(l10n.homeDays(program.days.length)),
        ],
      ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: PbSpace.s3,
          children: [
            Barbell(
              plates: List.filled(5, Plate.waiting),
              label: l10n.homeEmptyTitle,
            ),
            Text(
              l10n.homeEmptyTitle,
              style: PbText.heading.copyWith(color: c.ink),
            ),
            Text(
              l10n.homeEmptyText,
              style: PbText.body.copyWith(color: c.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignedCard extends ConsumerWidget {
  const _AssignedCard(this.assignment);
  final Assignment assignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final key = (authorId: assignment.coachId, programId: assignment.programId);
    final source = ref.watch(sharedProgramProvider(key));
    final name =
        ref
            .watch(myCoachesProvider)
            .value
            ?.where((link) => link.coachId == assignment.coachId)
            .firstOrNull
            ?.coachName ??
        '';
    return Padding(
      padding: const EdgeInsets.only(bottom: PbSpace.s2),
      child: source.when(
        skipLoadingOnReload: false,
        data: (program) => program == null
            ? Text(l.programUnavailable)
            : _ProgramCard(program, coachName: name),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Column(
          children: [
            Text(l.programUnavailable),
            TextButton(
              onPressed: () => ref.invalidate(sharedProgramProvider(key)),
              child: Text(l.retry),
            ),
          ],
        ),
      ),
    );
  }
}
