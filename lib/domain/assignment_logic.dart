import 'models.dart';
import 'workout_logic.dart';

/// Program IDs are scoped to their author, including inside assignments.
String assignmentId(String coachId, String programId) =>
    '${coachId}_$programId';

bool canAssignProgram(String coachId, Program program, CoachLink link) =>
    program.authorId == coachId &&
    link.coachId == coachId &&
    link.traineeId != coachId &&
    link.status == LinkStatus.active &&
    program.name.trim().isNotEmpty;

bool canReadAssignment(Assignment assignment, CoachLink link) =>
    assignment.coachId == link.coachId &&
    assignment.traineeId == link.traineeId &&
    link.status != LinkStatus.removed;

Assignment assignProgram({
  required String coachId,
  required Program program,
  required CoachLink link,
  required DateTime now,
}) {
  if (!canAssignProgram(coachId, program, link)) {
    throw StateError('Only an active coach can assign their own program');
  }
  return Assignment(
    id: assignmentId(coachId, program.id),
    programId: program.id,
    coachId: coachId,
    traineeId: link.traineeId,
    assignedAt: now,
  );
}

/// Includes the current workout. Mine refers to supervision at start,
/// including free workouts and programs written by someone else.
List<Workout> traineeWorkouts(
  Iterable<Workout> workouts,
  CoachLink link, {
  required bool mineOnly,
}) => link.status == LinkStatus.removed
    ? []
    : (workouts
          .where(
            (w) =>
                w.traineeId == link.traineeId &&
                (!mineOnly || w.supervisorCoachId == link.coachId),
          )
          .toList()
        ..sort((a, b) => performedAt(b).compareTo(performedAt(a))));
