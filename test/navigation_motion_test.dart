import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progressbar_app/theme.dart';
import 'package:progressbar_app/widgets/navigation_motion.dart';

class _CounterScene extends StatefulWidget {
  const _CounterScene(this.name, {required this.created});
  final String name;
  final VoidCallback created;
  @override
  State<_CounterScene> createState() => _CounterSceneState();
}

class _CounterSceneState extends State<_CounterScene> {
  int count = 0;
  @override
  void initState() {
    super.initState();
    widget.created();
  }

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    key: ValueKey('scene-${widget.name}'),
    child: Center(
      child: TextButton(
        onPressed: () => setState(() => count++),
        child: Text('${widget.name}: $count'),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'tab motion is continuous on interruption and keeps branch state',
    (t) async {
      final index = ValueNotifier(0);
      addTearDown(index.dispose);
      final created = [0, 0, 0];
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<int>(
              valueListenable: index,
              builder: (_, value, _) => PbBranchTransition(
                index: value,
                children: [
                  for (var i = 0; i < 3; i++)
                    _CounterScene('$i', created: () => created[i]++),
                ],
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('0: 0'));
      await t.pump();
      index.value = 1;
      await t.pump();
      await t.pump(const Duration(milliseconds: 60));
      final moving = find.byKey(const ValueKey('scene-1'));
      final before = t.getTopLeft(moving);
      expect(before.dx, greaterThan(0));
      expect(find.text('0: 1').hitTestable(), findsNothing);
      index.value = 2;
      await t.pump();
      expect(t.getTopLeft(moving), before);
      await t.pump(const Duration(milliseconds: 30));
      index.value = 0;
      await t.pumpAndSettle();
      expect(find.text('0: 1'), findsOneWidget);
      expect(created, [1, 1, 1]);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('reduced tab motion crossfades without translation', (t) async {
    final index = ValueNotifier(0);
    addTearDown(index.dispose);
    await t.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: ValueListenableBuilder<int>(
              valueListenable: index,
              builder: (_, value, _) => PbBranchTransition(
                index: value,
                children: const [
                  SizedBox.expand(key: ValueKey('first')),
                  SizedBox.expand(key: ValueKey('second')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final origin = t.getTopLeft(find.byKey(const ValueKey('first')));
    index.value = 1;
    await t.pump();
    await t.pump(const Duration(milliseconds: 40));
    final second = find.byKey(const ValueKey('second'));
    expect(t.getTopLeft(second), origin);
    final opacity = t
        .widget<Opacity>(
          find.ancestor(of: second, matching: find.byType(Opacity)),
        )
        .opacity;
    expect(opacity, allOf(greaterThan(0), lessThan(1)));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('first')), findsNothing);
  });

  for (final reduced in [false, true]) {
    testWidgets(
      'iOS edge swipe remains available with reduced motion $reduced',
      (t) async {
        final navigator = GlobalKey<NavigatorState>();
        await t.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            theme: buildTheme(
              Brightness.dark,
              reducedMotion: reduced,
            ).copyWith(platform: TargetPlatform.iOS),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
              child: child!,
            ),
            home: const Scaffold(body: Text('Home')),
          ),
        );
        unawaited(
          navigator.currentState!.push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  const Scaffold(key: ValueKey('detail'), body: Text('Detail')),
            ),
          ),
        );
        await t.pump();
        await t.pump(const Duration(milliseconds: 60));
        final offset = t.getTopLeft(find.byKey(const ValueKey('detail')));
        expect(offset.dx, reduced ? 0 : greaterThan(0));
        await t.pumpAndSettle();
        final width = t.view.physicalSize.width / t.view.devicePixelRatio;
        await t.timedDragFrom(
          const Offset(1, 200),
          Offset(width * .8, 0),
          const Duration(milliseconds: 250),
        );
        await t.pumpAndSettle();
        expect(find.text('Detail'), findsNothing);
        expect(find.text('Home'), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets('Android system back returns through the platform transition', (
    t,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await t.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: buildTheme(Brightness.light)
            .copyWith(platform: TargetPlatform.android),
        home: const Scaffold(body: Text('Home')),
      ),
    );
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Detail')),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.text('Detail'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
