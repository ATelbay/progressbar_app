/// How an exercise is measured.
enum Measure { reps, time }

enum WorkoutStatus { inProgress, completed }

/// State of a coach–trainee link, always set by the trainee.
/// [active] may assign programs; [readOnly] only sees workouts; [removed] sees nothing.
enum LinkStatus { active, readOnly, removed }

/// Side of the link the inviter takes.
enum LinkRole { coach, trainee }

/// How the user prefers to enter results.
enum EntryMode { summary, perSet }

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.bodyWeightKg,
    this.entryMode = EntryMode.summary,
    this.lastSetCount,
    this.languageCode,
  });

  final String id;
  final String name;
  final String phone;
  final double? bodyWeightKg;
  final EntryMode entryMode;

  /// Number of sets last entered in summary mode, reused for the next entry.
  final int? lastSetCount;

  /// Interface language the user chose; null follows the phone.
  final String? languageCode;

  /// [languageCode] is a function so that it can also be set back to null.
  UserProfile copyWith({
    String? name,
    double? bodyWeightKg,
    EntryMode? entryMode,
    int? lastSetCount,
    String? Function()? languageCode,
  }) => UserProfile(
    id: id,
    name: name ?? this.name,
    phone: phone,
    bodyWeightKg: bodyWeightKg ?? this.bodyWeightKg,
    entryMode: entryMode ?? this.entryMode,
    lastSetCount: lastSetCount ?? this.lastSetCount,
    languageCode: languageCode == null ? this.languageCode : languageCode(),
  );
}

/// A catalog entry. Built-in exercises have no [ownerId] and carry a name per
/// language; a user's own exercise has one name under its [ownerId].
class Exercise {
  const Exercise({
    required this.id,
    required this.names,
    required this.muscleGroup,
    this.equipment,
    this.measure = Measure.reps,
    this.usesBodyWeight = false,
    this.ownerId,
  });

  final String id;

  /// Language code → name.
  final Map<String, String> names;
  final String muscleGroup;
  final String? equipment;
  final Measure measure;
  final bool usesBodyWeight;
  final String? ownerId;

  String nameFor(String languageCode) =>
      names[languageCode] ?? names['en'] ?? names.values.first;
}

/// One set as numbers: reps or seconds, with weight. For a body-weight
/// exercise [weightKg] is the extra weight and may be zero.
class SetValues {
  const SetValues({this.reps, this.seconds, this.weightKg = 0});

  final int? reps;
  final int? seconds;
  final double weightKg;

  @override
  bool operator ==(Object other) =>
      other is SetValues &&
      other.reps == reps &&
      other.seconds == seconds &&
      other.weightKg == weightKg;

  @override
  int get hashCode => Object.hash(reps, seconds, weightKg);

  @override
  String toString() => 'SetValues($weightKg kg × ${reps ?? '${seconds}s'})';
}

class ProgramExercise {
  const ProgramExercise({
    required this.id,
    required this.exerciseId,
    required this.sets,
    this.note,
  });

  final String id;
  final String exerciseId;

  /// Planned sets, in order.
  final List<SetValues> sets;

  /// Coach's note shown to the trainee.
  final String? note;
}

class ProgramDay {
  const ProgramDay({
    required this.id,
    required this.name,
    required this.exercises,
  });

  final String id;
  final String name;
  final List<ProgramExercise> exercises;
}

class Program {
  const Program({
    required this.id,
    required this.authorId,
    required this.name,
    required this.days,
  });

  final String id;

  /// The user who wrote the program: a coach, or the trainee in solo mode.
  final String authorId;
  final String name;
  final List<ProgramDay> days;
}

/// A program given to a trainee. A solo user has no assignments: they simply
/// own their programs.
class Assignment {
  const Assignment({
    required this.id,
    required this.programId,
    required this.coachId,
    required this.traineeId,
    required this.assignedAt,
  });

  final String id;
  final String programId;
  final String coachId;
  final String traineeId;
  final DateTime assignedAt;
}

class CoachLink {
  const CoachLink({
    required this.id,
    required this.coachId,
    required this.traineeId,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String coachId;
  final String traineeId;
  final LinkStatus status;
  final DateTime createdAt;
}

class Invitation {
  const Invitation({
    required this.code,
    required this.inviterId,
    required this.inviterRole,
    required this.createdAt,
  });

  final String code;
  final String inviterId;

  /// The role the inviter takes; the person who accepts takes the other one.
  final LinkRole inviterRole;
  final DateTime createdAt;
}

class WorkoutSet {
  const WorkoutSet({required this.id, this.plan, this.fact, this.rpe});

  final String id;

  /// Copied from the program when the workout starts; null for an extra set.
  final SetValues? plan;

  /// What was actually done; null until recorded.
  final SetValues? fact;

  /// Perceived effort, 1–10 in steps of 0.5.
  final double? rpe;

  bool get isExtra => plan == null;

  WorkoutSet withFact(SetValues? fact, {double? rpe}) => WorkoutSet(
    id: id,
    plan: plan,
    fact: fact,
    rpe: fact == null ? null : rpe,
  );
}

/// An exercise inside a workout. Name, measure and note are copies taken at
/// start, so later edits to the catalog or program do not rewrite history.
class WorkoutExercise {
  const WorkoutExercise({
    required this.id,
    required this.exerciseId,
    required this.name,
    required this.measure,
    required this.usesBodyWeight,
    required this.sets,
    this.note,
  });

  final String id;
  final String exerciseId;
  final String name;
  final Measure measure;
  final bool usesBodyWeight;
  final List<WorkoutSet> sets;
  final String? note;

  bool get hasFact => sets.any((s) => s.fact != null);

  WorkoutExercise withSets(List<WorkoutSet> sets) => WorkoutExercise(
    id: id,
    exerciseId: exerciseId,
    name: name,
    measure: measure,
    usesBodyWeight: usesBodyWeight,
    sets: sets,
    note: note,
  );
}

class Workout {
  const Workout({
    required this.id,
    required this.traineeId,
    required this.status,
    required this.startedAt,
    required this.exercises,
    this.supervisorCoachId,
    this.programId,
    this.programName,
    this.dayName,
    this.completedAt,
    this.editedAt,
    this.comment,
    this.bodyWeightKg,
  });

  final String id;

  /// Every workout belongs to the trainee.
  final String traineeId;

  /// The trainee's active coach when the workout started, if any. A coach sees
  /// a workout as «theirs» by this field.
  final String? supervisorCoachId;

  /// Null for a workout without a program.
  final String? programId;
  final String? programName;
  final String? dayName;
  final WorkoutStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;

  /// Set when a completed workout is corrected.
  final DateTime? editedAt;
  final String? comment;

  /// Trainee's body weight at start, for body-weight exercises.
  final double? bodyWeightKg;
  final List<WorkoutExercise> exercises;

  bool get isCompleted => status == WorkoutStatus.completed;
  bool get editedAfterCompletion => editedAt != null;

  Workout copyWith({
    WorkoutStatus? status,
    DateTime? completedAt,
    DateTime? editedAt,
    String? comment,
    List<WorkoutExercise>? exercises,
  }) => Workout(
    id: id,
    traineeId: traineeId,
    supervisorCoachId: supervisorCoachId,
    programId: programId,
    programName: programName,
    dayName: dayName,
    status: status ?? this.status,
    startedAt: startedAt,
    completedAt: completedAt ?? this.completedAt,
    editedAt: editedAt ?? this.editedAt,
    comment: comment ?? this.comment,
    bodyWeightKg: bodyWeightKg,
    exercises: exercises ?? this.exercises,
  );
}
