import 'package:flutter_test/flutter_test.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/domain/storage_status.dart';

void main() {
  final workout = Workout(
    id: 'w1',
    traineeId: 'user-1',
    status: WorkoutStatus.inProgress,
    startedAt: DateTime(2026, 10, 8),
    exercises: [
      for (final (id, fact) in [
        ('recorded', const SetValues(reps: 8, weightKg: 60)),
        ('waiting', null),
      ])
        WorkoutExercise(
          id: id,
          exerciseId: id,
          name: id,
          measure: Measure.reps,
          usesBodyWeight: false,
          sets: [WorkoutSet(id: 's1', fact: fact)],
        ),
    ],
  );

  test('server acknowledgement clears pending marks', () {
    const state = WorkoutSyncState(fromCache: false, hasPendingWrites: false);
    expect(state.pendingExercises(workout), isEmpty);
  });

  test('without a connection an already sent result is not pending', () {
    const state = WorkoutSyncState(fromCache: true, hasPendingWrites: false);
    expect(state.pendingExercises(workout), isEmpty);
  });

  test('while sending only recorded exercises get pending marks', () {
    const state = WorkoutSyncState(fromCache: false, hasPendingWrites: true);
    expect(state.pendingExercises(workout), {'recorded'});
  });

  test('a pending document restored offline still marks its results', () {
    const state = WorkoutSyncState(fromCache: true, hasPendingWrites: true);
    expect(state.pendingExercises(workout), {'recorded'});
  });
}
