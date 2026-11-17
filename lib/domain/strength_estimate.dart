import 'models.dart';

/// Epley's estimate of a one-rep max, `weight × (1 + reps / 30)`, and the
/// weight itself for a single rep. Rounded to half a kilogram, so that two
/// sets compare the way they read. Null without weight or reps.
double? estimatedMaxKg(SetValues set) {
  final reps = set.reps;
  if (reps == null || reps < 1 || set.weightKg <= 0) return null;
  final estimate = reps == 1 ? set.weightKg : set.weightKg * (1 + reps / 30);
  return (estimate * 2).round() / 2;
}
