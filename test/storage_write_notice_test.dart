import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progressbar_app/domain/storage_status.dart';
import 'package:progressbar_app/features/auth/auth_controller.dart';
import 'package:progressbar_app/features/storage_status_providers.dart';
import 'package:progressbar_app/l10n/app_localizations.dart';
import 'package:progressbar_app/widgets/storage_write_notice.dart';

import 'support/fakes.dart';

void main() {
  late FakeAuthRepository auth;
  late ProviderContainer container;

  Future<void> open(WidgetTester tester) async {
    auth = FakeAuthRepository(signedInAs: 'user-1');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (_, child) => StorageWriteNotice(child: child!),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const Scaffold(body: Text('Another screen')),
                  ),
                ),
                child: const Text('Leave the editor'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(StorageWriteNotice)),
    );
  }

  Future<void> show(
    WidgetTester tester,
    StorageArea area, {
    String uid = 'user-1',
  }) async {
    container.read(storageWriteFailuresProvider.notifier).report(uid, area);
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('a refusal stays visible until acknowledged', (tester) async {
    await open(tester);
    await show(tester, StorageArea.workout);
    final message = find.textContaining(
      'The server refused the workout changes',
    );
    expect(message, findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(message, findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(message, findsNothing);
    expect(container.read(storageWriteFailuresProvider), isNull);
  });

  testWidgets('a late refusal is visible after leaving the editor', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Leave the editor'));
    await tester.pumpAndSettle();
    await show(tester, StorageArea.program);
    expect(find.text('Another screen'), findsOneWidget);
    expect(
      find.textContaining('The server refused the program changes'),
      findsOneWidget,
    );
  });

  testWidgets(
    'sign-out clears notices and late errors of the previous user are hidden',
    (tester) async {
      await open(tester);
      await show(tester, StorageArea.exercise);
      expect(
        find.textContaining('The server refused the exercise changes'),
        findsOneWidget,
      );
      await auth.signOut();
      await tester.pumpAndSettle();
      expect(find.textContaining('The server refused'), findsNothing);
      await show(tester, StorageArea.workout);
      expect(find.textContaining('The server refused'), findsNothing);
    },
  );
}
