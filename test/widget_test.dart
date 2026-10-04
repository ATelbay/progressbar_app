import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:progressbar_app/app.dart';

void main() {
  testWidgets('sign-in leads to the tabbed shell and back', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ProgressBarApp()));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Workout without a program'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('interface is translated into Russian and Kazakh', (
    tester,
  ) async {
    for (final (locale, title) in [
      (const Locale('ru'), 'Вход'),
      (const Locale('kk'), 'Кіру'),
    ]) {
      tester.platformDispatcher.localesTestValue = [locale];
      await tester.pumpWidget(
        ProviderScope(key: ValueKey(locale), child: const ProgressBarApp()),
      );
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
    }
    tester.platformDispatcher.clearLocalesTestValue();
  });
}
