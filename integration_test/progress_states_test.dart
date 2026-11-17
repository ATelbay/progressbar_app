// Progress geometry with real fonts and local Firebase data only.
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:progressbar_app/app.dart';
import 'package:progressbar_app/data/exercise_catalog_repository.dart';
import 'package:progressbar_app/data/profile_repository.dart';
import 'package:progressbar_app/data/workout_repository.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/domain/workout_logic.dart';
import 'package:progressbar_app/features/home/home_screen.dart';
import 'package:progressbar_app/features/progress/progress_detail_screen.dart';
import 'package:progressbar_app/features/progress/progress_screen.dart';
import 'package:progressbar_app/firebase_options.dart';
import 'package:progressbar_app/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'progress search, all metrics, one point, time, body weight and large text',
    (tester) async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
      final db = FirebaseFirestore.instance..useFirestoreEmulator(host, 8080);
      final auth = FirebaseAuth.instance;
      await auth.useAuthEmulator(host, 9099);
      await auth.signOut();
      final uid = (await auth.signInAnonymously()).user!.uid;
      final profiles = FirestoreProfileRepository(db),
          store = FirestoreWorkoutRepository(db);
      var profile = UserProfile(
        id: uid,
        name: 'Прогресс',
        phone: '+77010000120',
        languageCode: 'ru',
        theme: ThemeChoice.light,
      );
      await profiles.save(profile);
      final catalog = await AssetExerciseCatalogRepository(rootBundle).load();
      final weighted = catalog.values
          .where((e) => e.measure == Measure.reps && !e.usesBodyWeight)
          .take(3)
          .toList();
      final body = catalog.values.firstWhere(
        (e) => e.measure == Measure.reps && e.usesBodyWeight,
      );
      final time = catalog.values.firstWhere((e) => e.measure == Measure.time);
      Future<void> wait(Finder f) async {
        for (var i = 0; i < 100 && f.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(f, findsWidgets);
      }

      Future<void> tap(Finder f) async {
        await wait(f);
        await tester.ensureVisible(f.first);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(f.first);
        await tester.pump(const Duration(milliseconds: 600));
      }

      Future<void> mark(String name) async {
        // ignore: avoid_print
        print(name.startsWith('FONT:') ? name : 'SHOT:$name');
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(tester.takeException(), isNull);
      }

      await tester.pumpWidget(const ProviderScope(child: ProgressBarApp()));
      await wait(find.byType(HomeScreen));
      AppLocalizations l() =>
          AppLocalizations.of(tester.element(find.byType(Scaffold).last))!;
      await tap(find.text(l().tabProgress));
      await wait(find.text(l().progressEmptyTitle));
      await mark('01-progress-empty');
      await tap(find.text(l().historyToPrograms));
      await wait(find.byType(HomeScreen));
      profile = profile.copyWith(theme: ThemeChoice.dark);
      await profiles.save(profile);
      const weights = [77.5, 78.0, 80.0, 78.5, 81.0, 80.0, 82.5];
      for (var i = 0; i < 7; i++) {
        WorkoutExercise recorded(Exercise e, SetValues fact) => WorkoutExercise(
          id: 'we-${e.id}',
          exerciseId: e.id,
          name: e.nameFor('ru'),
          measure: e.measure,
          usesBodyWeight: e.usesBodyWeight,
          sets: [WorkoutSet(id: 'set-${e.id}', fact: fact)],
        );
        final w = Workout(
          id: 'point-$i',
          traineeId: uid,
          status: WorkoutStatus.inProgress,
          startedAt: DateTime.now(),
          bodyWeightKg: 80,
          exercises: [
            recorded(weighted[0], SetValues(reps: 10, weightKg: weights[i])),
            recorded(weighted[1], const SetValues(reps: 10, weightKg: 24)),
            if (i == 6)
              recorded(weighted[2], const SetValues(reps: 5, weightKg: 100)),
            recorded(body, SetValues(reps: 9 + i, weightKg: i > 3 ? 10 : 0)),
            recorded(time, SetValues(seconds: i == 6 ? 75 : 80)),
          ],
        );
        await store.start(w);
        await store.save(
          completeWorkout(
            w,
            now: DateTime.now(),
            day: DateTime.now().subtract(Duration(days: (6 - i) * 7)),
          ),
        );
      }
      await db.waitForPendingWrites();
      await tap(find.text(l().tabProgress));
      await wait(find.byType(ProgressScreen));
      await wait(find.text(weighted[0].nameFor('ru')));
      await mark('02-progress-list-dusk');
      await tester.enterText(find.byType(TextField), 'нет такого упражнения');
      await tester.pump(const Duration(milliseconds: 500));
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 300));
      await wait(find.text(l().progressNothingFound));
      await mark('03-progress-nothing-found');
      await tap(find.byIcon(Icons.close));
      await tap(find.text(weighted[0].nameFor('ru')));
      await wait(find.byType(ProgressDetailScreen));
      await mark('04-progress-detail-max');
      await tap(find.text(l().progressMetricWeight));
      await mark('05-progress-detail-weight');
      await tap(find.text(l().progressMetricReps));
      await mark('06-progress-detail-reps');
      await tap(find.text(l().progressMetricMax));
      await mark('FONT:accessibility-large');
      await mark('07-progress-detail-large-ru');
      profile = profile.copyWith(languageCode: () => 'kk');
      await profiles.save(profile);
      await mark('08-progress-detail-large-kk');
      await mark('FONT:large');
      profile = profile.copyWith(
        languageCode: () => 'en',
        theme: ThemeChoice.light,
      );
      await profiles.save(profile);
      await mark('09-progress-detail-dawn-en');
      await tap(
        find.byTooltip(
          MaterialLocalizations.of(
            tester.element(find.byType(ProgressDetailScreen)),
          ).backButtonTooltip,
        ),
      );
      await wait(find.byType(ProgressScreen));
      await mark('10-progress-list-dawn');
      await tap(find.text(time.nameFor('ru')));
      await wait(find.byType(ProgressDetailScreen));
      await mark('11-progress-time');
      await tap(
        find.byTooltip(
          MaterialLocalizations.of(
            tester.element(find.byType(ProgressDetailScreen)),
          ).backButtonTooltip,
        ),
      );
      await tap(find.text(body.nameFor('ru')));
      await wait(find.byType(ProgressDetailScreen));
      await mark('12-progress-body-extra');
      await tap(
        find.byTooltip(
          MaterialLocalizations.of(
            tester.element(find.byType(ProgressDetailScreen)),
          ).backButtonTooltip,
        ),
      );
      await tap(find.text(weighted[2].nameFor('ru')));
      await wait(find.byType(ProgressDetailScreen));
      await mark('13-progress-single-point');
      final recorded = await store.watchCompleted(uid).first;
      for (final w in recorded) {
        await store.deleteCompleted(w);
      }
      await db.waitForPendingWrites();
      await wait(find.text(l().progressGone));
      await mark('14-progress-gone');
      await auth.signOut();
    },
  );
}
