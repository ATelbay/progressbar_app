import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:progressbar_app/app.dart';
import 'package:progressbar_app/domain/models.dart';
import 'package:progressbar_app/features/auth/auth_controller.dart';

import 'support/fakes.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;

  Widget app({Key? key}) => ProviderScope(
    key: key,
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      profileRepositoryProvider.overrideWithValue(profiles),
    ],
    child: const ProgressBarApp(),
  );

  setUp(() {
    auth = FakeAuthRepository();
    profiles = FakeProfileRepository();
  });

  testWidgets('phone, code and first-time profile lead to the tabs', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Get code'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.enterText(find.byType(TextField), '+7 708 488 06 67');
    await tester.tap(find.text('Get code'));
    await tester.pumpAndSettle();
    expect(auth.sentTo, '+77084880667');
    expect(find.text('Sent to +77084880667'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    expect(find.text('Two quick questions'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Арман');
    await tester.tap(find.byTooltip('Increase body weight'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    final saved = profiles.profileOf('user-1')!;
    expect(saved.name, 'Арман');
    expect(saved.phone, '+77084880667');
    expect(saved.bodyWeightKg, 75.5);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Get code'), findsOneWidget);
  });

  testWidgets('a wrong code is explained and can be retried', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '+77084880667');
    await tester.tap(find.text('Get code'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '000000');
    await tester.pumpAndSettle();
    expect(find.textContaining('Wrong code'), findsOneWidget);
    expect(find.text('Two quick questions'), findsNothing);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    expect(find.text('Two quick questions'), findsOneWidget);
  });

  testWidgets('a number without a country code is rejected before sending', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '8 708 488');
    await tester.tap(find.text('Get code'));
    await tester.pumpAndSettle();

    expect(auth.sendCount, 0);
    expect(
      find.textContaining("doesn't look like a phone number"),
      findsOneWidget,
    );
  });

  testWidgets('a returning user with a profile goes straight to the tabs', (
    tester,
  ) async {
    auth = FakeAuthRepository(signedInAs: 'user-1');
    await profiles.save(
      const UserProfile(id: 'user-1', name: 'Арман', phone: '+77084880667'),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('a signed-in user without a profile is asked to fill it in', (
    tester,
  ) async {
    auth = FakeAuthRepository(signedInAs: 'user-1');
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Two quick questions'), findsOneWidget);
  });

  testWidgets('interface is translated into Russian and Kazakh', (
    tester,
  ) async {
    for (final (locale, button) in [
      (const Locale('ru'), 'Получить код'),
      (const Locale('kk'), 'Код алу'),
    ]) {
      tester.platformDispatcher.localesTestValue = [locale];
      await tester.pumpWidget(app(key: ValueKey(locale)));
      await tester.pumpAndSettle();
      expect(find.text(button), findsOneWidget);
    }
    tester.platformDispatcher.clearLocalesTestValue();
  });
}
