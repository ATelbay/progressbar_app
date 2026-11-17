import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;

import 'design/tokens.g.dart';
import 'widgets/navigation_motion.dart';

export 'design/tokens.g.dart';

extension PbTheme on BuildContext {
  PbColors get pb => Theme.of(this).extension<PbColors>()!;
}

/// Dark is «Закат», light is «Рассвет». Values come from the design tokens.
ThemeData buildTheme(Brightness brightness, {bool reducedMotion = false}) {
  final c = brightness == Brightness.dark ? PbColors.dusk : PbColors.dawn;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    // SnackBars use an inverse surface; their action needs its text accent.
    inversePrimary: brightness == Brightness.light
        ? PbColors.dusk.accentText
        : PbColors.dawn.accentText,
    secondary: c.accentText,
    onSecondary: c.ground,
    error: c.danger,
    onError: c.ground,
    surface: c.surface,
    onSurface: c.ink,
    onSurfaceVariant: c.inkMuted,
    outline: c.lineStrong,
    outlineVariant: c.line,
  );
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(PbRadius.md),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.ground,
    fontFamily: 'Golos Text',
    extensions: [c],
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: PbPageTransitionsBuilder(
          const CupertinoPageTransitionsBuilder(),
          reducedMotion: reducedMotion,
        ),
        TargetPlatform.android: PbPageTransitionsBuilder(
          PredictiveBackPageTransitionsBuilder(fallbackColor: c.ground),
          reducedMotion: reducedMotion,
        ),
      },
    ),
    textTheme: TextTheme(
      headlineMedium: PbText.title.copyWith(color: c.ink),
      titleLarge: PbText.heading.copyWith(color: c.ink),
      bodyLarge: PbText.body.copyWith(color: c.ink),
      bodyMedium: PbText.body.copyWith(color: c.ink),
      labelLarge: PbText.bodyStrong,
      labelMedium: PbText.label.copyWith(color: c.inkMuted),
      bodySmall: PbText.caption.copyWith(color: c.inkMuted),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: PbText.title.copyWith(color: c.ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(PbSize.actionHeight),
        shape: shape,
        textStyle: PbText.bodyStrong,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(PbSize.actionHeight),
        shape: shape,
        foregroundColor: c.ink,
        backgroundColor: c.sunken,
        side: BorderSide.none,
        textStyle: PbText.body,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(PbSize.touchMin, PbSize.touchMin),
        foregroundColor: c.inkMuted,
        textStyle: PbText.body,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.glassStrong,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PbRadius.md),
        borderSide: BorderSide(color: c.lineStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PbRadius.md),
        borderSide: BorderSide(color: c.lineStrong),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      indicatorColor: c.selection,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? c.accentText
              : c.inkMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => PbText.navLabel.copyWith(
          color: states.contains(WidgetState.selected)
              ? c.accentText
              : c.inkMuted,
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, PbSize.touchMin)),
        textStyle: const WidgetStatePropertyAll(PbText.label),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.disabled) ? c.inkMuted : c.ink,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.selection : c.sunken,
        ),
        side: const WidgetStatePropertyAll(BorderSide.none),
      ),
    ),
    dividerTheme: DividerThemeData(color: c.line, thickness: 1),
  );
}
