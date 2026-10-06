import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/assignment_logic.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../widgets/sheet.dart';
import '../auth/auth_controller.dart';
import '../people/people_providers.dart';
import 'assignment_providers.dart';
import 'program_providers.dart';

/// One side is fixed; choose the program on a trainee's screen or the
/// trainee in the builder. Watches links even while the sheet is open.
class AssignmentSheet extends ConsumerStatefulWidget {
  const AssignmentSheet({super.key, this.program, this.traineeId})
    : assert((program == null) != (traineeId == null));
  final Program? program;
  final String? traineeId;

  @override
  ConsumerState<AssignmentSheet> createState() => _AssignmentSheetState();
}

class _AssignmentSheetState extends ConsumerState<AssignmentSheet> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _assign(Program program, CoachLink link) async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final uid = ref.read(uidProvider).value!;
      final current = ref
          .read(myTraineesProvider)
          .value!
          .firstWhere((l) => l.id == link.id);
      final assignment = assignProgram(
        coachId: uid,
        program: program,
        link: current,
        now: DateTime.now(),
      );
      await ref.read(assignmentRepositoryProvider).assign(assignment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.assignSuccess)),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final links = ref.watch(myTraineesProvider);
    final programs = ref.watch(ownProgramsProvider);
    final uid = ref.watch(uidProvider).value;
    final options = <(Program, CoachLink)>[
      for (final link in links.value ?? <CoachLink>[])
        if (widget.traineeId == null || link.traineeId == widget.traineeId)
          for (final program
              in widget.program == null
                  ? programs.value ?? <Program>[]
                  : [widget.program!])
            if (uid != null && canAssignProgram(uid, program, link))
              (program, link),
    ];
    return PbSheet(
      children: [
        Text(
          widget.program == null ? l.assignProgram : l.assignTrainee,
          style: PbText.heading.copyWith(color: context.pb.ink),
        ),
        if (_failed)
          Text(l.assignFailed, style: TextStyle(color: context.pb.danger)),
        if (links.hasError ||
            (widget.program == null && programs.hasError)) ...[
          Text(l.dataLoadFailed),
          TextButton(
            onPressed: () {
              ref.invalidate(myTraineesProvider);
              ref.invalidate(ownProgramsProvider);
            },
            child: Text(l.retry),
          ),
        ] else if (links.isLoading ||
            (widget.program == null && programs.isLoading))
          const Center(child: CircularProgressIndicator())
        else if (options.isEmpty)
          Text(
            widget.program == null
                ? l.assignEmptyPrograms
                : l.assignEmptyTrainees,
          )
        else ...[
          for (final (program, link) in options)
            OutlinedButton(
              onPressed: _busy ? null : () => _assign(program, link),
              child: Text(
                widget.program == null ? program.name : link.traineeName,
              ),
            ),
        ],
        if (_busy) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
