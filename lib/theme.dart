import 'package:flutter/material.dart';

import 'design/tokens.g.dart';

export 'design/tokens.g.dart';

extension PbTheme on BuildContext {
  PbColors get pb => Theme.of(this).extension<PbColors>()!;
}

/// Dark is «Закат», light is «Рассвет». Values come from the design tokens.
ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? PbColors.dusk : PbColors.dawn;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
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
        textStyle: PbText.bodyStrong,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(PbSize.touchMin, PbSize.touchMin),
        foregroundColor: c.accentText,
        textStyle: PbText.bodyStrong,
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
      backgroundColor: c.surface,
      indicatorColor: c.sunken,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? c.accentText
              : c.inkMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => PbText.label.copyWith(
          fontSize: 12,
          color: states.contains(WidgetState.selected)
              ? c.accentText
              : c.inkMuted,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(color: c.line, thickness: 1),
  );
}
