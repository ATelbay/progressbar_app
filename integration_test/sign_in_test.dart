// Signs in against the real Firebase project with the test phone number
// configured in the console (no SMS is sent). Run on a simulator or emulator:
//   flutter test integration_test/sign_in_test.dart -d <device>
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:progressbar_app/app.dart';
import 'package:progressbar_app/firebase_options.dart';

const testPhone = String.fromEnvironment(
  'TEST_PHONE',
  defaultValue: '+77084880667',
);
const testCode = String.fromEnvironment('TEST_CODE', defaultValue: '123456');

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
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await tester.pumpWidget(const ProviderScope(child: ProgressBarApp()));

    final getCode = find.byType(FilledButton);
    final tabs = find.byType(NavigationBar);
    await pumpUntil(
      tester,
      find.byWidgetPredicate((w) => w is FilledButton || w is NavigationBar),
    );

    if (tabs.evaluate().isEmpty) {
      await tester.enterText(find.byType(TextField), testPhone);
      await tester.tap(getCode);
      await pumpUntil(tester, find.byType(BackButton));

      await tester.enterText(find.byType(TextField), testCode);
      // First sign-in asks for a name; later runs go straight to the tabs.
      await pumpUntil(
        tester,
        find.byWidgetPredicate(
          (w) => w is NavigationBar || w is IconButton && w.tooltip != null,
        ),
      );
      if (tabs.evaluate().isEmpty) {
        await tester.enterText(find.byType(TextField), 'Тест');
        await tester.tap(find.byType(FilledButton));
      }
    }
    await pumpUntil(tester, tabs);

    await tester.tap(find.byIcon(Icons.person_outline));
    await pumpUntil(tester, find.byIcon(Icons.logout));
    await tester.tap(find.byIcon(Icons.logout));
    await pumpUntil(tester, find.byType(TextField));
    expect(tabs, findsNothing);
  });
}
