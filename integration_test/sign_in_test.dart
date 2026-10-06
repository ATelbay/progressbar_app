// Signs in against the real Firebase project with the test phone number
// configured in the console (no SMS is sent). Run on a simulator or emulator:
//   flutter test integration_test/sign_in_test.dart -d <device> \
//     --dart-define-from-file=<private test credentials.json>
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:progressbar_app/app.dart';
import 'package:progressbar_app/features/auth/code_screen.dart';
import 'package:progressbar_app/features/auth/profile_setup_screen.dart';
import 'package:progressbar_app/features/auth/sign_in_screen.dart';
import 'package:progressbar_app/firebase_options.dart';

const testPhone = String.fromEnvironment('TEST_PHONE');
const testCode = String.fromEnvironment('TEST_CODE');

Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 150 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  if (finder.evaluate().isEmpty) {
    final seen = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? t.textSpan?.toPlainText())
        .join(' | ');
    fail('Timed out waiting for $finder. On screen: $seen');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('test number signs in, fills the profile and signs out', (
    tester,
  ) async {
    expect(
      RegExp(r'^\+\d{10,15}$').hasMatch(testPhone),
      isTrue,
      reason: 'Pass TEST_PHONE for a fictional number configured in Firebase.',
    );
    expect(
      RegExp(r'^\d{6}$').hasMatch(testCode),
      isTrue,
      reason: 'Pass the matching six-digit TEST_CODE.',
    );
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // A cached session must not let this test skip phone verification.
    await FirebaseAuth.instance.signOut();
    await tester.pumpWidget(const ProviderScope(child: ProgressBarApp()));

    final tabs = find.byType(NavigationBar);
    await pumpUntil(tester, find.byType(SignInScreen));
    await tester.enterText(find.byType(TextField), testPhone);
    await tester.tap(find.byType(FilledButton));
    await pumpUntil(tester, find.byType(CodeScreen));

    await tester.enterText(find.byType(TextField), testCode);
    // First sign-in asks for a name; later runs go straight to the tabs.
    await pumpUntil(
      tester,
      find.byWidgetPredicate(
        (w) => w is NavigationBar || w is ProfileSetupScreen,
      ),
    );
    if (tabs.evaluate().isEmpty) {
      await tester.enterText(find.byType(TextField), 'Тест');
      await tester.tap(find.byType(FilledButton));
    }
    await pumpUntil(tester, tabs);
    expect(FirebaseAuth.instance.currentUser?.phoneNumber, testPhone);
    // Confirm that the profile reached Firestore, not just the local cache.
    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get(const GetOptions(source: Source.server));
    expect(profile.exists, isTrue);
    expect(profile.data()?['phone'], testPhone);
    expect(profile.data()?['name'], isNotEmpty);

    await tester.tap(find.byIcon(Icons.person_outline));
    await pumpUntil(tester, find.byIcon(Icons.logout));
    await tester.tap(find.byIcon(Icons.logout));
    await pumpUntil(tester, find.byType(SignInScreen));
    expect(tabs, findsNothing);
    expect(FirebaseAuth.instance.currentUser, isNull);
  });
}
