import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/history/history_screen.dart';
import 'features/home/home_screen.dart';
import 'features/people/people_screen.dart';
import 'features/people/trainee_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/program/program_builder_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/shell.dart';
import 'features/workout/workout_screen.dart';

abstract final class Routes {
  static const signIn = '/sign-in';
  static const home = '/';
  static const history = '/history';
  static const progress = '/progress';
  static const people = '/people';
  static const profile = '/profile';
  static const programBuilder = '/program';
  static const workout = '/workout';
  static const trainee = '/trainee';
}

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final signedIn = ref.watch(authControllerProvider);

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
      final atSignIn = state.matchedLocation == Routes.signIn;
      if (!signedIn) return atSignIn ? null : Routes.signIn;
      return atSignIn ? Routes.home : null;
    },
    routes: [
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
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
      overlay(Routes.workout, const WorkoutScreen()),
      overlay(Routes.trainee, const TraineeScreen()),
    ],
  );
});
