import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/progress_logic.dart';
import '../workout/workout_providers.dart';

/// Every exercise with points, most recently done first.
final progressOverviewProvider = Provider<AsyncValue<List<ExerciseProgress>>>(
  (ref) => ref.watch(completedWorkoutsProvider).whenData(progressOverview),
);

/// The metric picked on an exercise's chart. It stays for the session and
/// applies to every exercise that has it; the others show their main one.
class ProgressMetricChoice extends Notifier<ProgressMetric> {
  @override
  ProgressMetric build() => ProgressMetric.estimatedMax;

  void set(ProgressMetric metric) => state = metric;
}

final progressMetricProvider =
    NotifierProvider<ProgressMetricChoice, ProgressMetric>(
      ProgressMetricChoice.new,
    );
