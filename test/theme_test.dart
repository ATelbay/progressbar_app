import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:progressbar_app/theme.dart';

void main() {
  test('dark theme is Закат and light theme is Рассвет', () {
    final dark = buildTheme(Brightness.dark);
    final light = buildTheme(Brightness.light);

    expect(dark.extension<PbColors>(), PbColors.dusk);
    expect(light.extension<PbColors>(), PbColors.dawn);
    expect(dark.scaffoldBackgroundColor, const Color(0xFF22211F));
    expect(light.scaffoldBackgroundColor, const Color(0xFFF5F3EE));
    expect(dark.colorScheme.primary, const Color(0xFFE9B56C));
  });

  test('numerals use the condensed face with tabular figures', () {
    expect(PbText.numHero.fontFamily, 'Fira Sans Extra Condensed');
    expect(PbText.numHero.fontFeatures, isNotEmpty);
    expect(PbText.body.fontFamily, 'Golos Text');
  });
}
