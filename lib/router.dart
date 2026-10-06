import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/code_screen.dart';
import 'features/auth/profile_setup_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/exercises/exercise_picker_screen.dart';
import 'features/history/history_screen.dart';
import 'features/history/workout_edit_screen.dart';
import 'features/home/home_screen.dart';
import 'features/people/people_screen.dart';
import 'features/people/trainee_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/program/program_builder_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/shell.dart';
import 'features/workout/workout_screen.dart';

abstract final class Routes {
  static const loading = '/loading';
  static const signIn = '/sign-in';
  static const signInCode = '/sign-in/code';
  static const welcome = '/welcome';
  static const home = '/';
  static const history = '/history';
  static const progress = '/progress';
  static const people = '/people';
  static const profile = '/profile';
  static const programBuilder = '/program';
  static const workout = '/workout';
  static const trainee = '/trainee';
  static const exercisePicker = '/exercises';
  static const exerciseCatalog = '/exercise-catalog';
  static const workoutEdit = '/workout-edit';
}

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);

  GoRoute tab(String path, Widget screen) =>
      GoRoute(path: path, builder: (_, _) => screen);
  GoRoute overlay(String path, Widget screen) => GoRoute(
    path: path,
    parentNavigatorKey: _rootKey,
    builder: (_, _) => screen,
  );

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.home,
    redirect: (_, state) {
      final at = state.matchedLocation;
      return switch (session) {
        Session.loading => Routes.loading,
        Session.signedOut =>
          at == Routes.signIn || at == Routes.signInCode ? null : Routes.signIn,
        Session.needsProfile => Routes.welcome,
        Session.ready =>
          const {
                Routes.loading,
                Routes.signIn,
                Routes.signInCode,
                Routes.welcome,
              }.contains(at)
              ? Routes.home
              : null,
      };
    },
    routes: [
      GoRoute(
        path: Routes.loading,
        builder: (_, _) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(path: Routes.signInCode, builder: (_, _) => const CodeScreen()),
      GoRoute(
        path: Routes.welcome,
        builder: (_, _) => const ProfileSetupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          for (final route in [
            tab(Routes.home, const HomeScreen()),
            tab(Routes.history, const HistoryScreen()),
            tab(Routes.progress, const ProgressScreen()),
            tab(Routes.people, const PeopleScreen()),
            tab(Routes.profile, const ProfileScreen()),
          ])
            StatefulShellBranch(routes: [route]),
        ],
      ),
      overlay(Routes.programBuilder, const ProgramBuilderScreen()),
      GoRoute(
        path: '${Routes.programBuilder}/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            ProgramBuilderScreen(programId: state.pathParameters['id']),
      ),
      overlay(Routes.workout, const WorkoutScreen()),
      GoRoute(
        path: '${Routes.workoutEdit}/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            WorkoutEditScreen(workoutId: state.pathParameters['id']!),
      ),
      overlay(Routes.trainee, const TraineeScreen()),
      overlay(Routes.exercisePicker, const ExercisePickerScreen()),
      overlay(Routes.exerciseCatalog, const ExercisePickerScreen(manage: true)),
    ],
  );
});
