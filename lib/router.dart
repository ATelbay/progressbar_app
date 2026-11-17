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
import 'domain/link_logic.dart';
import 'features/people/invite_screens.dart';
import 'features/people/people_providers.dart';
import 'features/people/people_screen.dart';
import 'features/people/trainee_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/program/program_builder_screen.dart';
import 'features/progress/progress_detail_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/shell.dart';
import 'features/workout/workout_screen.dart';
import 'widgets/navigation_motion.dart';

abstract final class Routes {
  static const loading = '/loading';
  static const signIn = '/sign-in';
  static const signInCode = '/sign-in/code';
  static const welcome = '/welcome';
  static const home = '/';
  static const history = '/history';
  static const progress = '/progress';

  /// One exercise's chart; catalog IDs contain «/», so the ID is encoded.
  static String progressOf(String exerciseId) =>
      '$progress/${Uri.encodeComponent(exerciseId)}';
  static const people = '/people';
  static const profile = '/profile';
  static const programBuilder = '/program';
  static const workout = '/workout';
  static const trainee = '/trainee';
  static const assignedProgram = '/assigned';
  static const invite = '/invite';
  static const inviteAccept = '/invite-accept';
  static const join = '/join';
  static const exercisePicker = '/exercises';
  static const exerciseCatalog = '/exercise-catalog';
  static const workoutEdit = '/workout-edit';
}

final _rootKey = GlobalKey<NavigatorState>();

class _Launch {
  bool routed = false;
}

final _launchProvider = Provider((ref) => _Launch());

// Use the same MaterialPage type as our app/theme. Relying on go_router's
// app-type detection can otherwise fall back to pages without transitions.
MaterialPage<void> _page(GoRouterState state, Widget child) =>
    MaterialPage<void>(
      key: state.pageKey,
      name: state.name ?? state.path,
      restorationId: state.pageKey.value,
      child: child,
    );

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);
  // The router is rebuilt when the session changes. Only the first one reads
  // the link the app was started with, or an invitation would open twice.
  final launch = ref.read(_launchProvider);
  final restarted = launch.routed;
  launch.routed = true;

  GoRoute tab(
    String path,
    Widget screen, {
    List<RouteBase> routes = const [],
  }) => GoRoute(
    path: path,
    pageBuilder: (_, state) => _page(state, screen),
    routes: routes,
  );
  GoRoute overlay(String path, Widget screen) => GoRoute(
    path: path,
    parentNavigatorKey: _rootKey,
    pageBuilder: (_, state) => _page(state, screen),
  );

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.home,
    overridePlatformDefaultLocation: restarted,
    redirect: (_, state) {
      final at = state.matchedLocation;
      // An invitation link is not a screen of its own: the code is kept until
      // the person is signed in and the shell opens it over the home screen.
      final invited = inviteCodeFromLink(state.uri);
      if (invited != null) {
        Future.microtask(
          () => ref.read(pendingInviteCodeProvider.notifier).set(invited),
        );
        if (session == Session.ready) return Routes.home;
      }
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
        pageBuilder: (_, state) => _page(
          state,
          const Scaffold(body: Center(child: CircularProgressIndicator())),
        ),
      ),
      GoRoute(
        path: Routes.signIn,
        pageBuilder: (_, state) => _page(state, const SignInScreen()),
      ),
      GoRoute(
        path: Routes.signInCode,
        pageBuilder: (_, state) => _page(state, const CodeScreen()),
      ),
      GoRoute(
        path: Routes.welcome,
        pageBuilder: (_, state) => _page(state, const ProfileSetupScreen()),
      ),
      StatefulShellRoute(
        pageBuilder: (_, state, shell) =>
            _page(state, AppShell(navigationShell: shell)),
        navigatorContainerBuilder: (_, shell, children) =>
            PbBranchTransition(index: shell.currentIndex, children: children),
        branches: [
          for (final route in [
            tab(Routes.home, const HomeScreen()),
            tab(Routes.history, const HistoryScreen()),
            tab(
              Routes.progress,
              const ProgressScreen(),
              routes: [
                // Inside the tab, so that the bar stays and back returns to
                // the list of exercises.
                GoRoute(
                  path: ':exerciseId',
                  pageBuilder: (_, state) => _page(
                    state,
                    ProgressDetailScreen(
                      exerciseId: state.pathParameters['exerciseId']!,
                    ),
                  ),
                ),
              ],
            ),
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
        pageBuilder: (_, state) => _page(
          state,
          ProgramBuilderScreen(programId: state.pathParameters['id']),
        ),
      ),
      overlay(Routes.workout, const WorkoutScreen()),
      GoRoute(
        path: '${Routes.workoutEdit}/:id',
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, state) => _page(
          state,
          WorkoutEditScreen(workoutId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '${Routes.trainee}/:id',
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, state) =>
            _page(state, TraineeScreen(traineeId: state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '${Routes.assignedProgram}/:coachId/:id',
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, state) => _page(
          state,
          ProgramBuilderScreen(
            programId: state.pathParameters['id'],
            authorId: state.pathParameters['coachId'],
          ),
        ),
      ),
      overlay(Routes.invite, const InviteScreen()),
      GoRoute(
        path: Routes.inviteAccept,
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, state) => _page(
          state,
          InviteAcceptScreen(initialCode: state.uri.queryParameters['code']),
        ),
      ),
      GoRoute(path: '${Routes.join}/:code', redirect: (_, _) => Routes.home),
      overlay(Routes.exercisePicker, const ExercisePickerScreen()),
      overlay(Routes.exerciseCatalog, const ExercisePickerScreen(manage: true)),
    ],
  );
});
