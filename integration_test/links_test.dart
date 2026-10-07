// Two real emulator Auth users, native Firestore, and the actual screens.
// No production auth or data changes. Run with tool/links_walkthrough.py.
import 'dart:convert';
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
import 'package:progressbar_app/data/firestore_codec.dart';
import 'package:progressbar_app/domain/link_logic.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/features/auth/code_screen.dart';
import 'package:progressbar_app/features/auth/profile_setup_screen.dart';
import 'package:progressbar_app/features/auth/sign_in_screen.dart';
import 'package:progressbar_app/features/home/home_screen.dart';
import 'package:progressbar_app/features/people/trainee_screen.dart';
import 'package:progressbar_app/firebase_options.dart';
import 'package:progressbar_app/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'two users invite, assign, train offline, revoke access and reconnect',
    (tester) async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final db = FirebaseFirestore.instance
        ..useFirestoreEmulator('localhost', 8080);
      final auth = FirebaseAuth.instance;
      await auth.useAuthEmulator('localhost', 9099);
      await auth.signOut();

      Future<void> wait(Finder finder) async {
        for (var i = 0; i < 150 && finder.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(finder, findsWidgets);
      }

      Future<void> tap(Finder finder) async {
        await wait(finder);
        await tester.ensureVisible(finder.last);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(finder.last);
        await tester.pump(const Duration(milliseconds: 600));
      }

      Future<void> shot(String name) async {
        // ignore: avoid_print
        print('SHOT:$name');
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(tester.takeException(), isNull);
      }

      Future<dynamic> http(
        String url, {
        String? token,
        Map<String, Object?>? patch,
      }) async {
        final client = HttpClient();
        try {
          final request = await client.openUrl(
            patch == null ? 'GET' : 'PATCH',
            Uri.parse(url),
          );
          if (token != null) {
            request.headers.set('Authorization', 'Bearer $token');
          }
          if (patch != null) {
            request.headers.contentType = ContentType.json;
            request.write(jsonEncode(patch));
          }
          final response = await request.close();
          final body = await response.transform(utf8.decoder).join();
          expect(response.statusCode, 200);
          return jsonDecode(body);
        } finally {
          client.close();
        }
      }

      Future<void> remoteString(
        String path,
        String field,
        String value,
        String token,
      ) async {
        await http(
          'http://localhost:8080/v1/projects/progressbar-app/databases/(default)/documents/$path?updateMask.fieldPaths=$field',
          token: token,
          patch: {
            'fields': {
              field: {'stringValue': value},
            },
          },
        );
      }

      await tester.pumpWidget(const ProviderScope(child: ProgressBarApp()));
      await wait(find.byType(SignInScreen));
      var l = AppLocalizations.of(tester.element(find.byType(SignInScreen)))!;
      final suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(
        7,
      );
      final coachPhone = '+7701${suffix}1';
      final traineePhone = '+7701${suffix}2';
      Future<void> login(String phone, String name) async {
        await auth.signOut();
        await wait(find.byType(SignInScreen));
        l = AppLocalizations.of(tester.element(find.byType(SignInScreen)))!;
        await tester.enterText(find.byType(TextField), phone);
        await tap(find.widgetWithText(FilledButton, l.signInGetCode));
        await wait(find.byType(CodeScreen));
        final response = await http(
          'http://localhost:9099/emulator/v1/projects/progressbar-app/verificationCodes',
        );
        final codes = (response['verificationCodes'] as List).where(
          (c) => c['phoneNumber'] == phone,
        );
        await tester.enterText(
          find.byType(TextField),
          codes.last['code'] as String,
        );
        for (var i = 0; i < 150; i++) {
          await tester.pump(const Duration(milliseconds: 200));
          if (find.byType(ProfileSetupScreen).evaluate().isNotEmpty ||
              find.byType(HomeScreen).evaluate().isNotEmpty) {
            break;
          }
        }
        if (find.byType(ProfileSetupScreen).evaluate().isNotEmpty) {
          await tester.enterText(find.byType(TextField), name);
          await tap(find.widgetWithText(FilledButton, l.welcomeDone));
        }
        await wait(find.byType(HomeScreen));
        await db.waitForPendingWrites();
      }

      await login(coachPhone, 'Сергей');
      final coachId = auth.currentUser!.uid;
      final coachToken = (await auth.currentUser!.getIdToken())!;
      final program = Program(
        id: 'shared-plan',
        authorId: coachId,
        name: 'Сила тренера',
        days: [
          ProgramDay(
            id: 'back',
            name: 'Спина',
            exercises: [
              ProgramExercise(
                id: 'row',
                exerciseId: 'custom/coach-row',
                sets: [SetValues(reps: 8, weightKg: 40)],
                note: 'Пауза вверху',
              ),
            ],
          ),
        ],
      );
      await db
          .doc('users/$coachId/programs/shared-plan')
          .set(programToMap(program));
      await db
          .doc('users/$coachId/exercises/custom~coach-row')
          .set(
            exerciseToMap(
              const Exercise(
                id: 'custom/coach-row',
                names: {'en': 'Coach row', 'ru': 'Тяга тренера'},
                muscleGroup: 'lats',
              ),
            ),
          );
      await tap(find.text(l.tabPeople));
      await tap(find.text(l.peopleInvite));
      await tap(find.text(l.inviteCreate));
      await wait(find.text(l.inviteCopy));
      await shot('01-invitation');
      if (Platform.isAndroid) {
        // The real system share sheet; the runner closes it with «back».
        await tap(find.text(l.inviteShare));
        await shot('01b-share-sheet');
        // ignore: avoid_print
        print('BACK:');
        await tester.pump(const Duration(seconds: 2));
      }
      final invite =
          (await db
                  .collection('invitations')
                  .where('inviterId', isEqualTo: coachId)
                  .get())
              .docs
              .single
              .id;

      await login(traineePhone, 'Айгерим');
      final traineeId = auth.currentUser!.uid;
      final traineeToken = (await auth.currentUser!.getIdToken())!;
      await tap(find.text(l.tabPeople));
      await tap(find.text(l.peopleEnterCode));
      await tester.enterText(find.byType(TextField), invite);
      await tap(find.text(l.inviteFind));
      await wait(find.text(l.inviteAccept));
      await shot('02-accept');
      await tap(find.text(l.inviteAccept));
      await wait(find.text('Сергей'));
      await shot('03-trainee-people');

      await login(coachPhone, 'Сергей');
      await tap(find.text(l.tabPeople));
      await tap(find.text('Айгерим'));
      await wait(find.byType(TraineeScreen));
      await tap(find.text(l.assignProgram));
      await shot('04-assign');
      await tap(find.text('Сила тренера'));
      await wait(find.text(l.assignSuccess));
      await shot('05-coach-trainee');
      expect(
        (await db
                .collection('users/$traineeId/assignments')
                .where('coachId', isEqualTo: coachId)
                .get())
            .docs
            .length,
        1,
      );

      await login(traineePhone, 'Айгерим');
      await wait(find.text(l.assignedBy('Сергей')));
      await shot('06-assigned-home');
      await tap(find.text('Сила тренера'));
      await wait(
        find.text(l.localeName == 'ru' ? 'Тяга тренера' : 'Coach row'),
      );
      expect(find.byType(TextField), findsNothing);
      expect(find.text(l.builderDeleteProgram), findsNothing);
      await remoteString(
        'users/$coachId/programs/shared-plan',
        'name',
        'Обновлённая сила',
        coachToken,
      );
      await wait(find.text('Обновлённая сила'));
      await shot('07-assigned-builder');
      await db.disableNetwork();
      await tap(find.text(l.builderStart));
      await wait(find.text(l.entryRecord));
      await shot('08-assigned-offline-workout');
      await tap(find.widgetWithText(FilledButton, l.entryRecord));
      await tap(find.widgetWithText(FilledButton, l.workoutFinish));
      await wait(find.text(l.finishTitle));
      await tap(find.widgetWithText(FilledButton, l.workoutFinish));
      await wait(find.byType(HomeScreen));
      await db.enableNetwork();
      await db.waitForPendingWrites();
      final workouts = await db
          .collection('users/$traineeId/workouts')
          .get(const GetOptions(source: Source.server));
      final workout = workouts.docs.single.data();
      expect(workout['status'], 'completed');
      expect(workout['supervisorCoachId'], coachId);
      expect(workout['supervisorCoachName'], 'Сергей');
      expect(workout['exercises'][0]['sets'][0]['plan']['weightKg'], 40);
      expect(workout['programName'], 'Обновлённая сила');
      await tap(find.text(l.tabHistory));
      await wait(find.text(l.workoutCoach('Сергей')));
      await shot('09-history');

      await tap(find.text(l.tabPeople));
      await tap(find.text('Сергей'));
      await tap(find.text(l.coachDeactivate));
      await wait(find.text(l.chipReadOnly));
      await shot('10-deactivated');
      await tap(find.text(l.tabHome));
      await wait(find.text('Обновлённая сила'));
      await tap(find.text('Обновлённая сила'));
      await wait(find.text(l.builderStart));
      // Start again while deactivated: supervisor is absent, author is unchanged.
      await tap(find.text(l.builderStart));
      await wait(find.text(l.entryRecord));
      await tap(find.widgetWithText(FilledButton, l.entryRecord));
      await tap(find.widgetWithText(FilledButton, l.workoutFinish));
      await wait(find.text(l.finishTitle));
      await tap(find.widgetWithText(FilledButton, l.workoutFinish));
      await wait(find.byType(HomeScreen));
      await db.waitForPendingWrites();

      await login(coachPhone, 'Сергей');
      await tap(find.text(l.tabPeople));
      await tap(find.text('Айгерим'));
      await wait(find.text(l.traineeReadOnly));
      expect(find.text(l.assignProgram), findsNothing);
      await wait(find.text(l.workoutCoach('Сергей')));
      expect(find.text(l.workoutSolo), findsNothing);
      await shot('11-coach-readonly-mine');
      await tap(find.text(l.traineeAll));
      await wait(find.text(l.workoutSolo));
      await shot('12-coach-all');
      await remoteString(
        'links/${coachId}_$traineeId',
        'status',
        'removed',
        traineeToken,
      );
      await wait(find.text(l.traineeUnavailable));
      await shot('13-removed');
      await login(traineePhone, 'Айгерим');
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Обновлённая сила'), findsNothing);
      await tap(find.text(l.tabHistory));
      await wait(find.text(l.workoutCoach('Сергей')));
      await shot('14-retained-history');

      // The removed coach is added again: the same link is renewed, so the
      // earlier workouts and the assigned program come back by themselves.
      await login(coachPhone, 'Сергей');
      await tap(find.text(l.tabPeople));
      await tap(find.text(l.peopleInvite));
      await tap(find.text(l.inviteCreate));
      await wait(find.text(l.inviteCopy));
      final secondInvite =
          (await db
                  .collection('invitations')
                  .where('inviterId', isEqualTo: coachId)
                  .get())
              .docs
              .single
              .id;
      await login(traineePhone, 'Айгерим');
      // This time by link. On Android the runner opens it for real, the way
      // the camera does after reading the QR code. iOS first asks «Open in
      // Progress Bar?», and that system prompt cannot be pressed from here,
      // so there the link is handed over the way the system hands it over.
      if (Platform.isAndroid) {
        // ignore: avoid_print
        print('LINK:${inviteLink(secondInvite)}');
      } else {
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/navigation',
          const JSONMethodCodec().encodeMethodCall(
            MethodCall('pushRouteInformation', {
              'location': inviteLink(secondInvite),
            }),
          ),
          (_) {},
        );
      }
      await wait(find.text(l.inviteAccept));
      await shot('15-opened-by-link');
      await tap(find.text(l.inviteAccept));
      await wait(find.byType(HomeScreen));
      await wait(find.text(l.assignedBy('Сергей')));
      await shot('16-readded-trainee-home');
      await login(coachPhone, 'Сергей');
      await tap(find.text(l.tabPeople));
      await tap(find.text('Айгерим'));
      await wait(find.byType(TraineeScreen));
      await wait(find.text(l.assignProgram));
      await wait(find.text(l.workoutCoach('Сергей')));
      expect(find.text(l.workoutSolo), findsNothing);
      await shot('17-readded-coach-mine');
      await tap(find.text(l.traineeAll));
      await wait(find.text(l.workoutSolo));
      await auth.signOut();
    },
  );
}
