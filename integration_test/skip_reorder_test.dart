// Skipping an exercise and moving cards with a real long press, against the
// local Firebase only.
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:progressbar_app/app.dart';
import 'package:progressbar_app/data/exercise_catalog_repository.dart';
import 'package:progressbar_app/data/profile_repository.dart';
import 'package:progressbar_app/data/program_repository.dart';
import 'package:progressbar_app/data/workout_repository.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/domain/workout_logic.dart';
import 'package:progressbar_app/features/home/home_screen.dart';
import 'package:progressbar_app/features/workout/entry_panel.dart';
import 'package:progressbar_app/features/workout/execution_entry_panel.dart';
import 'package:progressbar_app/features/workout/workout_screen.dart';
import 'package:progressbar_app/firebase_options.dart';
import 'package:progressbar_app/l10n/app_localizations.dart';
import 'package:progressbar_app/widgets/glass_panel.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('an exercise is skipped and cards are moved by a long press', (
    tester,
  ) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    final db = FirebaseFirestore.instance..useFirestoreEmulator(host, 8080);
    final auth = FirebaseAuth.instance;
    await auth.useAuthEmulator(host, 9099);
    await auth.signOut();
    final uid = (await auth.signInAnonymously()).user!.uid;
    final profiles = FirestoreProfileRepository(db);
    final profile = UserProfile(
      id: uid,
      name: 'Проверка пропуска',
      phone: '+77010000013',
      languageCode: 'ru',
      theme: ThemeChoice.dark,
    );
    await profiles.save(profile);
    final catalog = await AssetExerciseCatalogRepository(rootBundle).load();
    final exercises = catalog.values
        .where((e) => e.measure == Measure.reps && !e.usesBodyWeight)
        .take(5)
        .toList();
    final program = Program(
      id: 'skip-program',
      authorId: uid,
      name: 'Проверка пропуска',
      days: [
        ProgramDay(
          id: 'day',
          name: 'День 1',
          exercises: [
            for (final (i, exercise) in exercises.indexed)
              ProgramExercise(
                id: 'pe$i',
                executionMode: i == 2 || i == 3
                    ? ExecutionMode.superset
                    : ExecutionMode.ordinary,
                groupId: i == 2 || i == 3 ? 'pair' : null,
                exerciseId: exercise.id,
                sets: const [
                  SetValues(reps: 8, weightKg: 20),
                  SetValues(reps: 8, weightKg: 20),
                ],
              ),
          ],
        ),
      ],
    );
    await FirestoreProgramRepository(db).save(program);
    final workout = startWorkout(
      id: 'skip-workout',
      traineeId: uid,
      now: DateTime.now(),
      newId: () => db.collection('ids').doc().id,
      catalog: catalog,
      languageCode: 'ru',
      program: program,
      day: program.days.single,
    );
    await FirestoreWorkoutRepository(db).start(workout);
    await db.waitForPendingWrites();
    final doc = db.doc('users/$uid/workouts/${workout.id}');
    final ids = workout.exercises.map((e) => e.id).toList();
    Future<Map<String, dynamic>> server() async =>
        (await doc.get(const GetOptions(source: Source.server))).data()!;
    List<String> order(Map<String, dynamic> data) => [
      for (final e in data['exercises'] as List) e['id'] as String,
    ];

    Future<void> wait(Finder finder) async {
      for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(finder, findsWidgets);
    }

    Future<void> tap(Finder finder) async {
      await wait(finder);
      await tester.ensureVisible(finder.first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(finder.first);
      await tester.pump(const Duration(milliseconds: 600));
    }

    Future<void> mark(String line) async {
      // ignore: avoid_print
      print(line);
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(tester.takeException(), isNull);
    }

    AppLocalizations l() =>
        AppLocalizations.of(tester.element(find.byType(WorkoutScreen)))!;
    Finder slot(String id) => find.byKey(ValueKey('workout-exercise-$id'));
    String open() =>
        tester.widget<EntryPanel>(find.byType(EntryPanel)).exercise.id;
    Finder card(String id) =>
        find.descendant(of: slot(id), matching: find.byType(GlassCard));

    await tester.pumpWidget(const ProviderScope(child: ProgressBarApp()));
    await wait(find.byType(HomeScreen));
    final home = AppLocalizations.of(tester.element(find.byType(HomeScreen)))!;
    await tap(find.text(home.homeContinue));
    await wait(find.byType(EntryPanel));
    expect(open(), ids[0]);

    // Skipped without a connection, it waits on the phone and reaches the
    // server once the connection is back.
    await db.disableNetwork();
    await tap(find.text(l().workoutSkip));
    await wait(find.text(l().workoutSkippedChip));
    expect(open(), ids[1]);
    await mark('SHOT:01-skipped-offline');
    await db.enableNetwork();
    await db.waitForPendingWrites();
    var saved = await server();
    expect((saved['exercises'] as List).map((e) => e['skipped']), [
      true,
      false,
      false,
      false,
      false,
    ]);

    // The last card is held, carried to the top edge of the screen, kept
    // there while the screen scrolls, and dropped above the open panel.
    await tester.ensureVisible(card(ids[4]));
    await tester.pump(const Duration(milliseconds: 300));
    final from = tester.getCenter(card(ids[4]));
    final top = tester.getTopLeft(find.byType(WorkoutScreen)).dy;
    final gesture = await tester.startGesture(from);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 200));
    final edge = Offset(from.dx, top + 40);
    for (var i = 1; i <= 20; i++) {
      await gesture.moveTo(Offset.lerp(from, edge, i / 20)!);
      await tester.pump(const Duration(milliseconds: 32));
    }
    await mark('SHOT:02-dragging');
    // Held still: the screen scrolls to the top under the finger.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 800));
    await db.waitForPendingWrites();
    saved = await server();
    var moved = order(saved);
    // Above everything, where the finger stayed.
    expect(moved, [ids[4], ids[0], ids[1], ids[2], ids[3]]);
    expect(saved['originalOrder'], ids);
    // The panel stayed where the trainee was typing.
    expect(open(), ids[1]);
    await tester.ensureVisible(find.byType(EntryPanel));
    await mark('SHOT:03-moved');

    // A superset has one immediate handle and moves offline as a unit.
    Finder handle(String id) => find.byKey(ValueKey('workout-drag-handle-$id'));
    expect(handle(ids[2]), findsOneWidget);
    expect(handle(ids[3]), findsNothing);
    expect(handle(ids[1]), findsNothing);
    await tester.ensureVisible(handle(ids[2]));
    await tester.pump(const Duration(milliseconds: 300));
    final unchanged = order(await server());
    await tester.tap(handle(ids[2]));
    await tester.pump(const Duration(milliseconds: 600));
    expect(open(), ids[1]);
    expect(order(await server()), unchanged);
    await db.disableNetwork();
    final hfrom = tester.getCenter(handle(ids[2]));
    final hdrag = await tester.startGesture(hfrom);
    // No kLongPressTimeout: the gesture starts with movement.
    for (var i = 1; i <= 20; i++) {
      await hdrag.moveTo(
        Offset.lerp(hfrom, Offset(hfrom.dx, top + 40), i / 20)!,
      );
      await tester.pump(const Duration(milliseconds: 16));
      if (i == 8) await mark('SHOT:03b-handle-superset-lifted');
    }
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await hdrag.up();
    await tester.pump(const Duration(milliseconds: 600));
    expect(open(), ids[1]);
    await db.enableNetwork();
    await db.waitForPendingWrites();
    saved = await server();
    moved = order(saved);
    expect(moved, [ids[2], ids[3], ids[4], ids[0], ids[1]]);
    expect(saved['originalOrder'], ids);
    await mark('SHOT:03c-handle-superset-moved');
    // A cancel stops the shared auto scroller and does not persist a move.
    await tester.ensureVisible(handle(ids[4]));
    await tester.pump(const Duration(milliseconds: 300));
    final cancel = await tester.startGesture(tester.getCenter(handle(ids[4])));
    await cancel.moveBy(const Offset(0, 24));
    await tester.pump(const Duration(milliseconds: 32));
    await cancel.moveTo(
      Offset(hfrom.dx, tester.getBottomLeft(find.byType(WorkoutScreen)).dy - 8),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 32));
    }
    await cancel.cancel();
    await tester.pump(const Duration(milliseconds: 600));
    final scroller = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(WorkoutScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final stopped = scroller.position.pixels;
    await tester.pump(const Duration(seconds: 1));
    expect(scroller.position.pixels, stopped);
    await db.waitForPendingWrites();
    expect(order(await server()), moved);

    // A skip is taken back from the card, without recording anything.
    await tap(card(ids[0]));
    expect(open(), ids[0]);
    await tap(find.text(l().workoutUnskip));
    await db.waitForPendingWrites();
    saved = await server();
    expect(
      (saved['exercises'] as List).every((e) => e['skipped'] == false),
      isTrue,
    );
    expect(order(saved), moved);

    unawaited(profiles.save(profile.copyWith(theme: ThemeChoice.light)));
    for (
      var i = 0;
      i < 100 &&
          Theme.of(tester.element(find.byType(WorkoutScreen))).brightness !=
              Brightness.light;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tap(find.text(l().workoutSkip));
    await wait(find.text(l().workoutSkippedChip));
    await mark('SHOT:04-skipped-light');
    await tester.ensureVisible(handle(ids[4]));
    await tester.pump(const Duration(milliseconds: 300));
    final lightDrag = await tester.startGesture(
      tester.getCenter(handle(ids[4])),
    );
    await lightDrag.moveBy(const Offset(0, -24));
    await tester.pump(const Duration(milliseconds: 32));
    await lightDrag.moveBy(const Offset(0, -20));
    await mark('SHOT:04b-lifted-light');
    await lightDrag.cancel();
    await tester.pump(const Duration(milliseconds: 600));
    // Skipping now selects the first unrecorded group in the new order.
    await wait(find.byType(ExecutionEntryPanel));
    expect(handle(ids[2]), findsNothing);
    expect(handle(ids[3]), findsNothing);
    // Move another card while the superset's local entry copy is open.
    await tester.ensureVisible(handle(ids[4]));
    await tester.pump(const Duration(milliseconds: 300));
    final source = tester.getCenter(handle(ids[4]));
    final around = await tester.startGesture(source);
    final bottom = tester.getBottomLeft(find.byType(WorkoutScreen)).dy - 8;
    for (var i = 1; i <= 20; i++) {
      await around.moveTo(
        Offset.lerp(source, Offset(source.dx, bottom), i / 20)!,
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    for (var i = 0; i < 35; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await around.up();
    await tester.pump(const Duration(milliseconds: 600));
    await db.waitForPendingWrites();
    saved = await server();
    moved = order(saved);
    expect(moved, [ids[2], ids[3], ids[0], ids[1], ids[4]]);
    expect(find.byType(ExecutionEntryPanel), findsOneWidget);
    for (var member = 0; member < 2; member++) {
      if (member == 0) {
        await tap(find.widgetWithText(FilledButton, l().entryContinue));
      }
      await tap(find.widgetWithText(FilledButton, l().entryContinue));
      await tap(
        find.widgetWithText(
          FilledButton,
          member == 0 ? l().entryContinue : l().executionRecordSuperset,
        ),
      );
    }
    await db.waitForPendingWrites();
    saved = await server();
    expect(order(saved), moved);
    expect(saved['originalOrder'], ids);
    expect(
      (saved['exercises'] as List)
          .take(2)
          .expand((e) => e['sets'] as List)
          .every((s) => s['fact'] != null),
      isTrue,
    );
    await mark('SHOT:04c-superset-recorded-after-move');
    await mark('FONT:accessibility-large');
    await tester.ensureVisible(find.text(l().workoutSkippedChip));
    await mark('SHOT:05-skipped-large');
    await mark('FONT:large');
  });
}
