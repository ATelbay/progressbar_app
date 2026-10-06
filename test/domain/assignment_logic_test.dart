import 'package:flutter_test/flutter_test.dart';
import 'package:progressbar_app/domain/assignment_logic.dart';
import 'package:progressbar_app/domain/exercise_catalog.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/domain/program_logic.dart';
import 'package:progressbar_app/domain/workout_logic.dart';

void main() {
  final now = DateTime(2026, 10, 6);
  CoachLink link(LinkStatus status) => CoachLink(
    id: 'coach_trainee',
    coachId: 'coach',
    traineeId: 'trainee',
    status: status,
    createdAt: now,
  );
  const custom = Exercise(
    id: 'custom/one',
    names: {'ru': 'Тяга тренера'},
    muscleGroup: 'lats',
    ownerId: 'coach',
  );
  const day = ProgramDay(
    id: 'day',
    name: 'Спина',
    exercises: [
      ProgramExercise(
        id: 'planned',
        exerciseId: 'custom/one',
        sets: [SetValues(reps: 8, weightKg: 40)],
        note: 'Пауза',
      ),
    ],
  );
  const program = Program(
    id: 'p',
    authorId: 'coach',
    name: 'Сила',
    days: [day],
  );

  test('only an active coach can assign a program they own', () {
    final assignment = assignProgram(
      coachId: 'coach',
      program: program,
      link: link(LinkStatus.active),
      now: now,
    );
    expect(assignment.traineeId, 'trainee');
    expect(assignment.id, assignmentId('coach', 'p'));
    for (final status in [LinkStatus.readOnly, LinkStatus.removed]) {
      expect(
        () => assignProgram(
          coachId: 'coach',
          program: program,
          link: link(status),
          now: now,
        ),
        throwsStateError,
      );
    }
    expect(
      canAssignProgram('other', program, link(LinkStatus.active)),
      isFalse,
    );
    expect(
      canAssignProgram(
        'coach',
        const Program(id: 'p', authorId: 'other', name: 'Чужая', days: []),
        link(LinkStatus.active),
      ),
      isFalse,
    );
    expect(assignmentId('other', 'p'), isNot(assignment.id));
    expect(canReadAssignment(assignment, link(LinkStatus.readOnly)), isTrue);
    expect(canReadAssignment(assignment, link(LinkStatus.removed)), isFalse);
  });

  test('mine uses supervision, all includes current and other coaches', () {
    Workout workout(
      String id,
      String? coach,
      int hour, {
      String trainee = 'trainee',
    }) => Workout(
      id: id,
      traineeId: trainee,
      supervisorCoachId: coach,
      status: WorkoutStatus.inProgress,
      startedAt: now.add(Duration(hours: hour)),
      exercises: const [],
    );
    final workouts = [
      workout('mine', 'coach', 1),
      workout('other', 'next', 2),
      workout('free', null, 0),
      workout('stranger', 'coach', 3, trainee: 'else'),
    ];
    expect(
      traineeWorkouts(
        workouts,
        link(LinkStatus.active),
        mineOnly: true,
      ).map((w) => w.id),
      ['mine'],
    );
    expect(
      traineeWorkouts(
        workouts,
        link(LinkStatus.readOnly),
        mineOnly: false,
      ).map((w) => w.id),
      ['other', 'mine', 'free'],
    );
    expect(
      traineeWorkouts(workouts, link(LinkStatus.removed), mineOnly: false),
      isEmpty,
    );
  });

  test(
    'assigned day belongs to trainee and snapshots author catalog and coach',
    () {
      final catalog = mergeCatalog({}, [custom]);
      expect(canStartDay(day, {}), isFalse);
      expect(canStartDay(day, catalog), isTrue);
      var id = 0;
      final workout = startWorkout(
        id: 'w',
        traineeId: 'trainee',
        now: now,
        newId: () => '${id++}',
        catalog: catalog,
        languageCode: 'ru',
        program: program,
        day: day,
        supervisorCoachId: 'newCoach',
        supervisorCoachName: 'Мадина',
        bodyWeightKg: 70,
      );
      expect(workout.traineeId, 'trainee');
      expect(workout.supervisorCoachId, 'newCoach');
      expect(workout.copyWith(comment: 'Done').supervisorCoachName, 'Мадина');
      expect(workout.exercises.single.name, 'Тяга тренера');
      expect(workout.exercises.single.note, 'Пауза');
      final edited = removeExercise(program, 'day', 'planned');
      expect(edited.days.single.exercises, isEmpty);
      expect(workout.exercises.single.sets.single.plan!.weightKg, 40);
    },
  );
}
